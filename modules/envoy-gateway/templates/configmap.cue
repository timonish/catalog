package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// EnvoyGatewayConfigMap holds the EnvoyGateway configuration file. The
// object name carries the hash of the data (computed in #Config) and
// the ConfigMap is immutable, so configuration changes create a new
// object and roll the controller pods referencing it.
#EnvoyGatewayConfigMap: corev1.#ConfigMap & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      _config._configMapName
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	immutable: true
	data:      _config._configData
}
