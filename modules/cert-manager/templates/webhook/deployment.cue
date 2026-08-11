package webhook

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/cert-manager/templates/config"
)

#Deployment: appsv1.#Deployment & {
	#config: config.#Config
	_config: #config

	// The name of the immutable ConfigMap holding the webhook
	// configuration file.
	#cmName: string

	_webhook: _config.webhook
	_selectorLabels: #SelectorLabels & {#config: _config}
	_metricsPort: (#MetricsPort & {#config: _config}).port

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: #ObjectMeta & {#config: _config}
	if _webhook.deploymentAnnotations != _|_ {
		metadata: annotations: _webhook.deploymentAnnotations
	}

	spec: appsv1.#DeploymentSpec & {
		replicas: _webhook.replicas
		if _webhook.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _webhook.revisionHistoryLimit
		}
		if _webhook.strategy != _|_ {
			strategy: _webhook.strategy
		}
		selector: matchLabels: _selectorLabels
		template: {
			metadata: {
				labels: _selectorLabels
				if _webhook.podLabels != _|_ {
					labels: _webhook.podLabels
				}
				if _webhook.podAnnotations != _|_ {
					annotations: _webhook.podAnnotations
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
				serviceAccountName:           _webhook.serviceAccount.name
				automountServiceAccountToken: _webhook.automountServiceAccountToken
				if !_webhook.serviceAccount.create {
					if _config.imagePullSecrets != _|_ {
						imagePullSecrets: _config.imagePullSecrets
					}
				}
				enableServiceLinks: _webhook.enableServiceLinks
				securityContext:    _webhook.podSecurityContext
				if _webhook.hostNetwork {
					hostNetwork: true
				}
				if _webhook.priorityClassName != _|_ {
					priorityClassName: _webhook.priorityClassName
				}
				if _webhook.runtimeClassName != _|_ {
					runtimeClassName: _webhook.runtimeClassName
				}
				if _webhook.hostUsers != _|_ {
					hostUsers: _webhook.hostUsers
				}
				if _webhook.hostAliases != _|_ {
					hostAliases: _webhook.hostAliases
				}
				if _webhook.dnsPolicy != _|_ {
					dnsPolicy: _webhook.dnsPolicy
				}
				if _webhook.dnsConfig != _|_ {
					dnsConfig: _webhook.dnsConfig
				}
				containers: [
					{
						name:            "cert-manager-webhook"
						image:           _webhook.image.reference
						imagePullPolicy: _webhook.image.pullPolicy
						securityContext: _webhook.securityContext
						args: [
							"--config=/var/cert-manager/config/config.yaml",
							for a in _webhook.extraArgs {a},
						]
						ports: [
							{
								name:          "https"
								protocol:      "TCP"
								containerPort: _webhook.config.securePort
							},
							{
								name:          "healthcheck"
								protocol:      "TCP"
								containerPort: _webhook.config.healthzPort
							},
							if _metricsPort > 0 {
								{
									name:          "http-metrics"
									protocol:      "TCP"
									containerPort: _metricsPort
								}
							},
						]
						livenessProbe:  _webhook.livenessProbe
						readinessProbe: _webhook.readinessProbe
						env: [
							{
								name: "POD_NAMESPACE"
								valueFrom: fieldRef: fieldPath: "metadata.namespace"
							},
							if _webhook.env != _|_ for e in _webhook.env {e},
						]
						volumeMounts: [
							{
								name:      "config"
								mountPath: "/var/cert-manager/config"
							},
							if _webhook.extraVolumeMounts != _|_ for m in _webhook.extraVolumeMounts {m},
						]
						if _webhook.resources != _|_ {
							resources: _webhook.resources
						}
					},
					if _webhook.extraContainers != _|_ for c in _webhook.extraContainers {c},
				]
				volumes: [
					{
						name: "config"
						configMap: name: #cmName
					},
					if _webhook.extraVolumes != _|_ for v in _webhook.extraVolumes {v},
				]
				nodeSelector: _webhook.nodeSelector
				if _webhook.affinity != _|_ {
					affinity: _webhook.affinity
				}
				if _webhook.tolerations != _|_ {
					tolerations: _webhook.tolerations
				}
				if _webhook.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _webhook.topologySpreadConstraints
				}
			}
		}
	}
}
