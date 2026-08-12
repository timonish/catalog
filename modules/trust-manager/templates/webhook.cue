package templates

import (
	admissionv1 "k8s.io/api/admissionregistration/v1"
	corev1 "k8s.io/api/core/v1"
)

// Service exposing the webhook to the API server.
#WebhookService: corev1.#Service & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   _config.metadata
	if _config.webhook.service.labels != _|_ {
		metadata: labels: _config.webhook.service.labels
	}
	if _config.webhook.service.annotations != _|_ {
		metadata: annotations: _config.webhook.service.annotations
	}
	spec: corev1.#ServiceSpec & {
		type: _config.webhook.service.type
		if _config.webhook.service.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _config.webhook.service.ipFamilyPolicy
		}
		if _config.webhook.service.ipFamilies != _|_ {
			ipFamilies: _config.webhook.service.ipFamilies
		}
		ports: [{
			name:       "webhook"
			protocol:   "TCP"
			port:       443
			targetPort: "webhook"
			if _config.webhook.service.type == "NodePort" {
				if _config.webhook.service.nodePort > 0 {
					nodePort: _config.webhook.service.nodePort
				}
			}
		}]
		selector: _config.selector.labels
	}
}

// The webhook rejecting invalid Bundles at admission. The CA of the
// serving certificate is injected by the cert-manager cainjector from
// the Certificate this module creates.
#ValidatingWebhookConfiguration: admissionv1.#ValidatingWebhookConfiguration & {
	_config:    #Config
	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "ValidatingWebhookConfiguration"
	metadata: {
		name:   _config.metadata.name
		labels: _config.metadata.labels
		annotations: "cert-manager.io/inject-ca-from": "\(_config.metadata.namespace)/\(_config.metadata.name)"
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	webhooks: [{
		name: "trust.cert-manager.io"
		rules: [{
			apiGroups: ["trust.cert-manager.io"]
			apiVersions: ["v1alpha1"]
			operations: ["CREATE", "UPDATE"]
			resources: ["bundles"]
		}]
		admissionReviewVersions: ["v1"]
		timeoutSeconds: _config.webhook.timeoutSeconds
		failurePolicy:  "Fail"
		sideEffects:    "None"
		clientConfig: service: {
			name:      _config.metadata.name
			namespace: _config.metadata.namespace
			path:      "/validate-trust-cert-manager-io-v1alpha1-bundle"
		}
	}]
}
