package certcontroller

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/external-secrets/templates/config"
)

#Deployment: appsv1.#Deployment & {
	#config: config.#Config
	_config: #config

	_cc: _config.certController
	_selectorLabels: #SelectorLabels & {#config: _config}

	// The affinity rules generated from the affinity values;
	// the anti-affinity presets match the component pods.
	_affinity: timoniv1.#Affinity & {
		#Values:      _cc.affinity
		#MatchLabels: _selectorLabels
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: #ObjectMeta & {#config: _config}
	if _cc.deploymentAnnotations != _|_ {
		metadata: annotations: _cc.deploymentAnnotations
	}

	spec: appsv1.#DeploymentSpec & {
		replicas: _cc.replicas
		if _cc.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _cc.revisionHistoryLimit
		}
		if _cc.strategy != _|_ {
			strategy: _cc.strategy
		}
		selector: matchLabels: _selectorLabels
		template: {
			metadata: {
				labels: _selectorLabels
				if _cc.podLabels != _|_ {
					labels: _cc.podLabels
				}
				if _cc.podAnnotations != _|_ {
					annotations: _cc.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _cc.serviceAccount.name
				automountServiceAccountToken: _cc.automountServiceAccountToken
				if !_cc.serviceAccount.create {
					if _config.imagePullSecrets != _|_ {
						imagePullSecrets: _config.imagePullSecrets
					}
				}
				enableServiceLinks: _cc.enableServiceLinks
				securityContext:    _cc.podSecurityContext
				if _cc.hostNetwork {
					hostNetwork: true
				}
				if _cc.priorityClassName != _|_ {
					priorityClassName: _cc.priorityClassName
				}
				if _cc.schedulerName != _|_ {
					schedulerName: _cc.schedulerName
				}
				if _cc.runtimeClassName != _|_ {
					runtimeClassName: _cc.runtimeClassName
				}
				if _cc.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: _cc.terminationGracePeriodSeconds
				}

				// hostUsers requires Kubernetes 1.33 or newer.
				if _cc.hostUsers != _|_ &&
					(_config.clusterVersion.major > 1 || _config.clusterVersion.minor >= 33) {
					hostUsers: _cc.hostUsers
				}
				if _cc.hostAliases != _|_ {
					hostAliases: _cc.hostAliases
				}
				if _cc.dnsPolicy != _|_ {
					dnsPolicy: _cc.dnsPolicy
				}
				if _cc.dnsConfig != _|_ {
					dnsConfig: _cc.dnsConfig
				}
				if _cc.initContainers != _|_ {
					initContainers: _cc.initContainers
				}
				containers: [
					{
						name:            "cert-controller"
						image:           _config.image.reference
						imagePullPolicy: _config.image.pullPolicy
						securityContext: _cc.securityContext
						args: [
							"certcontroller",
							"--crd-requeue-interval=\(_cc.requeueInterval)",
							"--service-name=\(_config.metadata.name)-webhook",
							"--service-namespace=\(_config.metadata.namespace)",
							"--secret-name=\(_config.webhook.tls.secretName)",
							"--secret-namespace=\(_config.metadata.namespace)",
							"--metrics-addr=:\(_cc.metrics.port)",
							"--healthz-addr=:\(_cc.healthPort)",
							"--loglevel=\(_cc.logLevel)",
							"--zap-time-encoding=\(_cc.logTimeEncoding)",
							if _cc.enablePartialCache {
								"--enable-partial-cache=true"
							},
							if _config.enableHTTP2 {
								"--enable-http2=true"
							},
							if _cc.leaderElection.enabled {
								"--enable-leader-election=true"
							},
							for a in (config.#MetricsSecureArgs & {#metrics: _cc.metrics}).args {a},
							if _cc.metrics.auth.enabled {
								"--metrics-auth=true"
							},
							for a in _cc.extraArgs {a},
						]
						ports: [
							{
								name:          "metrics"
								protocol:      "TCP"
								containerPort: _cc.metrics.port
							},
							{
								name:          "healthz"
								protocol:      "TCP"
								containerPort: _cc.healthPort
							},
						]
						livenessProbe:  _cc.livenessProbe
						readinessProbe: _cc.readinessProbe
						if _cc.startupProbe != _|_ {
							startupProbe: _cc.startupProbe
						}
						if _cc.env != _|_ {
							env: _cc.env
						}
						if _cc.extraVolumeMounts != _|_ {
							volumeMounts: _cc.extraVolumeMounts
						}
						if _cc.resources != _|_ {
							resources: _cc.resources
						}
					},
					if _cc.extraContainers != _|_ for c in _cc.extraContainers {c},
				]
				if _cc.extraVolumes != _|_ {
					volumes: _cc.extraVolumes
				}
				nodeSelector: _cc.nodeSelector
				if _affinity.#Enabled {
					affinity: _affinity
				}
				if _cc.tolerations != _|_ {
					tolerations: _cc.tolerations
				}
				if _cc.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _cc.topologySpreadConstraints
				}
			}
		}
	}
}
