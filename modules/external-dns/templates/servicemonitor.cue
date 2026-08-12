package templates

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
)

// The canonical scrape endpoint fields shared by the external-dns and
// provider-webhook endpoints; the values are validated as
// #ScrapeEndpoint by the config schema.
_endpoint: {
	#ep: {...}

	path:        "/metrics"
	honorLabels: #ep.honorLabels
	if #ep.interval != "" {
		interval: #ep.interval
	}
	if #ep.scrapeTimeout != "" {
		scrapeTimeout: #ep.scrapeTimeout
	}
	if #ep.scheme != _|_ {
		scheme: #ep.scheme
	}
	if #ep.tlsConfig != _|_ {
		tlsConfig: #ep.tlsConfig
	}
	if #ep.bearerTokenFile != _|_ {
		bearerTokenFile: #ep.bearerTokenFile
	}
	if #ep.bearerTokenSecret != _|_ {
		bearerTokenSecret: #ep.bearerTokenSecret
	}
	if #ep.proxyUrl != _|_ {
		proxyUrl: #ep.proxyUrl
	}
	if #ep.metricRelabelings != _|_ {
		metricRelabelings: #ep.metricRelabelings
	}
	if #ep.relabelings != _|_ {
		relabelings: #ep.relabelings
	}
}

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
		endpoints: [
			_endpoint & {
				#ep:  _config.serviceMonitor
				port: "http"
			},
			if _config.provider.name == "webhook" {
				_endpoint & {
					#ep:  _config.provider.webhook.serviceMonitor
					port: "http-webhook"
				}
			},
		]
	}
}
