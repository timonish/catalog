package templates

import (
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

	// The namespace watched for sources in the namespaced scope.
	_sourceNamespace: [
		if _config.sourceNamespace != _|_ {_config.sourceNamespace},
		_config.metadata.namespace,
	][0]

	spec: appsv1.#DeploymentSpec & {
		replicas: _config.replicas
		if _config.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _config.revisionHistoryLimit
		}
		strategy: _config.strategy
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
				automountServiceAccountToken: _config.automountServiceAccountToken
				serviceAccountName:           _config.serviceAccount.name
				if _config.imagePullSecrets != _|_ {
					imagePullSecrets: _config.imagePullSecrets
				}
				if _config.shareProcessNamespace {
					shareProcessNamespace: true
				}
				securityContext: _config.podSecurityContext
				if _config.priorityClassName != _|_ {
					priorityClassName: _config.priorityClassName
				}
				if _config.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: _config.terminationGracePeriodSeconds
				}
				if _config.dnsPolicy != _|_ {
					dnsPolicy: _config.dnsPolicy
				}
				if _config.dnsConfig != _|_ {
					dnsConfig: _config.dnsConfig
				}
				if _config.initContainers != _|_ {
					initContainers: _config.initContainers
				}
				containers: [
					if _config.extraContainers != _|_ for c in _config.extraContainers {c},
					{
						name:            "external-dns"
						securityContext: _config.securityContext
						image:           _config.image.reference
						imagePullPolicy: _config.image.pullPolicy
						if _config.env != _|_ {
							env: _config.env
						}
						args: [
							"--log-level=\(_config.logLevel)",
							"--log-format=\(_config.logFormat)",
							"--interval=\(_config.interval)",
							if _config.triggerLoopOnEvent {
								"--events"
							},
							for s in _config.sources {
								"--source=\(s)"
							},
							"--policy=\(_config.policy)",
							"--registry=\(_config.registry)",
							if _config.txtOwnerId != _|_ {
								"--txt-owner-id=\(_config.txtOwnerId)"
							},
							if _config.txtPrefix != _|_ {
								"--txt-prefix=\(_config.txtPrefix)"
							},
							if _config.txtSuffix != _|_ {
								"--txt-suffix=\(_config.txtSuffix)"
							},
							if _config.namespaced {
								"--namespace=\(_sourceNamespace)"
							},
							if _config.gatewayNamespace != _|_ {
								"--gateway-namespace=\(_config.gatewayNamespace)"
							},
							if _config.enableGatewayListenerSets {
								"--gateway-listener-sets"
							},
							for d in _config.domainFilters {
								"--domain-filter=\(d)"
							},
							for d in _config.excludeDomains {
								"--exclude-domains=\(d)"
							},
							if _config.labelFilter != _|_ {
								"--label-filter=\(_config.labelFilter)"
							},
							if _config.annotationFilter != _|_ {
								"--annotation-filter=\(_config.annotationFilter)"
							},
							if _config.annotationPrefix != _|_ {
								"--annotation-prefix=\(_config.annotationPrefix)"
							},
							for t in _config.managedRecordTypes {
								"--managed-record-types=\(t)"
							},
							"--provider=\(_config.provider.name)",
							for a in _config.extraArgs {a},
						]
						ports: [{
							name:          "http"
							protocol:      "TCP"
							containerPort: 7979
						}]
						livenessProbe:  _config.livenessProbe
						readinessProbe: _config.readinessProbe
						if _config.extraVolumeMounts != _|_ {
							volumeMounts: _config.extraVolumeMounts
						}
						if _config.resources != _|_ {
							resources: _config.resources
						}
					},
					if _config.provider.name == "webhook" {
						{
							_webhook:        _config.provider.webhook
							name:            "webhook"
							image:           _webhook.image.reference
							imagePullPolicy: _webhook.image.pullPolicy
							if _webhook.env != _|_ {
								env: _webhook.env
							}
							if len(_webhook.args) > 0 {
								args: _webhook.args
							}
							ports: [{
								name:          "http-webhook"
								protocol:      "TCP"
								containerPort: 8080
							}]
							livenessProbe:  _webhook.livenessProbe
							readinessProbe: _webhook.readinessProbe
							if _webhook.extraVolumeMounts != _|_ {
								volumeMounts: _webhook.extraVolumeMounts
							}
							if _webhook.resources != _|_ {
								resources: _webhook.resources
							}
							if _webhook.securityContext != _|_ {
								securityContext: _webhook.securityContext
							}
						}
					},
				]
				if _config.extraVolumes != _|_ {
					volumes: _config.extraVolumes
				}
				if _config.nodeSelector != _|_ {
					nodeSelector: _config.nodeSelector
				}
				if _config.affinity != _|_ {
					affinity: #AffinityWithDefaultSelector & {
						_affinity: _config.affinity
						_labels:   _config.selector.labels
					}
				}
				if _config.topologySpreadConstraints != _|_ {
					// Constraints without an explicit label selector match
					// the instance pods.
					topologySpreadConstraints: [
						for c in _config.topologySpreadConstraints {
							c
							if c.labelSelector == _|_ {
								labelSelector: matchLabels: _config.selector.labels
							}
						},
					]
				}
				if _config.tolerations != _|_ {
					tolerations: _config.tolerations
				}
			}
		}
	}
}

// Pod affinity and anti-affinity terms without an explicit label
// selector are completed with the instance selector labels.
#AffinityWithDefaultSelector: {
	_affinity: corev1.#Affinity
	_labels: {[string]: string}

	if _affinity.nodeAffinity != _|_ {
		nodeAffinity: _affinity.nodeAffinity
	}
	if _affinity.podAffinity != _|_ {
		podAffinity: {
			if _affinity.podAffinity.preferredDuringSchedulingIgnoredDuringExecution != _|_ {
				preferredDuringSchedulingIgnoredDuringExecution: [
					for t in _affinity.podAffinity.preferredDuringSchedulingIgnoredDuringExecution {
						weight:          t.weight
						podAffinityTerm: t.podAffinityTerm
						if t.podAffinityTerm.labelSelector == _|_ {
							podAffinityTerm: labelSelector: matchLabels: _labels
						}
					},
				]
			}
			if _affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution != _|_ {
				requiredDuringSchedulingIgnoredDuringExecution: [
					for t in _affinity.podAffinity.requiredDuringSchedulingIgnoredDuringExecution {
						t
						if t.labelSelector == _|_ {
							labelSelector: matchLabels: _labels
						}
					},
				]
			}
		}
	}
	if _affinity.podAntiAffinity != _|_ {
		podAntiAffinity: {
			if _affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution != _|_ {
				preferredDuringSchedulingIgnoredDuringExecution: [
					for t in _affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution {
						weight:          t.weight
						podAffinityTerm: t.podAffinityTerm
						if t.podAffinityTerm.labelSelector == _|_ {
							podAffinityTerm: labelSelector: matchLabels: _labels
						}
					},
				]
			}
			if _affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution != _|_ {
				requiredDuringSchedulingIgnoredDuringExecution: [
					for t in _affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution {
						t
						if t.labelSelector == _|_ {
							labelSelector: matchLabels: _labels
						}
					},
				]
			}
		}
	}
}
