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
	if _config.serviceMonitor.annotations != _|_ {
		metadata: annotations: _config.serviceMonitor.annotations
	}

	_endpoints: [
		{name: "http", cfg: _config.serviceMonitor.http},
		if _config.selfMonitor.enabled {
			{name: "metrics", cfg: _config.serviceMonitor.metrics}
		},
	]

	spec: {
		jobLabel: _config.serviceMonitor.jobLabel
		if _config.serviceMonitor.targetLabels != _|_ {
			targetLabels: _config.serviceMonitor.targetLabels
		}
		if _config.serviceMonitor.podTargetLabels != _|_ {
			podTargetLabels: _config.serviceMonitor.podTargetLabels
		}
		if _config.serviceMonitor.namespaceSelector != _|_ {
			namespaceSelector: matchNames: _config.serviceMonitor.namespaceSelector
		}
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
		if _config.serviceMonitor.selectorOverride != _|_ {
			selector: matchLabels: _config.serviceMonitor.selectorOverride
		}
		if _config.serviceMonitor.selectorOverride == _|_ {
			selector: matchLabels: _config.selector.labels
		}
		endpoints: [for e in _endpoints {
			{
				port:        e.name
				honorLabels: e.cfg.honorLabels
				enableHttp2: e.cfg.enableHttp2
				if e.cfg.interval != "" {
					interval: e.cfg.interval
				}
				if e.cfg.scrapeTimeout != "" {
					scrapeTimeout: e.cfg.scrapeTimeout
				}
				if e.cfg.proxyUrl != _|_ {
					proxyUrl: e.cfg.proxyUrl
				}
				if e.cfg.scheme != _|_ {
					scheme: e.cfg.scheme
				}
				if e.cfg.bearerTokenFile != _|_ {
					bearerTokenFile: e.cfg.bearerTokenFile
				}
				if e.cfg.bearerTokenSecret != _|_ {
					bearerTokenSecret: e.cfg.bearerTokenSecret
				}
				if e.cfg.tlsConfig != _|_ {
					tlsConfig: e.cfg.tlsConfig
				}
				if e.cfg.metricRelabelings != _|_ {
					metricRelabelings: e.cfg.metricRelabelings
				}
				if e.cfg.relabelings != _|_ {
					relabelings: e.cfg.relabelings
				}
			}
		}]
	}
}
