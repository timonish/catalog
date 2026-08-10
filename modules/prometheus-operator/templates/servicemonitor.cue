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
		if _config.serviceMonitor.sampleLimit != _|_ {
			sampleLimit: _config.serviceMonitor.sampleLimit
		}
		if _config.serviceMonitor.targetLimit != _|_ {
			targetLimit: _config.serviceMonitor.targetLimit
		}
		if _config.serviceMonitor.labelLimit != _|_ {
			labelLimit: _config.serviceMonitor.labelLimit
		}
		if _config.serviceMonitor.labelNameLengthLimit != _|_ {
			labelNameLengthLimit: _config.serviceMonitor.labelNameLengthLimit
		}
		if _config.serviceMonitor.labelValueLengthLimit != _|_ {
			labelValueLengthLimit: _config.serviceMonitor.labelValueLengthLimit
		}
		endpoints: [{
			port: _config._servingPortName
			path: "/metrics"
			// With the webhook enabled the operator serves everything,
			// metrics included, over TLS.
			if _config.webhook.enabled {
				scheme: "https"
				tlsConfig: insecureSkipVerify: true
			}
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
		}]
	}
}
