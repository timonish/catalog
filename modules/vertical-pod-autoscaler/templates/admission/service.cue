package admission

import (
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

// The metrics Service scraped through the ServiceMonitor.
#MetricsService: corev1.#Service & {
	#config: config.#Config
	_config: #config

	apiVersion: "v1"
	kind:       "Service"
	metadata: #ObjectMeta & {#config: _config}
	if _config.admissionController.metricsService.labels != _|_ {
		metadata: labels: _config.admissionController.metricsService.labels
	}
	if _config.admissionController.metricsService.annotations != _|_ {
		metadata: annotations: _config.admissionController.metricsService.annotations
	}
	spec: corev1.#ServiceSpec & {
		if _config.admissionController.metricsService.ipFamilies != _|_ {
			ipFamilies: _config.admissionController.metricsService.ipFamilies
		}
		if _config.admissionController.metricsService.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _config.admissionController.metricsService.ipFamilyPolicy
		}
		selector: #SelectorLabels & {#config: _config}
		ports: [{
			name:       "metrics"
			port:       #MetricsPort
			protocol:   "TCP"
			targetPort: "prometheus"
		}]
	}
}
