package recommender

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

#Deployment: appsv1.#Deployment & {
	#config: config.#Config
	_config: #config

	_r:  _config.recommender
	_le: _r.leaderElection
	_selectorLabels: #SelectorLabels & {#config: _config}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: #ObjectMeta & {#config: _config}
	if _r.deploymentAnnotations != _|_ {
		metadata: annotations: _r.deploymentAnnotations
	}

	spec: appsv1.#DeploymentSpec & {
		replicas:             _r.replicas
		revisionHistoryLimit: _r.revisionHistoryLimit
		if _r.strategy != _|_ {
			strategy: _r.strategy
		}
		selector: matchLabels: _selectorLabels
		template: {
			metadata: {
				labels: _selectorLabels
				if _r.podLabels != _|_ {
					labels: _r.podLabels
				}
				if _r.podAnnotations != _|_ {
					annotations: _r.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _r.serviceAccount.name
				automountServiceAccountToken: _r.automountServiceAccountToken
				if !_r.serviceAccount.create {
					if _config.imagePullSecrets != _|_ {
						imagePullSecrets: _config.imagePullSecrets
					}
				}
				securityContext: _r.podSecurityContext
				if _r.priorityClassName != _|_ {
					priorityClassName: _r.priorityClassName
				}
				if _r.dnsPolicy != _|_ {
					dnsPolicy: _r.dnsPolicy
				}
				if _r.dnsConfig != _|_ {
					dnsConfig: _r.dnsConfig
				}
				if _r.schedulerName != _|_ {
					schedulerName: _r.schedulerName
				}
				if _r.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: _r.terminationGracePeriodSeconds
				}
				containers: [{
					name:            "recommender"
					image:           _r.image.reference
					imagePullPolicy: _r.image.pullPolicy
					securityContext: _r.securityContext
					env: [
						{
							name: "NAMESPACE"
							valueFrom: fieldRef: fieldPath: "metadata.namespace"
						},
						if _r.env != _|_ for e in _r.env {e},
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
						for a in _r.extraArgs {a},
					]
					ports: [{
						name:          "prometheus"
						containerPort: #MetricsPort
						protocol:      "TCP"
					}]
					livenessProbe:  _r.livenessProbe
					readinessProbe: _r.readinessProbe
					if _r.resources != _|_ {
						resources: _r.resources
					}
					if _r.extraVolumeMounts != _|_ {
						volumeMounts: _r.extraVolumeMounts
					}
				}]
				if _r.extraVolumes != _|_ {
					volumes: _r.extraVolumes
				}
				nodeSelector: _r.nodeSelector
				affinity:     _r.affinity
				if _r.tolerations != _|_ {
					tolerations: _r.tolerations
				}
				if _r.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _r.topologySpreadConstraints
				}
			}
		}
	}
}
