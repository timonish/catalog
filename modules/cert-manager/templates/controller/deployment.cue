package controller

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/cert-manager/templates/config"
)

#Deployment: appsv1.#Deployment & {
	#config: config.#Config
	_config: #config

	// The name of the immutable ConfigMap holding the controller
	// configuration file.
	#cmName: string

	_controller: _config.controller
	_selectorLabels: #SelectorLabels & {#config: _config}

	// The affinity rules generated from the affinity values;
	// the anti-affinity presets match the component pods.
	_affinity: timoniv1.#Affinity & {
		#Values:      _controller.affinity
		#MatchLabels: _selectorLabels
	}
	_metricsPort: (#MetricsPort & {#config: _config}).port
	_healthzPort: (#HealthzPort & {#config: _config}).port

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: #ObjectMeta & {#config: _config}
	if _controller.deploymentAnnotations != _|_ {
		metadata: annotations: _controller.deploymentAnnotations
	}

	spec: appsv1.#DeploymentSpec & {
		replicas: _controller.replicas
		if _controller.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _controller.revisionHistoryLimit
		}
		if _controller.strategy != _|_ {
			strategy: _controller.strategy
		}
		selector: matchLabels: _selectorLabels
		template: {
			metadata: {
				labels: _selectorLabels
				if _controller.podLabels != _|_ {
					labels: _controller.podLabels
				}
				if _controller.podAnnotations != _|_ {
					annotations: _controller.podAnnotations
				}

				// Scrape annotations for annotation-based Prometheus
				// setups without the Prometheus Operator.
				if _config.prometheus.enabled && !_config.serviceMonitor.enabled && !_config.podMonitor.enabled {
					annotations: {
						"prometheus.io/path":   "/metrics"
						"prometheus.io/scrape": "true"
						"prometheus.io/port":   "\(_metricsPort)"
					}
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _controller.serviceAccount.name
				automountServiceAccountToken: _controller.automountServiceAccountToken
				if !_controller.serviceAccount.create {
					if _config.imagePullSecrets != _|_ {
						imagePullSecrets: _config.imagePullSecrets
					}
				}
				enableServiceLinks: _controller.enableServiceLinks
				securityContext:    _controller.podSecurityContext
				if _controller.priorityClassName != _|_ {
					priorityClassName: _controller.priorityClassName
				}
				if _controller.runtimeClassName != _|_ {
					runtimeClassName: _controller.runtimeClassName
				}
				if _controller.hostUsers != _|_ {
					hostUsers: _controller.hostUsers
				}
				if _controller.hostAliases != _|_ {
					hostAliases: _controller.hostAliases
				}
				if _controller.dnsPolicy != _|_ {
					dnsPolicy: _controller.dnsPolicy
				}
				if _controller.dnsConfig != _|_ {
					dnsConfig: _controller.dnsConfig
				}
				containers: [
					{
						name:            "cert-manager-controller"
						image:           _controller.image.reference
						imagePullPolicy: _controller.image.pullPolicy
						securityContext: _controller.securityContext
						args: [
							"--config=/var/cert-manager/config/config.yaml",
							for a in _controller.extraArgs {a},
						]
						ports: [
							if _metricsPort > 0 {
								{
									name:          "http-metrics"
									protocol:      "TCP"
									containerPort: _metricsPort
								}
							},
							{
								name:          "http-healthz"
								protocol:      "TCP"
								containerPort: _healthzPort
							},
						]
						livenessProbe: _controller.livenessProbe
						env: [
							{
								name: "POD_NAMESPACE"
								valueFrom: fieldRef: fieldPath: "metadata.namespace"
							},
							if _controller.env != _|_ for e in _controller.env {e},
						]
						volumeMounts: [
							{
								name:      "config"
								mountPath: "/var/cert-manager/config"
							},
							if _controller.extraVolumeMounts != _|_ for m in _controller.extraVolumeMounts {m},
						]
						if _controller.resources != _|_ {
							resources: _controller.resources
						}
					},
					if _controller.extraContainers != _|_ for c in _controller.extraContainers {c},
				]
				volumes: [
					{
						name: "config"
						configMap: name: #cmName
					},
					if _controller.extraVolumes != _|_ for v in _controller.extraVolumes {v},
				]
				nodeSelector: _controller.nodeSelector
				if _affinity.#Enabled {
					affinity: _affinity
				}
				if _controller.tolerations != _|_ {
					tolerations: _controller.tolerations
				}
				if _controller.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _controller.topologySpreadConstraints
				}
			}
		}
	}
}
