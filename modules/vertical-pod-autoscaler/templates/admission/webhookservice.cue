package admission

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

// The Service the API server reaches the mutating webhook through; its
// name is passed to the admission controller with `--webhook-service`.
#WebhookService: corev1.#Service & {
	#config: config.#Config
	_config: #config
	_ac:     _config.admissionController

	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      _ac.service.name
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		labels: (timoniv1.#StdLabelComponent): _component
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _ac.service.annotations != _|_ {
			annotations: _ac.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:  "ClusterIP"
		ports: _ac.service.ports
		selector: #SelectorLabels & {#config: _config}
	}
}
