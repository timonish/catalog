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
	spec: corev1.#ServiceSpec & {
		selector: #SelectorLabels & {#config: _config}
		ports: [{
			name:       "metrics"
			port:       #MetricsPort
			protocol:   "TCP"
			targetPort: "prometheus"
		}]
	}
}
