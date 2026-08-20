package controller

import (
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/external-secrets/templates/config"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config: config.#Config
	_config: #config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: #ClusterObjectMeta & {#config: _config}
	metadata: {
		name:      _config.controller.serviceAccount.name
		namespace: _config.metadata.namespace
	}
	if _config.controller.serviceAccount.labels != _|_ {
		metadata: labels: _config.controller.serviceAccount.labels
	}
	if _config.controller.serviceAccount.annotations != _|_ {
		metadata: annotations: _config.controller.serviceAccount.annotations
	}
	automountServiceAccountToken: _config.controller.serviceAccount.automountServiceAccountToken
	if _config.imagePullSecrets != _|_ {
		imagePullSecrets: _config.imagePullSecrets
	}
}
