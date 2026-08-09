package templates

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
)

#ServiceMonitor: promv1.#ServiceMonitor & {
	_config:  #Config
	metadata: _config.metadata
	if _config.serviceMonitor.additionalLabels != _|_ {
		metadata: labels: _config.serviceMonitor.additionalLabels
	}
	spec: {
		jobLabel: "app.kubernetes.io/name"
		namespaceSelector: matchNames: [_config.metadata.namespace]
		selector: matchLabels: _config.selector.labels
		endpoints: [{
			port:   "https"
			path:   "/metrics"
			scheme: "https"
			tlsConfig: insecureSkipVerify: true
			interval:      _config.serviceMonitor.interval
			scrapeTimeout: _config.serviceMonitor.scrapeTimeout
			if _config.serviceMonitor.metricRelabelings != _|_ {
				metricRelabelings: _config.serviceMonitor.metricRelabelings
			}
			if _config.serviceMonitor.relabelings != _|_ {
				relabelings: _config.serviceMonitor.relabelings
			}
		}]
	}
}
