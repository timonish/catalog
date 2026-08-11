package recommender

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

#ServiceMonitor: promv1.#ServiceMonitor & {
	#config: config.#Config
	_config: #config
	_sm:     _config.serviceMonitor

	metadata: #ObjectMeta & {#config: _config}
	if _sm.labels != _|_ {
		metadata: labels: _sm.labels
	}
	if _sm.annotations != _|_ {
		metadata: annotations: _sm.annotations
	}
	spec: {
		jobLabel: "app.kubernetes.io/component"
		namespaceSelector: matchNames: [_config.metadata.namespace]
		selector: matchLabels: #SelectorLabels & {#config: _config}
		endpoints: [{
			port:          "metrics"
			path:          "/metrics"
			interval:      _sm.interval
			scrapeTimeout: _sm.scrapeTimeout
			if _sm.endpointAdditionalProperties != _|_ {
				_sm.endpointAdditionalProperties
			}
		}]
	}
}
