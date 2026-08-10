package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	_config: #Config

	_env: [
		{
			name: "ENVOY_GATEWAY_NAMESPACE"
			valueFrom: fieldRef: fieldPath: "metadata.namespace"
		},
		{
			name:  "KUBERNETES_CLUSTER_DOMAIN"
			value: _config.kubernetesClusterDomain
		},
		if _config.extraEnv != _|_ for e in _config.extraEnv {e},
	]

	_volumeMounts: [
		{
			name:      "envoy-gateway-config"
			mountPath: "/config"
			readOnly:  true
		},
		{
			name:      "certs"
			mountPath: "/certs"
			readOnly:  true
		},
		// Writable cache for Wasm modules; required because the
		// controller's root filesystem is read-only.
		{
			name:      "wasm-cache"
			mountPath: "/var/lib/eg/wasm"
		},
		if _config.extraVolumeMounts != _|_ for m in _config.extraVolumeMounts {m},
	]
	_volumes: [
		{
			name: "envoy-gateway-config"
			configMap: name: _config._configMapName
		},
		{
			name: "certs"
			secret: secretName: "envoy-gateway"
		},
		{
			name: "wasm-cache"
			if _config.wasmCacheVolume != _|_ {_config.wasmCacheVolume}
			if _config.wasmCacheVolume == _|_ {emptyDir: {}}
		},
		if _config.extraVolumes != _|_ for v in _config.extraVolumes {v},
	]

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: {
		name:      _config.metadata.name
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.deploymentAnnotations != _|_ {
			annotations: _config.deploymentAnnotations
		}
	}
	spec: appsv1.#DeploymentSpec & {
		// The replica count is left to the autoscaler when enabled.
		if !_config.hpa.enabled {
			replicas: _config.replicas
		}
		if _config.strategy != _|_ {
			strategy: _config.strategy
		}
		if _config.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _config.revisionHistoryLimit
		}
		selector: matchLabels: _config.selector.labels
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: _config.selector.labels
				if _config.podLabels != _|_ {
					labels: _config.podLabels
				}
				annotations: "kubectl.kubernetes.io/default-container": "envoy-gateway"
				annotations: _config.podAnnotations
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: _config.serviceAccount.name
				// The controller needs API access; the token mount is
				// disabled on the ServiceAccount itself.
				automountServiceAccountToken:  true
				securityContext:               _config.podSecurityContext
				nodeSelector:                  _config.nodeSelector
				terminationGracePeriodSeconds: _config.terminationGracePeriodSeconds
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
				containers: [{
					name:            "envoy-gateway"
					image:           _config.image.reference
					imagePullPolicy: _config.image.pullPolicy
					args: [
						"server",
						"--config-path=/config/envoy-gateway.yaml",
					]
					env: _env
					ports: [
						{name: "grpc", containerPort: _config.ports.grpc, protocol: "TCP"},
						{name: "ratelimit", containerPort: _config.ports.ratelimit, protocol: "TCP"},
						{name: "wasm", containerPort: _config.ports.wasm, protocol: "TCP"},
						{name: "metrics", containerPort: _config.ports.metrics, protocol: "TCP"},
						if _config.topologyInjector.enabled {
							{name: "webhook", containerPort: 9443, protocol: "TCP"}
						},
					]
					startupProbe:    _config.startupProbe
					livenessProbe:   _config.livenessProbe
					readinessProbe:  _config.readinessProbe
					resources:       _config.resources
					securityContext: _config.securityContext
					volumeMounts:    _volumeMounts
				}]
				volumes: _volumes
			}
		}
	}
}
