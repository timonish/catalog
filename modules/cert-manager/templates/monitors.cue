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

#ServiceMonitor: promv1.#ServiceMonitor & {
	#config: config.#Config
	_config: #config
	let cfg = _config
	_monitor: _config.serviceMonitor

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: _monitorMeta & {#config: cfg, #monitor: _monitor}
	spec: timoniv1.#MonitorSpec & {#Values: _monitor}
	spec: {
		selector: _monitorSelector & {#config: cfg}
		namespaceSelector: matchNames: [cfg.metadata.namespace]
		endpoints: [
			timoniv1.#MonitorEndpointSpec & {
				#Values:    _monitor
				targetPort: "http-metrics"
				path:       "/metrics"
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
	spec: timoniv1.#MonitorSpec & {#Values: _monitor}
	spec: {
		selector: _monitorSelector & {#config: cfg}
		namespaceSelector: matchNames: [cfg.metadata.namespace]
		podMetricsEndpoints: [
			timoniv1.#MonitorEndpointSpec & {
				#Values: _monitor
				port:    "http-metrics"
				path:    "/metrics"
			},
		]
	}
}
