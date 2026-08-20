package webhook

import (
	"encoding/base64"

	admissionv1 "k8s.io/api/admissionregistration/v1"
	"timoni.sh/external-secrets/templates/config"
)

// The metadata of the validating webhook configurations: the chart's
// fixed names, the cert-manager CA injection annotation in
// cert-manager mode and the user annotations.
_webhookConfigMeta: {
	#config: config.#Config
	#name:   string
	#ClusterObjectMeta & {#config: #config}
	name: #name
	labels: "external-secrets.io/component": "webhook"
	if #config.webhook.tls.type == "cert-manager" && #config.webhook.tls.certManager.addInjectorAnnotations {
		annotations: "cert-manager.io/inject-ca-from": "\(#config.metadata.namespace)/\(#config.metadata.name)-webhook"
	}
	if #config.webhook.annotations != _|_ {
		annotations: #config.webhook.annotations
	}
}

// One validating webhook entry; the CA bundle is set from the
// user-provided certificate in existingSecret mode and injected by the
// cert-controller or cert-manager otherwise.
_webhook: {
	#config:   config.#Config
	#resource: string
	#scope:    "Namespaced" | "Cluster"
	out: {
		name: "validate.\(#resource).external-secrets.io"
		rules: [{
			apiGroups: ["external-secrets.io"]
			apiVersions: ["v1"]
			operations: ["CREATE", "UPDATE", "DELETE"]
			resources: ["\(#resource)s"]
			scope: #scope
		}]
		clientConfig: {
			service: {
				name:      "\(#config.metadata.name)-webhook"
				namespace: #config.metadata.namespace
				path:      "/validate-external-secrets-io-v1-\(#resource)"
				port:      #config.webhook.service.port
			}
			if #config.webhook.tls.type == "existingSecret" {
				caBundle: '\(base64.Encode(null, #config.webhook.tls.caBundle))'
			}
		}
		admissionReviewVersions: ["v1", "v1beta1"]
		sideEffects:    "None"
		timeoutSeconds: #config.webhook.timeoutSeconds
		failurePolicy:  #config.webhook.failurePolicy
	}
}

#SecretStoreWebhookConfiguration: admissionv1.#ValidatingWebhookConfiguration & {
	#config: config.#Config
	_config: #config

	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "ValidatingWebhookConfiguration"
	metadata: _webhookConfigMeta & {#config: _config, #name: "secretstore-validate"}
	webhooks: [
		(_webhook & {#config: _config, #resource: "secretstore", #scope: "Namespaced"}).out,
		(_webhook & {#config: _config, #resource: "clustersecretstore", #scope: "Cluster"}).out,
	]
}

#ExternalSecretWebhookConfiguration: admissionv1.#ValidatingWebhookConfiguration & {
	#config: config.#Config
	_config: #config

	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "ValidatingWebhookConfiguration"
	metadata: _webhookConfigMeta & {#config: _config, #name: "externalsecret-validate"}
	webhooks: [
		(_webhook & {#config: _config, #resource: "externalsecret", #scope: "Namespaced"}).out,
	]
}
