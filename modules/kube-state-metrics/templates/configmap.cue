package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// CustomResourceStateConfigMap holds the Custom Resource State
// configuration. The object name carries the hash of the data (computed
// in #Config) and the ConfigMap is immutable, so config changes create
// a new object and roll the pods referencing it.
#CustomResourceStateConfigMap: corev1.#ConfigMap & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      _config._crsConfigMapName
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	immutable: true
	data:      _config._crsData
}
