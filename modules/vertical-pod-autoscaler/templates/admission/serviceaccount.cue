package admission

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
	metadata: name:      _config.admissionController.serviceAccount.name
	metadata: namespace: _config.metadata.namespace
	if _config.admissionController.serviceAccount.labels != _|_ {
		metadata: labels: _config.admissionController.serviceAccount.labels
	}
	if _config.admissionController.serviceAccount.annotations != _|_ {
		metadata: annotations: _config.admissionController.serviceAccount.annotations
	}
	automountServiceAccountToken: _config.admissionController.serviceAccount.automountServiceAccountToken
	if _config.imagePullSecrets != _|_ {
		imagePullSecrets: _config.imagePullSecrets
	}
}
