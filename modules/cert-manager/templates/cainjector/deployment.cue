package cainjector

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/cert-manager/templates/config"
)

#Deployment: appsv1.#Deployment & {
	#config: config.#Config
	_config: #config

	// The name of the immutable ConfigMap holding the cainjector
	// configuration file.
	#cmName: string

	_cainjector: _config.cainjector
	_selectorLabels: #SelectorLabels & {#config: _config}

	// The affinity rules generated from the affinity values;
	// the anti-affinity presets match the component pods.
	_affinity: timoniv1.#Affinity & {
		#Values:      _cainjector.affinity
		#MatchLabels: _selectorLabels
	}
	_metricsPort: (#MetricsPort & {#config: _config}).port

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: #ObjectMeta & {#config: _config}
	if _cainjector.deploymentAnnotations != _|_ {
		metadata: annotations: _cainjector.deploymentAnnotations
	}

	spec: appsv1.#DeploymentSpec & {
		replicas: _cainjector.replicas
		if _cainjector.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _cainjector.revisionHistoryLimit
		}
		if _cainjector.strategy != _|_ {
			strategy: _cainjector.strategy
		}
		selector: matchLabels: _selectorLabels
		template: {
			metadata: {
				labels: _selectorLabels
				if _cainjector.podLabels != _|_ {
					labels: _cainjector.podLabels
				}
				if _cainjector.podAnnotations != _|_ {
					annotations: _cainjector.podAnnotations
				}
				if _config.prometheus.enabled && !_config.serviceMonitor.enabled && !_config.podMonitor.enabled {
					annotations: {
						"prometheus.io/path":   "/metrics"
						"prometheus.io/scrape": "true"
						"prometheus.io/port":   "\(_metricsPort)"
					}
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _cainjector.serviceAccount.name
				automountServiceAccountToken: _cainjector.automountServiceAccountToken
				if !_cainjector.serviceAccount.create {
					if _config.imagePullSecrets != _|_ {
						imagePullSecrets: _config.imagePullSecrets
					}
				}
				enableServiceLinks: _cainjector.enableServiceLinks
				securityContext:    _cainjector.podSecurityContext
				if _cainjector.priorityClassName != _|_ {
					priorityClassName: _cainjector.priorityClassName
				}
				if _cainjector.runtimeClassName != _|_ {
					runtimeClassName: _cainjector.runtimeClassName
				}
				if _cainjector.hostUsers != _|_ {
					hostUsers: _cainjector.hostUsers
				}
				if _cainjector.hostAliases != _|_ {
					hostAliases: _cainjector.hostAliases
				}
				if _cainjector.dnsPolicy != _|_ {
					dnsPolicy: _cainjector.dnsPolicy
				}
				if _cainjector.dnsConfig != _|_ {
					dnsConfig: _cainjector.dnsConfig
				}
				containers: [
					{
						name:            "cert-manager-cainjector"
						image:           _cainjector.image.reference
						imagePullPolicy: _cainjector.image.pullPolicy
						securityContext: _cainjector.securityContext
						args: [
							"--config=/var/cert-manager/config/config.yaml",
							for a in _cainjector.extraArgs {a},
						]
						ports: [
							if _metricsPort > 0 {
								{
									name:          "http-metrics"
									protocol:      "TCP"
									containerPort: _metricsPort
								}
							},
						]
						env: [
							{
								name: "POD_NAMESPACE"
								valueFrom: fieldRef: fieldPath: "metadata.namespace"
							},
							if _cainjector.env != _|_ for e in _cainjector.env {e},
						]
						volumeMounts: [
							{
								name:      "config"
								mountPath: "/var/cert-manager/config"
							},
							if _cainjector.extraVolumeMounts != _|_ for m in _cainjector.extraVolumeMounts {m},
						]
						if _cainjector.resources != _|_ {
							resources: _cainjector.resources
						}
					},
					if _cainjector.extraContainers != _|_ for c in _cainjector.extraContainers {c},
				]
				volumes: [
					{
						name: "config"
						configMap: name: #cmName
					},
					if _cainjector.extraVolumes != _|_ for v in _cainjector.extraVolumes {v},
				]
				nodeSelector: _cainjector.nodeSelector
				if _affinity.#Enabled {
					affinity: _affinity
				}
				if _cainjector.tolerations != _|_ {
					tolerations: _cainjector.tolerations
				}
				if _cainjector.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _cainjector.topologySpreadConstraints
				}
			}
		}
	}
}
