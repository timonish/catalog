package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#ServiceAccount: corev1.#ServiceAccount & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: {
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.serviceAccount.annotations != _|_ {
			annotations: _config.serviceAccount.annotations
		}
	}
	if _config.serviceAccount.imagePullSecrets != _|_ {
		imagePullSecrets: _config.serviceAccount.imagePullSecrets
	}
	automountServiceAccountToken: _config.serviceAccount.automountServiceAccountToken
}
