package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#Deployment: appsv1.#Deployment & {
	_config: #Config

	// The affinity rules generated from the affinity values;
	// the anti-affinity presets match the instance selector labels.
	_affinity: timoniv1.#Affinity & {
		#Values:      _config.affinity
		#MatchLabels: _config.selector.labels
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   _config.metadata
	if _config.deploymentLabels != _|_ {
		metadata: labels: _config.deploymentLabels
	}
	if _config.deploymentAnnotations != _|_ {
		metadata: annotations: _config.deploymentAnnotations
	}

	spec: appsv1.#DeploymentSpec & {
		// In operator mode the replica count is left at the API
		// default of one; the manager is leader-elected.
		if _config._serverOnly {
			replicas: _config.web.serverReplicas
		}
		if _config.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _config.revisionHistoryLimit
		}
		if _config.strategy != _|_ {
			strategy: _config.strategy
		}
		selector: matchLabels: _config.selector.labels
		template: {
			metadata: {
				labels: _config.selector.labels
				if _config.podLabels != _|_ {
					labels: _config.podLabels
				}
				if _config.podAnnotations != _|_ {
					annotations: _config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _config.serviceAccount.name
				automountServiceAccountToken: _config.automountServiceAccountToken
				if _config.priorityClassName != _|_ {
					priorityClassName: _config.priorityClassName
				}
				if _config.schedulerName != _|_ {
					schedulerName: _config.schedulerName
				}
				if _config.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: _config.terminationGracePeriodSeconds
				}
				if _config.hostAliases != _|_ {
					hostAliases: _config.hostAliases
				}
				if _config.hostNetwork {
					hostNetwork: true
				}
				if _config.dnsConfig != _|_ {
					dnsConfig: _config.dnsConfig
				}
				if _config.dnsPolicy != _|_ {
					dnsPolicy: _config.dnsPolicy
				}
				if _config.imagePullSecrets != _|_ {
					imagePullSecrets: _config.imagePullSecrets
				}
				securityContext: _config.podSecurityContext
				nodeSelector:    _config.nodeSelector
				if _affinity.#Enabled {
					affinity: _affinity
				}
				if _config.tolerations != _|_ {
					tolerations: _config.tolerations
				}
				if _config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _config.topologySpreadConstraints
				}
				if _config.initContainers != _|_ {
					initContainers: _config.initContainers
				}
				containers: [
					{
						name:            "manager"
						image:           _config.image.reference
						imagePullPolicy: _config.image.pullPolicy
						securityContext: _config.securityContext
						args: [
							"--log-level=\(_config.logLevel)",
							if _config.multitenancy.enabled {
								"--default-service-account=\(_config.multitenancy.defaultServiceAccount)"
							},
							if _config.multitenancy.enabledForWorkloadIdentity {
								"--default-workload-identity-service-account=\(_config.multitenancy.defaultWorkloadIdentityServiceAccount)"
							},
							if _config._serverOnly {
								"--web-server-only=true"
							},
							if _config._createWebConfigSecret {
								"--web-config=/etc/flux-operator/web/config.yaml"
							},
							if _config._useWebConfigSecret {
								"--web-config-secret-name=\(_config.web.configSecretName)"
							},
							for a in _config.extraArgs {a},
						]
						env: [
							{
								name: "RUNTIME_NAMESPACE"
								valueFrom: fieldRef: fieldPath: "metadata.namespace"
							},
							{
								name:  "REPORTING_INTERVAL"
								value: _config.reporting.interval
							},
							{
								name: "WEB_SERVER_PORT"
								if _config.web.enabled {
									value: "9080"
								}
								if !_config.web.enabled {
									value: "0"
								}
							},
							if _config.marketplace.type != _|_ {
								{
									name:  "MARKETPLACE_TYPE"
									value: _config.marketplace.type
								}
							},
							if _config.marketplace.account != _|_ {
								{
									name:  "MARKETPLACE_ACCOUNT"
									value: _config.marketplace.account
								}
							},
							if _config.marketplace.license != _|_ {
								{
									name:  "MARKETPLACE_LICENSE"
									value: _config.marketplace.license
								}
							},
							if _config.env != _|_ for e in _config.env {e},
						]
						ports: [
							{
								name:          "http-metrics"
								protocol:      "TCP"
								containerPort: 8080
							},
							{
								name:          "http"
								protocol:      "TCP"
								containerPort: 8081
							},
							if _config.web.enabled {
								{
									name:          "http-web"
									protocol:      "TCP"
									containerPort: 9080
								}
							},
						]
						livenessProbe:  _config.livenessProbe
						readinessProbe: _config.readinessProbe
						if _config.startupProbe != _|_ {
							startupProbe: _config.startupProbe
						}
						resources: _config.resources
						volumeMounts: [
							{
								name:      "temp"
								mountPath: "/tmp"
							},
							if _config._createWebConfigSecret {
								{
									name:      "web-config"
									mountPath: "/etc/flux-operator/web"
									readOnly:  true
								}
							},
							if _config.extraVolumeMounts != _|_ for m in _config.extraVolumeMounts {m},
						]
					},
					if _config.extraContainers != _|_ for c in _config.extraContainers {c},
				]
				volumes: [
					{
						name: "temp"
						_config.tmpVolume
					},
					if _config._createWebConfigSecret {
						{
							name: "web-config"
							secret: secretName: _config._webConfigSecret.metadata.name
						}
					},
					if _config.extraVolumes != _|_ for v in _config.extraVolumes {v},
				]
			}
		}
	}
}
