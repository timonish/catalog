package controller

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/external-secrets/templates/config"
)

#Deployment: appsv1.#Deployment & {
	#config: config.#Config
	_config: #config

	_ctrl: _config.controller
	_selectorLabels: #SelectorLabels & {#config: _config}

	// The affinity rules generated from the affinity values;
	// the anti-affinity presets match the component pods.
	_affinity: timoniv1.#Affinity & {
		#Values:      _ctrl.affinity
		#MatchLabels: _selectorLabels
	}

	_scopedNamespace: [
		if _config.scopedNamespace != _|_ {_config.scopedNamespace},
		_config.metadata.namespace,
	][0]

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: #ObjectMeta & {#config: _config}
	if _ctrl.deploymentAnnotations != _|_ {
		metadata: annotations: _ctrl.deploymentAnnotations
	}

	spec: appsv1.#DeploymentSpec & {
		replicas: _ctrl.replicas
		if _ctrl.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _ctrl.revisionHistoryLimit
		}
		if _ctrl.strategy != _|_ {
			strategy: _ctrl.strategy
		}
		selector: matchLabels: _selectorLabels
		template: {
			metadata: {
				labels: _selectorLabels
				if _ctrl.podLabels != _|_ {
					labels: _ctrl.podLabels
				}
				if _ctrl.podAnnotations != _|_ {
					annotations: _ctrl.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _ctrl.serviceAccount.name
				automountServiceAccountToken: _ctrl.automountServiceAccountToken
				if !_ctrl.serviceAccount.create {
					if _config.imagePullSecrets != _|_ {
						imagePullSecrets: _config.imagePullSecrets
					}
				}
				enableServiceLinks: _ctrl.enableServiceLinks
				securityContext:    _ctrl.podSecurityContext
				if _ctrl.hostNetwork {
					hostNetwork: true
				}
				if _ctrl.priorityClassName != _|_ {
					priorityClassName: _ctrl.priorityClassName
				}
				if _ctrl.schedulerName != _|_ {
					schedulerName: _ctrl.schedulerName
				}
				if _ctrl.runtimeClassName != _|_ {
					runtimeClassName: _ctrl.runtimeClassName
				}
				if _ctrl.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: _ctrl.terminationGracePeriodSeconds
				}

				// hostUsers requires Kubernetes 1.33 or newer.
				if _ctrl.hostUsers != _|_ &&
					(_config.clusterVersion.major > 1 || _config.clusterVersion.minor >= 33) {
					hostUsers: _ctrl.hostUsers
				}
				if _ctrl.hostAliases != _|_ {
					hostAliases: _ctrl.hostAliases
				}
				if _ctrl.dnsPolicy != _|_ {
					dnsPolicy: _ctrl.dnsPolicy
				}
				if _ctrl.dnsConfig != _|_ {
					dnsConfig: _ctrl.dnsConfig
				}
				if _ctrl.initContainers != _|_ {
					initContainers: _ctrl.initContainers
				}
				containers: [
					{
						name:            "external-secrets"
						image:           _config.image.reference
						imagePullPolicy: _config.image.pullPolicy
						securityContext: _ctrl.securityContext
						args: [
							if _ctrl.leaderElection.enabled {
								"--enable-leader-election=true"
							},
							"--leader-election-id=\(_ctrl.leaderElection.id)",
							if _ctrl.leaderElection.leaseDuration != _|_ {
								"--leader-election-lease-duration=\(_ctrl.leaderElection.leaseDuration)"
							},
							if _ctrl.leaderElection.renewDeadline != _|_ {
								"--leader-election-renew-deadline=\(_ctrl.leaderElection.renewDeadline)"
							},
							if _ctrl.leaderElection.retryPeriod != _|_ {
								"--leader-election-retry-period=\(_ctrl.leaderElection.retryPeriod)"
							},
							if _config.scopedNamespace != _|_ || _config.scopedRBAC {
								"--namespace=\(_scopedNamespace)"
							},
							if !_ctrl.reconcilers.clusterStore {
								"--enable-cluster-store-reconciler=false"
							},
							if !_ctrl.reconcilers.clusterExternalSecret {
								"--enable-cluster-external-secret-reconciler=false"
							},
							if !_ctrl.reconcilers.clusterPushSecret {
								"--enable-cluster-push-secret-reconciler=false"
							},
							if !_ctrl.reconcilers.pushSecret {
								"--enable-push-secret-reconciler=false"
							},
							if !_ctrl.reconcilers.secretStore {
								"--enable-secret-store-reconciler=false"
							},
							if _ctrl.storeRequeueInterval != _|_ {
								"--store-requeue-interval=\(_ctrl.storeRequeueInterval)"
							},
							if _ctrl.controllerClass != _|_ {
								"--controller-class=\(_ctrl.controllerClass)"
							},
							if _ctrl.extendedMetricLabels {
								"--enable-extended-metric-labels=true"
							},
							if _config.enableHTTP2 {
								"--enable-http2=true"
							},
							if _ctrl.vault.enableTokenCache {
								"--enable-vault-token-cache=true"
							},
							if _ctrl.vault.enableTokenCache {
								"--vault-token-cache-size=\(_ctrl.vault.tokenCacheSize)"
							},
							"--concurrent=\(_ctrl.concurrent)",
							if _ctrl.genericTargets.enabled {
								"--unsafe-allow-generic-targets=true"
							},
							"--metrics-addr=:\(_ctrl.metrics.port)",
							"--live-addr=:\(_ctrl.healthPort)",
							"--loglevel=\(_ctrl.logLevel)",
							"--zap-time-encoding=\(_ctrl.logTimeEncoding)",
							for a in (config.#MetricsSecureArgs & {#metrics: _ctrl.metrics}).args {a},
							if _ctrl.metrics.auth.enabled {
								"--metrics-auth=true"
							},
							for a in _ctrl.extraArgs {a},
						]
						ports: [
							{
								name:          "metrics"
								protocol:      "TCP"
								containerPort: _ctrl.metrics.port
							},
							{
								name:          "healthz"
								protocol:      "TCP"
								containerPort: _ctrl.healthPort
							},
						]
						livenessProbe:  _ctrl.livenessProbe
						readinessProbe: _ctrl.readinessProbe
						if _ctrl.env != _|_ {
							env: _ctrl.env
						}
						if _ctrl.extraVolumeMounts != _|_ {
							volumeMounts: _ctrl.extraVolumeMounts
						}
						if _ctrl.resources != _|_ {
							resources: _ctrl.resources
						}
					},
					if _ctrl.extraContainers != _|_ for c in _ctrl.extraContainers {c},
				]
				if _ctrl.extraVolumes != _|_ {
					volumes: _ctrl.extraVolumes
				}
				nodeSelector: _ctrl.nodeSelector
				if _affinity.#Enabled {
					affinity: _affinity
				}
				if _ctrl.tolerations != _|_ {
					tolerations: _ctrl.tolerations
				}
				if _ctrl.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _ctrl.topologySpreadConstraints
				}
			}
		}
	}
}
