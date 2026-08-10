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

	name: #config.metadata.name
	namespace: [
		if #monitor.namespace != _|_ {#monitor.namespace},
		#config.metadata.namespace,
	][0]
	labels: #config.metadata.labels
	labels: prometheus: #monitor.prometheusInstance
	if #monitor.labels != _|_ {
		labels: #monitor.labels
	}
	if #config.metadata.annotations != _|_ {
		annotations: #config.metadata.annotations
	}
	if #monitor.annotations != _|_ {
		annotations: #monitor.annotations
	}
}

#ServiceMonitor: promv1.#ServiceMonitor & {
	#config: config.#Config
	_config: #config
	let cfg = _config
	_monitor: _config.prometheus.serviceMonitor

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: _monitorMeta & {#config: cfg, #monitor: _monitor}
	spec: {
		jobLabel: timoniv1.#StdLabelName
		selector: _monitorSelector & {#config: cfg}
		if _monitor.namespace != _|_ {
			namespaceSelector: matchNames: [cfg.metadata.namespace]
		}
		_extra: {...}
		if _monitor.endpointAdditionalProperties != _|_ {
			_extra: _monitor.endpointAdditionalProperties
		}
		endpoints: [{
			targetPort:    "http-metrics"
			path:          "/metrics"
			interval:      _monitor.interval
			scrapeTimeout: _monitor.scrapeTimeout
			honorLabels:   _monitor.honorLabels
		} & _extra]
	}
}

#PodMonitor: prompodv1.#PodMonitor & {
	#config: config.#Config
	_config: #config
	let cfg = _config
	_monitor: _config.prometheus.podMonitor

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "PodMonitor"
	metadata: _monitorMeta & {#config: cfg, #monitor: _monitor}
	spec: {
		jobLabel: timoniv1.#StdLabelName
		selector: _monitorSelector & {#config: cfg}
		if _monitor.namespace != _|_ {
			namespaceSelector: matchNames: [cfg.metadata.namespace]
		}
		_extra: {...}
		if _monitor.endpointAdditionalProperties != _|_ {
			_extra: _monitor.endpointAdditionalProperties
		}
		podMetricsEndpoints: [{
			port:          "http-metrics"
			path:          "/metrics"
			interval:      _monitor.interval
			scrapeTimeout: _monitor.scrapeTimeout
			honorLabels:   _monitor.honorLabels
		} & _extra]
	}
}
