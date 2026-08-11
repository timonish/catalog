package recommender

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
	metadata: name:      _config.recommender.serviceAccount.name
	metadata: namespace: _config.metadata.namespace
	if _config.recommender.serviceAccount.labels != _|_ {
		metadata: labels: _config.recommender.serviceAccount.labels
	}
	if _config.recommender.serviceAccount.annotations != _|_ {
		metadata: annotations: _config.recommender.serviceAccount.annotations
	}
	automountServiceAccountToken: _config.recommender.serviceAccount.automountServiceAccountToken
	if _config.imagePullSecrets != _|_ {
		imagePullSecrets: _config.imagePullSecrets
	}
}
