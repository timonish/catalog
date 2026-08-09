package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   _config.metadata
	if _config.service.labels != _|_ {
		metadata: labels: _config.service.labels
	}
	if _config.service.annotations != _|_ {
		metadata: annotations: _config.service.annotations
	}
	spec: corev1.#ServiceSpec & {
		type: _config.service.type
		ports: [{
			name:        "https"
			port:        _config.service.port
			protocol:    "TCP"
			targetPort:  "https"
			appProtocol: "https"
		}]
		selector: _config.selector.labels
	}
}
