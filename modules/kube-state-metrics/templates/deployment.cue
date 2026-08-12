package templates

import (
	"strings"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

// PodTemplate holds the pod template shared between the Deployment and
// the autosharding StatefulSet.
#PodTemplate: {
	_config: #Config

	// With autosharding, the pods derive their shard number from their
	// StatefulSet ordinal passed down through the downward API.
	_env: [
		if _config.autosharding.enabled {
			{name: "POD_NAME", valueFrom: fieldRef: fieldPath: "metadata.name"}
		},
		if _config.autosharding.enabled {
			{name: "POD_NAMESPACE", valueFrom: fieldRef: fieldPath: "metadata.namespace"}
		},
		for e in _config.env {e},
	]

	_volumeMounts: [
		if _config.kubeconfigSecret != _|_ {
			{
				name:      "kubeconfig"
				mountPath: "/opt/k8s/.kube/"
				readOnly:  true
			}
		},
		if _config.customResourceState.enabled {
			{
				name:      "customresourcestate-config"
				mountPath: "/etc/customresourcestate"
				readOnly:  true
			}
		},
		if _config.extraVolumeMounts != _|_ for m in _config.extraVolumeMounts {m},
	]
	_volumes: [
		if _config.kubeconfigSecret != _|_ {
			{
				name: "kubeconfig"
				secret: secretName: _config.kubeconfigSecret.name
			}
		},
		if _config.customResourceState.enabled {
			{
				name: "customresourcestate-config"
				configMap: name: _config._crsVolumeConfigMapName
			}
		},
		if _config.extraVolumes != _|_ for v in _config.extraVolumes {v},
	]

	template: corev1.#PodTemplateSpec & {
		metadata: {
			labels: _config.selector.labels
			if _config.podLabels != _|_ {
				labels: _config.podLabels
			}
			annotations: "kubectl.kubernetes.io/default-container": "kube-state-metrics"
			if _config.podAnnotations != _|_ {
				annotations: _config.podAnnotations
			}
		}
		spec: corev1.#PodSpec & {
			serviceAccountName:           _config.serviceAccount.name
			automountServiceAccountToken: _config.automountServiceAccountToken
			securityContext:              _config.podSecurityContext
			nodeSelector:                 _config.nodeSelector
			dnsPolicy:                    _config.dnsPolicy
			if _config.hostNetwork {
				hostNetwork: true
			}
			if _config.hostUsers != _|_ {
				hostUsers: _config.hostUsers
			}
			if _config.dnsConfig != _|_ {
				dnsConfig: _config.dnsConfig
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
			if _config.schedulerName != _|_ {
				schedulerName: _config.schedulerName
			}
			if _config.terminationGracePeriodSeconds != _|_ {
				terminationGracePeriodSeconds: _config.terminationGracePeriodSeconds
			}
			if _config.initContainers != _|_ {
				initContainers: _config.initContainers
			}
			containers: [
				{
					name:            "kube-state-metrics"
					image:           _config.image.reference
					imagePullPolicy: _config.image.pullPolicy
					securityContext: _config.securityContext
					args: [
						"--port=\(_config.service.port)",
						if len(_config.collectors) > 0 {
							"--resources=" + strings.Join(_config.collectors, ",")
						},
						if len(_config.metricLabelsAllowlist) > 0 {
							"--metric-labels-allowlist=" + strings.Join(_config.metricLabelsAllowlist, ",")
						},
						if len(_config.metricAnnotationsAllowList) > 0 {
							"--metric-annotations-allowlist=" + strings.Join(_config.metricAnnotationsAllowList, ",")
						},
						if len(_config.metricAllowlist) > 0 {
							"--metric-allowlist=" + strings.Join(_config.metricAllowlist, ",")
						},
						if len(_config.metricDenylist) > 0 {
							"--metric-denylist=" + strings.Join(_config.metricDenylist, ",")
						},
						if len(_config.namespaces) > 0 {
							"--namespaces=" + strings.Join(_config.namespaces, ",")
						},
						if len(_config.namespacesDenylist) > 0 {
							"--namespaces-denylist=" + strings.Join(_config.namespacesDenylist, ",")
						},
						if _config.autosharding.enabled {
							"--pod=$(POD_NAME)"
						},
						if _config.autosharding.enabled {
							"--pod-namespace=$(POD_NAMESPACE)"
						},
						if _config.kubeconfigSecret != _|_ {
							"--kubeconfig=/opt/k8s/.kube/config"
						},
						if _config.selfMonitor.telemetryHost != "" {
							"--telemetry-host=\(_config.selfMonitor.telemetryHost)"
						},
						if _config.selfMonitor.telemetryPort != 8081 {
							"--telemetry-port=\(_config.selfMonitor.telemetryPort)"
						},
						if _config.customResourceState.enabled {
							"--custom-resource-state-config-file=/etc/customresourcestate/\(_config._crsFileName)"
						},
						if _config.customResourceState.enabled && _config.customResourceState.only {
							"--custom-resource-state-only"
						},
						if _config.authFilter.enabled {
							"--auth-filter"
						},
						for a in _config.extraArgs {a},
					]
					if len(_env) > 0 {
						env: _env
					}
					ports: [
						{
							name:          "http"
							protocol:      "TCP"
							containerPort: _config.service.port
						},
						{
							name:          "metrics"
							protocol:      "TCP"
							containerPort: _config.selfMonitor.telemetryPort
						},
					]
					livenessProbe:  _config.livenessProbe
					readinessProbe: _config.readinessProbe
					if _config.startupProbe != _|_ {
						startupProbe: _config.startupProbe
					}
					resources: _config.resources
					if len(_volumeMounts) > 0 {
						volumeMounts: _volumeMounts
					}
				},
				if _config.extraContainers != _|_ for c in _config.extraContainers {c},
			]
			if len(_volumes) > 0 {
				volumes: _volumes
			}
		}
	}
}

#Deployment: appsv1.#Deployment & {
	_config: #Config
	let Config = _config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   _config.metadata
	if _config.workloadLabels != _|_ {
		metadata: labels: _config.workloadLabels
	}
	if _config.workloadAnnotations != _|_ {
		metadata: annotations: _config.workloadAnnotations
	}
	spec: appsv1.#DeploymentSpec & {
		replicas: _config.replicas
		if _config.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _config.revisionHistoryLimit
		}
		if _config.strategy != _|_ {
			strategy: _config.strategy
		}
		selector: matchLabels: _config.selector.labels
		template: (#PodTemplate & {_config: Config}).template
	}
}

#StatefulSet: appsv1.#StatefulSet & {
	_config: #Config
	let Config = _config
	apiVersion: "apps/v1"
	kind:       "StatefulSet"
	metadata:   _config.metadata
	if _config.workloadLabels != _|_ {
		metadata: labels: _config.workloadLabels
	}
	if _config.workloadAnnotations != _|_ {
		metadata: annotations: _config.workloadAnnotations
	}
	spec: appsv1.#StatefulSetSpec & {
		replicas:    _config.replicas
		serviceName: _config.metadata.name
		if _config.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _config.revisionHistoryLimit
		}
		selector: matchLabels: _config.selector.labels
		template: (#PodTemplate & {_config: Config}).template
	}
}
