package webhook

import (
	admissionv1 "k8s.io/api/admissionregistration/v1"
	"timoni.sh/cert-manager/templates/config"
)

// The namespace/name of the CA Secret the cainjector reads the serving
// CA from, referenced by the webhook configurations. With dynamic
// serving it is the generated CA Secret; with filesystem serving the
// user provisions a Secret at the default location.
#CASecretRef: {
	#config: config.#Config
	ref:     string
	if #config.webhook.config.tlsConfig.dynamic != _|_ {
		ref: "\(#config.webhook.config.tlsConfig.dynamic.secretNamespace)/\(#config.webhook.config.tlsConfig.dynamic.secretName)"
	}
	if #config.webhook.config.tlsConfig.dynamic == _|_ {
		ref: "\(#config.metadata.namespace)/\(#config.metadata.name)-webhook-ca"
	}
}

_clientConfig: {
	#config: config.#Config
	#path:   string
	out: {
		if #config.webhook.url.host != _|_ {
			url: "https://\(#config.webhook.url.host)\(#path)"
		}
		if #config.webhook.url.host == _|_ {
			service: {
				name:      "\(#config.metadata.name)-\(_component)"
				namespace: #config.metadata.namespace
				path:      #path
			}
		}
	}
}

#ValidatingWebhookConfiguration: admissionv1.#ValidatingWebhookConfiguration & {
	#config: config.#Config
	_config: #config

	_annotations: {
		"cert-manager.io/inject-ca-from-secret": (#CASecretRef & {#config: _config}).ref
		if _config.webhook.validatingWebhookConfiguration.annotations != _|_ {
			_config.webhook.validatingWebhookConfiguration.annotations
		}
	}

	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "ValidatingWebhookConfiguration"
	metadata: #ClusterObjectMeta & {#config: _config}
	metadata: annotations: _annotations
	webhooks: [{
		name:              "webhook.cert-manager.io"
		namespaceSelector: _config.webhook.validatingWebhookConfiguration.namespaceSelector
		rules: [{
			apiGroups: ["cert-manager.io", "acme.cert-manager.io"]
			apiVersions: ["v1"]
			operations: ["CREATE", "UPDATE"]
			resources: ["*/*"]
		}]
		admissionReviewVersions: ["v1"]
		// Non-v1 requests are converted to v1 before reaching the
		// webhook.
		matchPolicy:    "Equivalent"
		timeoutSeconds: _config.webhook.timeoutSeconds
		failurePolicy:  "Fail"
		sideEffects:    "None"
		clientConfig: (_clientConfig & {#config: _config, #path: "/validate"}).out
	}]
}

#MutatingWebhookConfiguration: admissionv1.#MutatingWebhookConfiguration & {
	#config: config.#Config
	_config: #config

	_annotations: {
		"cert-manager.io/inject-ca-from-secret": (#CASecretRef & {#config: _config}).ref
		if _config.webhook.mutatingWebhookConfiguration.annotations != _|_ {
			_config.webhook.mutatingWebhookConfiguration.annotations
		}
	}

	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "MutatingWebhookConfiguration"
	metadata: #ClusterObjectMeta & {#config: _config}
	metadata: annotations: _annotations
	webhooks: [{
		name: "webhook.cert-manager.io"
		if _config.webhook.mutatingWebhookConfiguration.namespaceSelector != _|_ {
			namespaceSelector: _config.webhook.mutatingWebhookConfiguration.namespaceSelector
		}
		rules: [{
			apiGroups: ["cert-manager.io"]
			apiVersions: ["v1"]
			operations: ["CREATE"]
			resources: ["certificaterequests"]
		}]
		admissionReviewVersions: ["v1"]
		matchPolicy:    "Equivalent"
		timeoutSeconds: _config.webhook.timeoutSeconds
		failurePolicy:  "Fail"
		sideEffects:    "None"
		clientConfig: (_clientConfig & {#config: _config, #path: "/mutate"}).out
	}]
}
