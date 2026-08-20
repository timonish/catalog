package webhook

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
		name:      _config.webhook.serviceAccount.name
		namespace: _config.metadata.namespace
	}
	if _config.webhook.serviceAccount.labels != _|_ {
		metadata: labels: _config.webhook.serviceAccount.labels
	}
	if _config.webhook.serviceAccount.annotations != _|_ {
		metadata: annotations: _config.webhook.serviceAccount.annotations
	}
	automountServiceAccountToken: _config.webhook.serviceAccount.automountServiceAccountToken
	if _config.imagePullSecrets != _|_ {
		imagePullSecrets: _config.imagePullSecrets
	}
}
