package updater

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

#Deployment: appsv1.#Deployment & {
	#config: config.#Config
	_config: #config

	_u:  _config.updater
	_le: _u.leaderElection
	_selectorLabels: #SelectorLabels & {#config: _config}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: #ObjectMeta & {#config: _config}
	if _u.deploymentAnnotations != _|_ {
		metadata: annotations: _u.deploymentAnnotations
	}

	spec: appsv1.#DeploymentSpec & {
		replicas:             _u.replicas
		revisionHistoryLimit: _u.revisionHistoryLimit
		if _u.strategy != _|_ {
			strategy: _u.strategy
		}
		selector: matchLabels: _selectorLabels
		template: {
			metadata: {
				labels: _selectorLabels
				if _u.podLabels != _|_ {
					labels: _u.podLabels
				}
				if _u.podAnnotations != _|_ {
					annotations: _u.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: _u.serviceAccount.name
				if !_u.serviceAccount.create {
					if _config.imagePullSecrets != _|_ {
						imagePullSecrets: _config.imagePullSecrets
					}
				}
				securityContext: _u.podSecurityContext
				if _u.priorityClassName != _|_ {
					priorityClassName: _u.priorityClassName
				}
				if _u.dnsPolicy != _|_ {
					dnsPolicy: _u.dnsPolicy
				}
				containers: [{
					name:            "updater"
					image:           _u.image.reference
					imagePullPolicy: _u.image.pullPolicy
					securityContext: _u.securityContext
					env: [
						{
							name: "NAMESPACE"
							valueFrom: fieldRef: fieldPath: "metadata.namespace"
						},
						if _u.env != _|_ for e in _u.env {e},
					]
					args: [
						"--v=4",
						"--stderrthreshold=info",
						if _le.enabled {"--leader-elect=true"},
						if _le.enabled {"--leader-elect-resource-namespace=\(_le.resourceNamespace)"},
						if _le.enabled {"--leader-elect-resource-name=\(_le.resourceName)"},
						if _le.enabled {"--leader-elect-lease-duration=\(_le.leaseDuration)"},
						if _le.enabled {"--leader-elect-renew-deadline=\(_le.renewDeadline)"},
						if _le.enabled {"--leader-elect-retry-period=\(_le.retryPeriod)"},
						"--in-place-skip-disruption-budget=\(_u.inPlaceSkipDisruptionBudget)",
						for a in _u.extraArgs {a},
					]
					ports: [{
						name:          "prometheus"
						containerPort: #MetricsPort
						protocol:      "TCP"
					}]
					livenessProbe: {
						httpGet: {
							path:   "/health-check"
							port:   "prometheus"
							scheme: "HTTP"
						}
						initialDelaySeconds: 5
						periodSeconds:       10
						failureThreshold:    3
					}
					readinessProbe: {
						httpGet: {
							path:   "/health-check"
							port:   "prometheus"
							scheme: "HTTP"
						}
						periodSeconds:    10
						failureThreshold: 3
					}
					if _u.resources != _|_ {
						resources: _u.resources
					}
				}]
				nodeSelector: _u.nodeSelector
				affinity:     _u.affinity
				if _u.tolerations != _|_ {
					tolerations: _u.tolerations
				}
				if _u.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _u.topologySpreadConstraints
				}
			}
		}
	}
}
