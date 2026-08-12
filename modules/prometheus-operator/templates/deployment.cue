package templates

import (
	"strings"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	_config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   _config.metadata
	if _config.deploymentAnnotations != _|_ {
		metadata: annotations: _config.deploymentAnnotations
	}

	_featureGates: [for k, v in _config.featureGates {"\(k)=\(v)"}]

	_volumeMounts: [
		if _config.webhook.enabled {
			{
				name:      "cert"
				mountPath: "/cert"
				readOnly:  true
			}
		},
		if _config.extraVolumeMounts != _|_ for m in _config.extraVolumeMounts {m},
	]
	_volumes: [
		if _config.webhook.enabled {
			{
				name: "cert"
				secret: secretName: _config._tlsSecretName
			}
		},
		if _config.extraVolumes != _|_ for v in _config.extraVolumes {v},
	]

	spec: appsv1.#DeploymentSpec & {
		// The operator has no leader election: a second replica would
		// reconcile the same objects concurrently.
		replicas: 1
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
				annotations: "kubectl.kubernetes.io/default-container": "prometheus-operator"
				if _config.podAnnotations != _|_ {
					annotations: _config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _config.serviceAccount.name
				automountServiceAccountToken: _config.automountServiceAccountToken
				securityContext:              _config.podSecurityContext
				nodeSelector:                 _config.nodeSelector
				if _config.hostNetwork {
					hostNetwork: true
				}
				if _config.schedulerName != _|_ {
					schedulerName: _config.schedulerName
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
				if _config.affinity != _|_ {
					affinity: _config.affinity
				}
				if _config.tolerations != _|_ {
					tolerations: _config.tolerations
				}
				if _config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _config.topologySpreadConstraints
				}
				if _config.priorityClassName != _|_ {
					priorityClassName: _config.priorityClassName
				}
				if _config.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: _config.terminationGracePeriodSeconds
				}
				containers: [{
					name:            "prometheus-operator"
					image:           _config.image.reference
					imagePullPolicy: _config.image.pullPolicy
					securityContext: _config.securityContext
					args: [
						if _config.kubeletService.enabled {
							"--kubelet-service=\(_config.kubeletService.namespace)/\(_config.kubeletService.name)"
						},
						if _config.kubeletService.enabled && _config.kubeletService.selector != "" {
							"--kubelet-selector=\(_config.kubeletService.selector)"
						},
						"--prometheus-config-reloader=\(_config.configReloader.image.reference)",
						"--watch-referenced-objects-in-all-namespaces=\(_config.watchReferencedObjectsInAllNamespaces)",
						"--disable-unmanaged-prometheus-configuration=\(_config.disableUnmanagedPrometheusConfiguration)",
						"--kubelet-endpoints=\(_config.kubeletEndpoints)",
						"--kubelet-endpointslice=\(_config.kubeletEndpointSlice)",
						if len(_config.namespaces) > 0 {
							"--namespaces=" + strings.Join(_config.namespaces, ",")
						},
						if len(_config.denyNamespaces) > 0 {
							"--deny-namespaces=" + strings.Join(_config.denyNamespaces, ",")
						},
						if len(_config.prometheusInstanceNamespaces) > 0 {
							"--prometheus-instance-namespaces=" + strings.Join(_config.prometheusInstanceNamespaces, ",")
						},
						if len(_config.alertmanagerInstanceNamespaces) > 0 {
							"--alertmanager-instance-namespaces=" + strings.Join(_config.alertmanagerInstanceNamespaces, ",")
						},
						if len(_config.alertmanagerConfigNamespaces) > 0 {
							"--alertmanager-config-namespaces=" + strings.Join(_config.alertmanagerConfigNamespaces, ",")
						},
						if len(_config.thanosRulerInstanceNamespaces) > 0 {
							"--thanos-ruler-instance-namespaces=" + strings.Join(_config.thanosRulerInstanceNamespaces, ",")
						},
						if _config.prometheusInstanceSelector != _|_ {
							"--prometheus-instance-selector=\(_config.prometheusInstanceSelector)"
						},
						if _config.alertmanagerInstanceSelector != _|_ {
							"--alertmanager-instance-selector=\(_config.alertmanagerInstanceSelector)"
						},
						if _config.thanosRulerInstanceSelector != _|_ {
							"--thanos-ruler-instance-selector=\(_config.thanosRulerInstanceSelector)"
						},
						if _config.secretFieldSelector != "" {
							"--secret-field-selector=\(_config.secretFieldSelector)"
						},
						if len(_featureGates) > 0 {
							"--feature-gates=" + strings.Join(_featureGates, ",")
						},
						if _config.configReloader.resources != _|_ {
							if _config.configReloader.resources.requests != _|_ {
								if _config.configReloader.resources.requests.cpu != _|_ {
									"--config-reloader-cpu-request=\(_config.configReloader.resources.requests.cpu)"
								}
							}
						},
						if _config.configReloader.resources != _|_ {
							if _config.configReloader.resources.requests != _|_ {
								if _config.configReloader.resources.requests.memory != _|_ {
									"--config-reloader-memory-request=\(_config.configReloader.resources.requests.memory)"
								}
							}
						},
						if _config.configReloader.resources != _|_ {
							if _config.configReloader.resources.limits != _|_ {
								if _config.configReloader.resources.limits.cpu != _|_ {
									"--config-reloader-cpu-limit=\(_config.configReloader.resources.limits.cpu)"
								}
							}
						},
						if _config.configReloader.resources != _|_ {
							if _config.configReloader.resources.limits != _|_ {
								if _config.configReloader.resources.limits.memory != _|_ {
									"--config-reloader-memory-limit=\(_config.configReloader.resources.limits.memory)"
								}
							}
						},
						if _config.configReloader.enableProbe {
							"--enable-config-reloader-probes=true"
						},
						if _config.prometheusDefaultBaseImage != _|_ {
							"--prometheus-default-base-image=\(_config.prometheusDefaultBaseImage)"
						},
						if _config.alertmanagerDefaultBaseImage != _|_ {
							"--alertmanager-default-base-image=\(_config.alertmanagerDefaultBaseImage)"
						},
						if _config.thanosDefaultBaseImage != _|_ {
							"--thanos-default-base-image=\(_config.thanosDefaultBaseImage)"
						},
						if _config.localhostAddress != _|_ {
							"--localhost=\(_config.localhostAddress)"
						},
						if _config.clusterDomain != "" {
							"--cluster-domain=\(_config.clusterDomain)"
						},
						if _config.logLevel != "info" {
							"--log-level=\(_config.logLevel)"
						},
						if _config.logFormat != "logfmt" {
							"--log-format=\(_config.logFormat)"
						},
						if _config.webhook.enabled {
							"--web.enable-tls=true"
						},
						if _config.webhook.enabled {
							"--web.listen-address=:\(_config.webhook.port)"
						},
						if _config.webhook.enabled {
							"--web.cert-file=/cert/tls.crt"
						},
						if _config.webhook.enabled {
							"--web.key-file=/cert/tls.key"
						},
						if _config.webhook.enabled {
							"--web.tls-min-version=\(_config.webhook.tls.minVersion)"
						},
						if _config.webhook.enabled && _config.webhook.tls.cipherSuites != _|_ {
							"--web.tls-cipher-suites=" + strings.Join(_config.webhook.tls.cipherSuites, ",")
						},
						for a in _config.extraArgs {a},
					]
					env: _config.env
					ports: [
						if !_config.webhook.enabled {
							{
								name:          "http"
								protocol:      "TCP"
								containerPort: 8080
							}
						},
						if _config.webhook.enabled {
							{
								name:          "https"
								protocol:      "TCP"
								containerPort: _config.webhook.port
							}
						},
					]
					livenessProbe:  _config.livenessProbe
					readinessProbe: _config.readinessProbe
					resources:      _config.resources
					if len(_volumeMounts) > 0 {
						volumeMounts: _volumeMounts
					}
				}]
				if len(_volumes) > 0 {
					volumes: _volumes
				}
			}
		}
	}
}
