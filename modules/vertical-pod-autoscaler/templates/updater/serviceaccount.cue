package updater

import (
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

#ServiceAccount: corev1.#ServiceAccount & {
	#config: config.#Config
	_config: #config

	apiVersion: "v1"
	kind:       "ServiceAccount"
	metadata: #ClusterObjectMeta & {#config: _config}
	metadata: name:      _config.updater.serviceAccount.name
	metadata: namespace: _config.metadata.namespace
	if _config.updater.serviceAccount.labels != _|_ {
		metadata: labels: _config.updater.serviceAccount.labels
	}
	if _config.updater.serviceAccount.annotations != _|_ {
		metadata: annotations: _config.updater.serviceAccount.annotations
	}
	automountServiceAccountToken: _config.updater.serviceAccount.automountServiceAccountToken
	if _config.imagePullSecrets != _|_ {
		imagePullSecrets: _config.imagePullSecrets
	}
}
