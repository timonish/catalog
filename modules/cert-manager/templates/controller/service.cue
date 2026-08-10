package controller

import (
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/cert-manager/templates/config"
)

// The controller metrics Service, created when `prometheus.enabled` is
// set and the PodMonitor is not used.
#Service: corev1.#Service & {
	#config: config.#Config
	_config: #config

	apiVersion: "v1"
	kind:       "Service"
	metadata: #ObjectMeta & {#config: _config}
	if _config.controller.service.annotations != _|_ {
		metadata: annotations: _config.controller.service.annotations
	}
	if _config.controller.service.labels != _|_ {
		metadata: labels: _config.controller.service.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		if _config.controller.service.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _config.controller.service.ipFamilyPolicy
		}
		if _config.controller.service.ipFamilies != _|_ {
			ipFamilies: _config.controller.service.ipFamilies
		}
		selector: #SelectorLabels & {#config: _config}
		ports: [{
			name:       "http-metrics"
			protocol:   "TCP"
			port:       9402
			targetPort: "http-metrics"
		}]
	}
}
