package templates

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/external-secrets/templates/config"
)

// One monitor scrapes the metrics of all deployed components through
// their Services, selected by the shared name label and the
// per-component labels.
#ServiceMonitor: promv1.#ServiceMonitor & {
	#config: config.#Config
	_config: #config
	let cfg = _config
	_monitor: _config.serviceMonitor

	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      cfg.metadata.name
		namespace: cfg.metadata.namespace
		labels:    cfg.metadata.labels
		if _monitor.additionalLabels != _|_ {
			labels: _monitor.additionalLabels
		}
		if cfg.metadata.annotations != _|_ {
			annotations: cfg.metadata.annotations
		}
		if _monitor.annotations != _|_ {
			annotations: _monitor.annotations
		}
	}
	spec: timoniv1.#MonitorSpec & {#Values: _monitor}
	spec: {
		selector: {
			matchLabels: (timoniv1.#StdLabelName): cfg.metadata.name
			matchExpressions: [{
				key:      timoniv1.#StdLabelComponent
				operator: "In"
				values: ["controller", "webhook", "cert-controller"]
			}]
		}
		namespaceSelector: matchNames: [cfg.metadata.namespace]
		endpoints: [
			timoniv1.#MonitorEndpointSpec & {
				#Values: _monitor
				port:    "metrics"
				path:    "/metrics"
			},
		]
	}
}
