package templates

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
)

// ServiceMonitor scraping the controller metrics port; requires the
// Prometheus Operator CRDs on the cluster. The controller also
// supports pushing metrics through `config.telemetry.metrics.sinks`.
#ServiceMonitor: promv1.#ServiceMonitor & {
	_config:  #Config
	metadata: _config.metadata
	if _config.serviceMonitor.additionalLabels != _|_ {
		metadata: labels: _config.serviceMonitor.additionalLabels
	}
	if _config.serviceMonitor.annotations != _|_ {
		metadata: annotations: _config.serviceMonitor.annotations
	}
	spec: {
		jobLabel: _config.serviceMonitor.jobLabel
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
		if _config.serviceMonitor.targetLabels != _|_ {
			targetLabels: _config.serviceMonitor.targetLabels
		}
		if _config.serviceMonitor.podTargetLabels != _|_ {
			podTargetLabels: _config.serviceMonitor.podTargetLabels
		}
		endpoints: [{
			port:        "metrics"
			path:        "/metrics"
			honorLabels: _config.serviceMonitor.honorLabels
			if _config.serviceMonitor.interval != "" {
				interval: _config.serviceMonitor.interval
			}
			if _config.serviceMonitor.scrapeTimeout != "" {
				scrapeTimeout: _config.serviceMonitor.scrapeTimeout
			}
			if _config.serviceMonitor.scheme != _|_ {
				scheme: _config.serviceMonitor.scheme
			}
			if _config.serviceMonitor.tlsConfig != _|_ {
				tlsConfig: _config.serviceMonitor.tlsConfig
			}
			if _config.serviceMonitor.bearerTokenFile != _|_ {
				bearerTokenFile: _config.serviceMonitor.bearerTokenFile
			}
			if _config.serviceMonitor.bearerTokenSecret != _|_ {
				bearerTokenSecret: _config.serviceMonitor.bearerTokenSecret
			}
			if _config.serviceMonitor.proxyUrl != _|_ {
				proxyUrl: _config.serviceMonitor.proxyUrl
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
