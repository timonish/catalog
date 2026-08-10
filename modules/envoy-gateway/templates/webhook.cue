package templates

import (
	admissionv1 "k8s.io/api/admissionregistration/v1"
)

// The topology injector webhook labels the Envoy fleet pods with
// their node's topology zone at binding time, enabling topology-aware
// routing. The configuration name is fixed: the certgen Job patches
// the CA bundle into it by that name. In cert-manager TLS mode the CA
// bundle is injected by cert-manager instead.
#MutatingWebhookConfiguration: admissionv1.#MutatingWebhookConfiguration & {
	_config:    #Config
	apiVersion: "admissionregistration.k8s.io/v1"
	kind:       "MutatingWebhookConfiguration"
	metadata: {
		name:   _config._webhookName
		labels: _config.metadata.labels
		labels: "app.kubernetes.io/component": "topology-injector"
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.topologyInjector.annotations != _|_ {
			annotations: _config.topologyInjector.annotations
		}
		if _config.tls.mode == "cert-manager" {
			annotations: "cert-manager.io/inject-ca-from": "\(_config.metadata.namespace)/\(_config.metadata.name)-envoy-gateway"
		}
	}
	webhooks: [{
		name: "topology.webhook.gateway.envoyproxy.io"
		admissionReviewVersions: ["v1"]
		sideEffects: "None"
		clientConfig: service: {
			name:      _config._serviceName
			namespace: _config.metadata.namespace
			path:      "/inject-pod-topology"
			port:      9443
		}
		// The webhook is an optimization: pod binding proceeds when it
		// is unreachable.
		failurePolicy: "Ignore"
		rules: [{
			operations: ["CREATE"]
			apiGroups: [""]
			apiVersions: ["v1"]
			resources: ["pods/binding"]
		}]
		// Scope the webhook to the namespaces running Envoy fleet pods:
		// the controller namespace by default, the watched namespaces
		// in GatewayNamespace deploy mode, or all namespaces when that
		// mode selects them by label.
		if !_config._gatewayNamespaceMode {
			namespaceSelector: matchExpressions: [{
				key:      "kubernetes.io/metadata.name"
				operator: "In"
				values: [_config.metadata.namespace]
			}]
		}
		if _config._gatewayNamespaceMode if len(_config._watchNamespaces) > 0 {
			namespaceSelector: matchExpressions: [{
				key:      "kubernetes.io/metadata.name"
				operator: "In"
				values:   _config._watchNamespaces
			}]
		}
	}]
}
