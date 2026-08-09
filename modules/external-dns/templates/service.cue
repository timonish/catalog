package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   _config.metadata
	if _config.service.annotations != _|_ {
		metadata: annotations: _config.service.annotations
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		if _config.service.ipFamilies != _|_ {
			ipFamilies: _config.service.ipFamilies
		}
		if _config.service.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _config.service.ipFamilyPolicy
		}
		selector: _config.selector.labels
		ports: [
			{
				name:       "http"
				port:       _config.service.port
				targetPort: "http"
				protocol:   "TCP"
			},
			if _config.provider.name == "webhook" {
				{
					name:       "http-webhook"
					port:       _config.provider.webhook.service.port
					targetPort: "http-webhook"
					protocol:   "TCP"
				}
			},
		]
	}
}
