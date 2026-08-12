package templates

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
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

	spec: timoniv1.#MonitorSpec & {#Values: _config.serviceMonitor}
	spec: {
		if _config.serviceMonitor.namespaceSelector != _|_ {
			namespaceSelector: matchNames: _config.serviceMonitor.namespaceSelector
		}
		if _config.serviceMonitor.selectorOverride != _|_ {
			selector: matchLabels: _config.serviceMonitor.selectorOverride
		}
		if _config.serviceMonitor.selectorOverride == _|_ {
			selector: matchLabels: _config.selector.labels
		}
		endpoints: [for e in _endpoints {
			timoniv1.#MonitorEndpointSpec & {
				#Values: e.cfg
				port:    e.name
			}
		}]
	}
}
