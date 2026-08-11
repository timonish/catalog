package webhook

import (
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/cert-manager/templates/config"
)

// The webhook Service serving the admission endpoints (and the metrics
// endpoint when `prometheus.enabled` is set and the PodMonitor is not
// used).
#Service: corev1.#Service & {
	#config: config.#Config
	_config: #config

	apiVersion: "v1"
	kind:       "Service"
	metadata: #ObjectMeta & {#config: _config}
	if _config.webhook.service.annotations != _|_ {
		metadata: annotations: _config.webhook.service.annotations
	}
	if _config.webhook.service.labels != _|_ {
		metadata: labels: _config.webhook.service.labels
	}
	spec: corev1.#ServiceSpec & {
		type: _config.webhook.service.type
		if _config.webhook.service.loadBalancerIP != _|_ {
			loadBalancerIP: _config.webhook.service.loadBalancerIP
		}
		if _config.webhook.service.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _config.webhook.service.ipFamilyPolicy
		}
		if _config.webhook.service.ipFamilies != _|_ {
			ipFamilies: _config.webhook.service.ipFamilies
		}
		selector: #SelectorLabels & {#config: _config}
		ports: [
			{
				name:       "https"
				protocol:   "TCP"
				port:       443
				targetPort: "https"
			},
			if _config.prometheus.enabled && !_config.podMonitor.enabled {
				{
					name:       "metrics"
					protocol:   "TCP"
					port:       9402
					targetPort: "http-metrics"
				}
			},
		]
	}
}
