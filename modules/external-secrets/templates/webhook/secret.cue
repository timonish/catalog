package webhook

import (
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/external-secrets/templates/config"
)

// The serving certificate Secret, created empty and populated by the
// cert-controller. The component label lets the cert-controller cache
// it with `enablePartialCache`.
#Secret: corev1.#Secret & {
	#config: config.#Config
	_config: #config

	apiVersion: "v1"
	kind:       "Secret"
	metadata: #ClusterObjectMeta & {#config: _config}
	metadata: {
		name:      _config.webhook.tls.secretName
		namespace: _config.metadata.namespace
		labels: "external-secrets.io/component": "webhook"
	}
}
