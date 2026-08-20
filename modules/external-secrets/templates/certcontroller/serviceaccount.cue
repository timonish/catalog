package certcontroller

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
		name:      _config.certController.serviceAccount.name
		namespace: _config.metadata.namespace
	}
	if _config.certController.serviceAccount.labels != _|_ {
		metadata: labels: _config.certController.serviceAccount.labels
	}
	if _config.certController.serviceAccount.annotations != _|_ {
		metadata: annotations: _config.certController.serviceAccount.annotations
	}
	automountServiceAccountToken: _config.certController.serviceAccount.automountServiceAccountToken
	if _config.imagePullSecrets != _|_ {
		imagePullSecrets: _config.imagePullSecrets
	}
}
