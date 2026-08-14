package templates

import (
	promv1 "monitoring.coreos.com/podmonitor/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

#PodMonitor: promv1.#PodMonitor & {
	_config:  #Config
	metadata: _config.metadata
	if _config.podMonitor.additionalLabels != _|_ {
		metadata: labels: _config.podMonitor.additionalLabels
	}
	if _config.podMonitor.annotations != _|_ {
		metadata: annotations: _config.podMonitor.annotations
	}

	spec: timoniv1.#MonitorSpec & {#Values: _config.podMonitor}
	spec: {
		if _config.podMonitor.selectorOverride != _|_ {
			selector: matchLabels: _config.podMonitor.selectorOverride
		}
		if _config.podMonitor.selectorOverride == _|_ {
			selector: matchLabels: _config.selector.labels
		}
		namespaceSelector: matchNames: [_config.metadata.namespace]
		if _config.podMonitor.attachMetadata != _|_ {
			attachMetadata: _config.podMonitor.attachMetadata
		}
		podMetricsEndpoints: [
			timoniv1.#MonitorEndpointSpec & {#Values: _config.podMonitor} & {
				port:            _config.service.portName
				path:            _config.podMonitor.path
				honorTimestamps: _config.podMonitor.honorTimestamps
				filterRunning:   _config.podMonitor.filterRunning
				followRedirects: _config.podMonitor.followRedirects
				if _config.podMonitor.basicAuth != _|_ {
					basicAuth: _config.podMonitor.basicAuth
				}
				if _config.podMonitor.params != _|_ {
					params: _config.podMonitor.params
				}
				if _config.podMonitor.oauth2 != _|_ {
					oauth2: _config.podMonitor.oauth2
				}
				if _config.podMonitor.authorization != _|_ {
					authorization: _config.podMonitor.authorization
				}
			},
		]
	}
}
