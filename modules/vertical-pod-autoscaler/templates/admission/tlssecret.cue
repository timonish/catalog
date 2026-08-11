package admission

import (
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

// The serving certificate Secret rendered from the PEM-encoded
// `tls.caCert`, `tls.cert` and `tls.key` values.
#TLSSecret: corev1.#Secret & {
	#config: config.#Config
	_config: #config
	_tls:    _config.admissionController.tls

	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      _tls.secretName
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		labels: (timoniv1.#StdLabelComponent): _component
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	type: "Opaque"
	stringData: {
		ca:   _tls.caCert
		cert: _tls.cert
		key:  _tls.key
	}
}
