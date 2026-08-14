package templates

import (
	"strings"

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
	if _config.deploymentAnnotations != _|_ {
		metadata: annotations: _config.deploymentAnnotations
	}

	_volumeMounts: [
		{
			name:      "env"
			mountPath: "/fluent-operator"
		},
		if _config.extraVolumeMounts != _|_ for m in _config.extraVolumeMounts {m},
	]
	_volumes: [
		{
			name: "env"
			configMap: name: _config._envConfigMap.metadata.name
		},
		if _config.extraVolumes != _|_ for v in _config.extraVolumes {v},
	]

	spec: appsv1.#DeploymentSpec & {
		replicas: _config.replicas
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
				annotations: "kubectl.kubernetes.io/default-container": "fluent-operator"
				if _config.podAnnotations != _|_ {
					annotations: _config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _config.serviceAccount.name
				automountServiceAccountToken: _config.automountServiceAccountToken
				securityContext:              _config.podSecurityContext
				nodeSelector:                 _config.nodeSelector
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
				if _affinity.#Enabled {
					affinity: _affinity
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
					name:            "fluent-operator"
					image:           _config.image.reference
					imagePullPolicy: _config.image.pullPolicy
					securityContext: _config.securityContext
					args: [
						// The upstream default disables the metrics
						// server; serve it on the Service port over
						// plain HTTP for the ServiceMonitor.
						"--metrics-bind-address=:\(_config.service.port)",
						"--metrics-secure=false",
						if _config.leaderElection.enabled {
							"--leader-elect"
						},
						if _config.disableComponentControllers != "" {
							"--disable-component-controllers=\(_config.disableComponentControllers)"
						},
						if len(_config.watchNamespaces) > 0 {
							"--watch-namespaces=" + strings.Join(_config.watchNamespaces, ",")
						},
						for a in _config.extraArgs {a},
					]
					env: [
						{
							name: "NAMESPACE"
							valueFrom: fieldRef: fieldPath: "metadata.namespace"
						},
						{
							name:  "CONTAINER_LOG_PATH"
							value: _config._containerLogPath
						},
						if _config.env != _|_ for e in _config.env {e},
					]
					ports: [{
						name:          _config.service.portName
						protocol:      "TCP"
						containerPort: _config.service.port
					}]
					livenessProbe:  _config.livenessProbe
					readinessProbe: _config.readinessProbe
					resources:      _config.resources
					volumeMounts:   _volumeMounts
				}]
				volumes: _volumes
			}
		}
	}
}
