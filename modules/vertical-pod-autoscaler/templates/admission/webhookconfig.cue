package admission

import (
	"encoding/base64"

	admissionv1 "k8s.io/api/admissionregistration/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

// The mutating webhook applying the recommended resources to pod
// creation requests. In certManager mode the cainjector patches the
// CA bundle; in tls.create mode the provided CA certificate is the
// bundle; in registerWebhook mode the admission controller manages
// the configuration itself and this object is not rendered.
#MutatingWebhookConfiguration: admissionv1.#MutatingWebhookConfiguration & {
	#config: config.#Config
	_config: #config
	_ac:     _config.admissionController
	_mwc:    _ac.mutatingWebhookConfiguration

	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "MutatingWebhookConfiguration"
	metadata: #ClusterObjectMeta & {#config: _config}
	metadata: name: "\(_config.metadata.name)-webhook-config"
	if _ac.certManager.enabled {
		metadata: annotations: "cert-manager.io/inject-ca-from": "\(_config.metadata.namespace)/\(_config.metadata.name)-webhook-cert"
	}
	if _mwc.annotations != _|_ {
		metadata: annotations: _mwc.annotations
	}
	webhooks: [{
		name: "vpa.k8s.io"
		admissionReviewVersions: ["v1"]
		clientConfig: {
			service: {
				name:      _ac.service.name
				namespace: _config.metadata.namespace
				port:      _ac.service.ports[0].port
			}
			// The API expects the base64 text in the serialized field;
			// the schema types it as bytes, so the encoded form is
			// wrapped as a bytes literal.
			if !_ac.certManager.enabled && _ac.tls.create {
				caBundle: '\(base64.Encode(null, _ac.tls.caCert))'
			}
		}
		failurePolicy: _mwc.failurePolicy
		matchPolicy:   "Equivalent"
		if _mwc.namespaceSelector != _|_ {
			namespaceSelector: _mwc.namespaceSelector
		}
		if _mwc.objectSelector != _|_ {
			objectSelector: _mwc.objectSelector
		}
		reinvocationPolicy: "Never"
		rules: [
			{
				apiGroups: [""]
				apiVersions: ["v1"]
				operations: ["CREATE"]
				resources: ["pods"]
				scope: "*"
			},
			{
				apiGroups: ["autoscaling.k8s.io"]
				apiVersions: ["*"]
				operations: ["CREATE", "UPDATE"]
				resources: ["verticalpodautoscalers"]
				scope: "*"
			},
		]
		sideEffects:    "None"
		timeoutSeconds: _mwc.timeoutSeconds
	}]
}
