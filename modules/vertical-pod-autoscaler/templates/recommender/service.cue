package recommender

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
	if _config.recommender.metricsService.labels != _|_ {
		metadata: labels: _config.recommender.metricsService.labels
	}
	if _config.recommender.metricsService.annotations != _|_ {
		metadata: annotations: _config.recommender.metricsService.annotations
	}
	spec: corev1.#ServiceSpec & {
		if _config.recommender.metricsService.ipFamilies != _|_ {
			ipFamilies: _config.recommender.metricsService.ipFamilies
		}
		if _config.recommender.metricsService.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _config.recommender.metricsService.ipFamilyPolicy
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
