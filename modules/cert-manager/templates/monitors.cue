package templates

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
	prompodv1 "monitoring.coreos.com/podmonitor/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/cert-manager/templates/config"
)

// One monitor scrapes the metrics of all three components, selected by
// the shared name label and the per-component labels.
_monitorSelector: {
	#config: config.#Config
	matchLabels: (timoniv1.#StdLabelName): #config.metadata.name
	matchExpressions: [{
		key:      timoniv1.#StdLabelComponent
		operator: "In"
		values: ["cainjector", "controller", "webhook"]
	}]
}

_monitorMeta: {
	#config:  config.#Config
	#monitor: _

	name:      #config.metadata.name
	namespace: #config.metadata.namespace
	labels:    #config.metadata.labels
	if #monitor.additionalLabels != _|_ {
		labels: #monitor.additionalLabels
	}
	if #config.metadata.annotations != _|_ {
		annotations: #config.metadata.annotations
	}
	if #monitor.annotations != _|_ {
		annotations: #monitor.annotations
	}
}

// The canonical scrape endpoint fields shared by both monitors.
_monitorEndpoint: {
	#monitor: _

	path:        "/metrics"
	honorLabels: #monitor.honorLabels
	if #monitor.interval != "" {
		interval: #monitor.interval
	}
	if #monitor.scrapeTimeout != "" {
		scrapeTimeout: #monitor.scrapeTimeout
	}
	if #monitor.scheme != _|_ {
		scheme: #monitor.scheme
	}
	if #monitor.tlsConfig != _|_ {
		tlsConfig: #monitor.tlsConfig
	}
	if #monitor.bearerTokenFile != _|_ {
		bearerTokenFile: #monitor.bearerTokenFile
	}
	if #monitor.bearerTokenSecret != _|_ {
		bearerTokenSecret: #monitor.bearerTokenSecret
	}
	if #monitor.proxyUrl != _|_ {
		proxyUrl: #monitor.proxyUrl
	}
	if #monitor.metricRelabelings != _|_ {
		metricRelabelings: #monitor.metricRelabelings
	}
	if #monitor.relabelings != _|_ {
		relabelings: #monitor.relabelings
	}
}

_monitorLimits: {
	#monitor: _

	if #monitor.sampleLimit != _|_ {
		sampleLimit: #monitor.sampleLimit
	}
	if #monitor.targetLimit != _|_ {
		targetLimit: #monitor.targetLimit
	}
	if #monitor.labelLimit != _|_ {
		labelLimit: #monitor.labelLimit
	}
	if #monitor.labelNameLengthLimit != _|_ {
		labelNameLengthLimit: #monitor.labelNameLengthLimit
	}
	if #monitor.labelValueLengthLimit != _|_ {
		labelValueLengthLimit: #monitor.labelValueLengthLimit
	}
}

#ServiceMonitor: promv1.#ServiceMonitor & {
	#config: config.#Config
	_config: #config
	let cfg = _config
	_monitor: _config.serviceMonitor

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: _monitorMeta & {#config: cfg, #monitor: _monitor}
	spec: {
		jobLabel: _monitor.jobLabel
		selector: _monitorSelector & {#config: cfg}
		namespaceSelector: matchNames: [cfg.metadata.namespace]
		_monitorLimits & {#monitor: _monitor}
		if _monitor.targetLabels != _|_ {
			targetLabels: _monitor.targetLabels
		}
		if _monitor.podTargetLabels != _|_ {
			podTargetLabels: _monitor.podTargetLabels
		}
		endpoints: [
			_monitorEndpoint & {
				#monitor:   _monitor
				targetPort: "http-metrics"
			},
		]
	}
}

#PodMonitor: prompodv1.#PodMonitor & {
	#config: config.#Config
	_config: #config
	let cfg = _config
	_monitor: _config.podMonitor

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PodMonitor"
	metadata: _monitorMeta & {#config: cfg, #monitor: _monitor}
	spec: {
		jobLabel: _monitor.jobLabel
		selector: _monitorSelector & {#config: cfg}
		namespaceSelector: matchNames: [cfg.metadata.namespace]
		_monitorLimits & {#monitor: _monitor}
		if _monitor.podTargetLabels != _|_ {
			podTargetLabels: _monitor.podTargetLabels
		}
		podMetricsEndpoints: [
			_monitorEndpoint & {
				#monitor: _monitor
				port:     "http-metrics"
			},
		]
	}
}
