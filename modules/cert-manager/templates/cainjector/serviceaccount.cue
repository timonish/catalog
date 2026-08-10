package cainjector

import (
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/cert-manager/templates/config"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config: config.#Config
	_config: #config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: #ObjectMeta & {#config: _config}
	metadata: name: _config.cainjector.serviceAccount.name
	if _config.cainjector.serviceAccount.labels != _|_ {
		metadata: labels: _config.cainjector.serviceAccount.labels
	}
	if _config.cainjector.serviceAccount.annotations != _|_ {
		metadata: annotations: _config.cainjector.serviceAccount.annotations
	}
	automountServiceAccountToken: _config.cainjector.serviceAccount.automountServiceAccountToken
	if _config.imagePullSecrets != _|_ {
		imagePullSecrets: _config.imagePullSecrets
	}
}
