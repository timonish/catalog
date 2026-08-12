package admission

import (
	promv1 "monitoring.coreos.com/servicemonitor/v1"
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
		endpoints: [{
			port:        "metrics"
			path:        "/metrics"
			honorLabels: _sm.honorLabels
			if _sm.interval != "" {
				interval: _sm.interval
			}
			if _sm.scrapeTimeout != "" {
				scrapeTimeout: _sm.scrapeTimeout
			}
			if _sm.scheme != _|_ {
				scheme: _sm.scheme
			}
			if _sm.tlsConfig != _|_ {
				tlsConfig: _sm.tlsConfig
			}
			if _sm.bearerTokenFile != _|_ {
				bearerTokenFile: _sm.bearerTokenFile
			}
			if _sm.bearerTokenSecret != _|_ {
				bearerTokenSecret: _sm.bearerTokenSecret
			}
			if _sm.proxyUrl != _|_ {
				proxyUrl: _sm.proxyUrl
			}
			if _sm.metricRelabelings != _|_ {
				metricRelabelings: _sm.metricRelabelings
			}
			if _sm.relabelings != _|_ {
				relabelings: _sm.relabelings
			}
		}]
	}
}
