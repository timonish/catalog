package templates

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
)

#ServiceMonitor: promv1.#ServiceMonitor & {
	_config: #Config
	metadata: {
		name: _config.metadata.name
		namespace: [
			if _config.serviceMonitor.namespace != _|_ {_config.serviceMonitor.namespace},
			_config.metadata.namespace,
		][0]
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	if _config.serviceMonitor.additionalLabels != _|_ {
		metadata: labels: _config.serviceMonitor.additionalLabels
	}
	if _config.serviceMonitor.annotations != _|_ {
		metadata: annotations: _config.serviceMonitor.annotations
	}
	spec: {
		jobLabel: "app.kubernetes.io/name"
		namespaceSelector: matchNames: [_config.metadata.namespace]
		selector: matchLabels: _config.selector.labels
		endpoints: [
			{
				port: "http"
				path: "/metrics"
				if _config.serviceMonitor.interval != _|_ {
					interval: _config.serviceMonitor.interval
				}
				if _config.serviceMonitor.scheme != _|_ {
					scheme: _config.serviceMonitor.scheme
				}
				if _config.serviceMonitor.bearerTokenFile != _|_ {
					bearerTokenFile: _config.serviceMonitor.bearerTokenFile
				}
				if _config.serviceMonitor.tlsConfig != _|_ {
					tlsConfig: _config.serviceMonitor.tlsConfig
				}
				if _config.serviceMonitor.scrapeTimeout != _|_ {
					scrapeTimeout: _config.serviceMonitor.scrapeTimeout
				}
				if _config.serviceMonitor.metricRelabelings != _|_ {
					metricRelabelings: _config.serviceMonitor.metricRelabelings
				}
				if _config.serviceMonitor.relabelings != _|_ {
					relabelings: _config.serviceMonitor.relabelings
				}
			},
			if _config.provider.name == "webhook" {
				{
					_webhook: _config.provider.webhook.serviceMonitor
					port:     "http-webhook"
					path:     "/metrics"
					if _webhook.interval != _|_ {
						interval: _webhook.interval
					}
					if _webhook.scheme != _|_ {
						scheme: _webhook.scheme
					}
					if _webhook.bearerTokenFile != _|_ {
						bearerTokenFile: _webhook.bearerTokenFile
					}
					if _webhook.tlsConfig != _|_ {
						tlsConfig: _webhook.tlsConfig
					}
					if _webhook.scrapeTimeout != _|_ {
						scrapeTimeout: _webhook.scrapeTimeout
					}
					if _webhook.metricRelabelings != _|_ {
						metricRelabelings: _webhook.metricRelabelings
					}
					if _webhook.relabelings != _|_ {
						relabelings: _webhook.relabelings
					}
				}
			},
		]
		if _config.serviceMonitor.targetLabels != _|_ {
			targetLabels: _config.serviceMonitor.targetLabels
		}
	}
}
