package templates

import (
	"encoding/base64"

	admissionv1 "k8s.io/api/admissionregistration/v1"
)

// The namespace scope of the admission webhooks: an explicit selector
// wins, otherwise it is derived from the operator watch scope so that
// objects in unwatched namespaces are not blocked by the webhook.
_webhookNamespaceSelector: {
	_config: #Config
	out: [
		if _config.webhook.namespaceSelector != _|_ {_config.webhook.namespaceSelector},
		if len(_config.namespaces) > 0 {
			{
				matchExpressions: [{
					key:      "kubernetes.io/metadata.name"
					operator: "In"
					values:   _config.namespaces
				}]
			}
		},
		if len(_config.denyNamespaces) > 0 {
			{
				matchExpressions: [{
					key:      "kubernetes.io/metadata.name"
					operator: "NotIn"
					values:   _config.denyNamespaces
				}]
			}
		},
		{},
	][0]
}

#ValidatingWebhookConfiguration: admissionv1.#ValidatingWebhookConfiguration & {
	_config:    #Config
	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "ValidatingWebhookConfiguration"
	metadata: {
		name:   "\(_config.metadata.name)-validation"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.webhook.tls.type == "cert-manager" {
			annotations: "cert-manager.io/inject-ca-from": "\(_config.metadata.namespace)/\(_config.metadata.name)-webhook-tls"
		}
	}

	_namespaceSelector: (_webhookNamespaceSelector & {"_config": _config}).out

	webhooks: [
		{
			name: "prometheusrulevalidate.monitoring.coreos.com"
			rules: [{
				apiGroups: ["monitoring.coreos.com"]
				apiVersions: ["*"]
				operations: ["CREATE", "UPDATE"]
				resources: ["prometheusrules"]
			}]
			clientConfig: {
				service: {
					name:      _config.metadata.name
					namespace: _config.metadata.namespace
					path:      "/admission-prometheusrules/validate"
					port:      _config.service.httpsPort
				}
				if _config.webhook.tls.type == "existingSecret" {
					caBundle: '\(base64.Encode(null, _config.webhook.tls.caBundle))'
				}
			}
			failurePolicy:  _config.webhook.failurePolicy
			timeoutSeconds: _config.webhook.timeoutSeconds
			sideEffects:    "None"
			admissionReviewVersions: ["v1"]
			namespaceSelector: _namespaceSelector
			if _config.webhook.objectSelector != _|_ {
				objectSelector: _config.webhook.objectSelector
			}

			// matchConditions requires Kubernetes 1.28 or newer.
			if _config.webhook.matchConditions != _|_ &&
				(_config.clusterVersion.major > 1 || _config.clusterVersion.minor >= 28) {
				matchConditions: _config.webhook.matchConditions
			}
		},
		{
			name: "alertmanagerconfigsvalidate.monitoring.coreos.com"
			rules: [{
				apiGroups: ["monitoring.coreos.com"]
				// The operator validates only the v1alpha1 payloads; the
				// v1beta1 admission is handled through conversion.
				apiVersions: ["v1alpha1"]
				operations: ["CREATE", "UPDATE"]
				resources: ["alertmanagerconfigs"]
			}]
			clientConfig: {
				service: {
					name:      _config.metadata.name
					namespace: _config.metadata.namespace
					path:      "/admission-alertmanagerconfigs/validate"
					port:      _config.service.httpsPort
				}
				if _config.webhook.tls.type == "existingSecret" {
					caBundle: '\(base64.Encode(null, _config.webhook.tls.caBundle))'
				}
			}
			failurePolicy:  _config.webhook.failurePolicy
			timeoutSeconds: _config.webhook.timeoutSeconds
			sideEffects:    "None"
			admissionReviewVersions: ["v1"]
			namespaceSelector: _namespaceSelector
			if _config.webhook.objectSelector != _|_ {
				objectSelector: _config.webhook.objectSelector
			}

			// matchConditions requires Kubernetes 1.28 or newer.
			if _config.webhook.matchConditions != _|_ &&
				(_config.clusterVersion.major > 1 || _config.clusterVersion.minor >= 28) {
				matchConditions: _config.webhook.matchConditions
			}
		},
	]
}

#MutatingWebhookConfiguration: admissionv1.#MutatingWebhookConfiguration & {
	_config:    #Config
	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "MutatingWebhookConfiguration"
	metadata: {
		name:   "\(_config.metadata.name)-mutation"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.webhook.tls.type == "cert-manager" {
			annotations: "cert-manager.io/inject-ca-from": "\(_config.metadata.namespace)/\(_config.metadata.name)-webhook-tls"
		}
	}

	_namespaceSelector: (_webhookNamespaceSelector & {"_config": _config}).out

	webhooks: [{
		// Normalizes the PrometheusRule rule data to strings.
		name: "prometheusrulemutate.monitoring.coreos.com"
		rules: [{
			apiGroups: ["monitoring.coreos.com"]
			apiVersions: ["*"]
			operations: ["CREATE", "UPDATE"]
			resources: ["prometheusrules"]
		}]
		clientConfig: {
			service: {
				name:      _config.metadata.name
				namespace: _config.metadata.namespace
				path:      "/admission-prometheusrules/mutate"
				port:      _config.service.httpsPort
			}
			if _config.webhook.tls.type == "existingSecret" {
				caBundle: '\(base64.Encode(null, _config.webhook.tls.caBundle))'
			}
		}
		failurePolicy:  _config.webhook.failurePolicy
		timeoutSeconds: _config.webhook.timeoutSeconds
		sideEffects:    "None"
		admissionReviewVersions: ["v1"]
		namespaceSelector: _namespaceSelector
		if _config.webhook.objectSelector != _|_ {
			objectSelector: _config.webhook.objectSelector
		}

		// matchConditions requires Kubernetes 1.28 or newer.
		if _config.webhook.matchConditions != _|_ &&
			(_config.clusterVersion.major > 1 || _config.clusterVersion.minor >= 28) {
			matchConditions: _config.webhook.matchConditions
		}
	}]
}
