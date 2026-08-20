package webhook

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/external-secrets/templates/config"
)

// The directory the serving certificate Secret is mounted at.
_certDir: "/tmp/certs"

#Deployment: appsv1.#Deployment & {
	#config: config.#Config
	_config: #config

	_webhook: _config.webhook
	_selectorLabels: #SelectorLabels & {#config: _config}

	// The affinity rules generated from the affinity values;
	// the anti-affinity presets match the component pods.
	_affinity: timoniv1.#Affinity & {
		#Values:      _webhook.affinity
		#MatchLabels: _selectorLabels
	}

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
				if _webhook.schedulerName != _|_ {
					schedulerName: _webhook.schedulerName
				}
				if _webhook.runtimeClassName != _|_ {
					runtimeClassName: _webhook.runtimeClassName
				}
				if _webhook.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: _webhook.terminationGracePeriodSeconds
				}

				// hostUsers requires Kubernetes 1.33 or newer.
				if _webhook.hostUsers != _|_ &&
					(_config.clusterVersion.major > 1 || _config.clusterVersion.minor >= 33) {
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
				if _webhook.initContainers != _|_ {
					initContainers: _webhook.initContainers
				}
				containers: [
					{
						name:            "webhook"
						image:           _config.image.reference
						imagePullPolicy: _config.image.pullPolicy
						securityContext: _webhook.securityContext
						args: [
							"webhook",
							"--port=\(_webhook.port)",
							"--dns-name=\(_config.metadata.name)-webhook.\(_config.metadata.namespace).svc",
							"--cert-dir=\(_certDir)",
							"--check-interval=\(_webhook.certCheckInterval)",
							if _webhook.lookaheadInterval != _|_ {
								"--lookahead-interval=\(_webhook.lookaheadInterval)"
							},
							"--metrics-addr=:\(_webhook.metrics.port)",
							"--healthz-addr=:\(_webhook.healthPort)",
							"--loglevel=\(_webhook.logLevel)",
							"--zap-time-encoding=\(_webhook.logTimeEncoding)",
							if _config.enableHTTP2 {
								"--enable-http2=true"
							},
							for a in (config.#MetricsSecureArgs & {#metrics: _webhook.metrics}).args {a},
							if _webhook.metrics.auth.enabled {
								"--metrics-auth=true"
							},
							for a in _webhook.extraArgs {a},
						]
						ports: [
							{
								name:          "webhook"
								protocol:      "TCP"
								containerPort: _webhook.port
							},
							{
								name:          "metrics"
								protocol:      "TCP"
								containerPort: _webhook.metrics.port
							},
							{
								name:          "healthz"
								protocol:      "TCP"
								containerPort: _webhook.healthPort
							},
						]
						livenessProbe:  _webhook.livenessProbe
						readinessProbe: _webhook.readinessProbe
						if _webhook.startupProbe != _|_ {
							startupProbe: _webhook.startupProbe
						}
						if _webhook.env != _|_ {
							env: _webhook.env
						}
						volumeMounts: [
							{
								name:      "certs"
								mountPath: _certDir
								readOnly:  true
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
						name: "certs"
						secret: secretName: _webhook.tls.secretName
					},
					if _webhook.extraVolumes != _|_ for v in _webhook.extraVolumes {v},
				]
				nodeSelector: _webhook.nodeSelector
				if _affinity.#Enabled {
					affinity: _affinity
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
