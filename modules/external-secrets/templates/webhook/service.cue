package webhook

import (
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/external-secrets/templates/config"
)

// The webhook Service serving the admission endpoint, and the metrics
// endpoint when `webhook.metrics.service.enabled` or the ServiceMonitor
// is set.
#Service: corev1.#Service & {
	#config: config.#Config
	_config: #config
	_svc:    _config.webhook.service

	apiVersion: "v1"
	kind:       "Service"
	metadata: #ObjectMeta & {#config: _config}
	if _svc.annotations != _|_ {
		metadata: annotations: _svc.annotations
	}
	if _svc.labels != _|_ {
		metadata: labels: _svc.labels
	}
	if (#MetricsExposed & {#config: _config}).exposed {
		if _config.webhook.metrics.service.annotations != _|_ {
			metadata: annotations: _config.webhook.metrics.service.annotations
		}
		if _config.webhook.metrics.service.labels != _|_ {
			metadata: labels: _config.webhook.metrics.service.labels
		}
	}
	spec: corev1.#ServiceSpec & {
		type: _svc.type
		if _svc.clusterIP != _|_ {
			clusterIP: _svc.clusterIP
		}
		if _svc.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _svc.ipFamilyPolicy
		}
		if _svc.ipFamilies != _|_ {
			ipFamilies: _svc.ipFamilies
		}
		if _svc.loadBalancerIP != _|_ {
			loadBalancerIP: _svc.loadBalancerIP
		}
		if _svc.loadBalancerClass != _|_ {
			loadBalancerClass: _svc.loadBalancerClass
		}
		if _svc.loadBalancerSourceRanges != _|_ {
			loadBalancerSourceRanges: _svc.loadBalancerSourceRanges
		}
		if _svc.externalTrafficPolicy != _|_ {
			externalTrafficPolicy: _svc.externalTrafficPolicy
		}
		selector: #SelectorLabels & {#config: _config}
		ports: [
			{
				name:       "webhook"
				protocol:   "TCP"
				port:       _svc.port
				targetPort: "webhook"
				if _svc.type == "NodePort" {
					if _svc.nodePort > 0 {
						nodePort: _svc.nodePort
					}
				}
			},
			if (#MetricsExposed & {#config: _config}).exposed {
				{
					name:       "metrics"
					protocol:   "TCP"
					port:       _config.webhook.metrics.service.port
					targetPort: "metrics"
				}
			},
		]
	}
}
