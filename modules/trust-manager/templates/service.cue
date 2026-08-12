package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// Service exposing the Prometheus metrics endpoint, selected by the
// ServiceMonitor through the component label.
#MetricsService: corev1.#Service & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "\(_config.metadata.name)-metrics"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		labels: "app.kubernetes.io/component": "metrics"
		if _config.metrics.service.labels != _|_ {
			labels: _config.metrics.service.labels
		}
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.metrics.service.annotations != _|_ {
			annotations: _config.metrics.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type: _config.metrics.service.type
		if _config.metrics.service.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _config.metrics.service.ipFamilyPolicy
		}
		if _config.metrics.service.ipFamilies != _|_ {
			ipFamilies: _config.metrics.service.ipFamilies
		}
		ports: [{
			name:       "metrics"
			protocol:   "TCP"
			port:       _config.metrics.port
			targetPort: "metrics"
		}]
		selector: _config.selector.labels
	}
}
