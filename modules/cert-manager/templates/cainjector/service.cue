package cainjector

import (
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/cert-manager/templates/config"
)

// The cainjector metrics Service, created when `prometheus.enabled` is
// set and the PodMonitor is not used.
#Service: corev1.#Service & {
	#config: config.#Config
	_config: #config

	apiVersion: "v1"
	kind:       "Service"
	metadata: #ObjectMeta & {#config: _config}
	if _config.cainjector.service.annotations != _|_ {
		metadata: annotations: _config.cainjector.service.annotations
	}
	if _config.cainjector.service.labels != _|_ {
		metadata: labels: _config.cainjector.service.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		selector: #SelectorLabels & {#config: _config}
		ports: [{
			name:       "http-metrics"
			protocol:   "TCP"
			port:       9402
			targetPort: "http-metrics"
		}]
	}
}
