package templates

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
)

#ServiceMonitor: promv1.#ServiceMonitor & {
	_config:  #Config
	metadata: _config.metadata
	metadata: labels: prometheus: _config.serviceMonitor.prometheusInstance
	if _config.serviceMonitor.additionalLabels != _|_ {
		metadata: labels: _config.serviceMonitor.additionalLabels
	}
	spec: {
		jobLabel: "app.kubernetes.io/name"
		namespaceSelector: matchNames: [_config.metadata.namespace]
		// Match the metrics Service only, not the webhook Service.
		selector: matchLabels: _config.selector.labels
		selector: matchLabels: "app.kubernetes.io/component": "metrics"
		endpoints: [{
			port: "metrics"
			path: "/metrics"
			if _config.serviceMonitor.interval != "" {
				interval: _config.serviceMonitor.interval
			}
			if _config.serviceMonitor.scrapeTimeout != "" {
				scrapeTimeout: _config.serviceMonitor.scrapeTimeout
			}
			if _config.serviceMonitor.metricRelabelings != _|_ {
				metricRelabelings: _config.serviceMonitor.metricRelabelings
			}
			if _config.serviceMonitor.relabelings != _|_ {
				relabelings: _config.serviceMonitor.relabelings
			}
			if _config.serviceMonitor.endpointAdditionalProperties != _|_ {
				_config.serviceMonitor.endpointAdditionalProperties
			}
		}]
	}
}
