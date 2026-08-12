package updater

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

#ServiceMonitor: promv1.#ServiceMonitor & {
	#config: config.#Config
	_config: #config
	_sm:     _config.serviceMonitor

	metadata: #ObjectMeta & {#config: _config}
	if _sm.additionalLabels != _|_ {
		metadata: labels: _sm.additionalLabels
	}
	if _sm.annotations != _|_ {
		metadata: annotations: _sm.annotations
	}
	spec: {
		jobLabel: _sm.jobLabel
		namespaceSelector: matchNames: [_config.metadata.namespace]
		selector: matchLabels: #SelectorLabels & {#config: _config}
		if _sm.sampleLimit != _|_ {
			sampleLimit: _sm.sampleLimit
		}
		if _sm.targetLimit != _|_ {
			targetLimit: _sm.targetLimit
		}
		if _sm.labelLimit != _|_ {
			labelLimit: _sm.labelLimit
		}
		if _sm.labelNameLengthLimit != _|_ {
			labelNameLengthLimit: _sm.labelNameLengthLimit
		}
		if _sm.labelValueLengthLimit != _|_ {
			labelValueLengthLimit: _sm.labelValueLengthLimit
		}
		if _sm.targetLabels != _|_ {
			targetLabels: _sm.targetLabels
		}
		if _sm.podTargetLabels != _|_ {
			podTargetLabels: _sm.podTargetLabels
		}
		endpoints: [
			timoniv1.#MonitorEndpointSpec & {
				#Values: _sm
				port:    "metrics"
				path:    "/metrics"
			},
		]
	}
}
