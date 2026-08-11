package templates

import (
	certv1 "cert-manager.io/certificate/v1"
	issuerv1 "cert-manager.io/issuer/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

// Self-signed Issuer dedicated to the webhook certificate.
#Issuer: issuerv1.#Issuer & {
	_config: #Config
	metadata: {
		name:      "\(_config.metadata.name)-issuer"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	spec: selfSigned: {}
}

// Certificate for serving the webhook over TLS. The name is referenced
// by the cainjector annotation on the webhook configuration.
#Certificate: certv1.#Certificate & {
	_config: #Config
	metadata: {
		name:      _config.metadata.name
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	spec: {
		commonName: "\(_config.metadata.name).\(_config.metadata.namespace).svc"
		dnsNames: ["\(_config.metadata.name).\(_config.metadata.namespace).svc"]
		secretName: "\(_config.metadata.name)-tls"
		_template:  _config.webhook.tls.certificate.secretTemplate
		if _template.annotations != _|_ || _template.labels != _|_ {
			secretTemplate: {
				if _template.annotations != _|_ {
					annotations: _template.annotations
				}
				if _template.labels != _|_ {
					labels: _template.labels
				}
			}
		}
		privateKey: rotationPolicy: "Always"
		revisionHistoryLimit: 1
		if _config.webhook.tls.certificate.duration != _|_ {
			duration: _config.webhook.tls.certificate.duration
		}
		issuerRef: {
			name:  "\(_config.metadata.name)-issuer"
			kind:  "Issuer"
			group: "cert-manager.io"
		}
	}
}

// Minimal schema of the approver-policy CertificateRequestPolicy,
// covering only the fields this module renders; the
// policy.cert-manager.io group has no vendored schema in the catalog.
#CertificateRequestPolicy: {
	_config:    #Config
	apiVersion: "policy.cert-manager.io/v1alpha1"
	kind:       "CertificateRequestPolicy"
	metadata: {
		name:   "\(_config.metadata.name)-policy"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	spec: {
		_svcName: "\(_config.metadata.name).\(_config.metadata.namespace).svc"
		allowed: {
			commonName: {
				value:    _svcName
				required: true
			}
			dnsNames: {
				values: [_svcName]
				required: true
			}
		}
		selector: issuerRef: {
			name:  "\(_config.metadata.name)-issuer"
			kind:  "Issuer"
			group: "cert-manager.io"
		}
	}
}

// ClusterRole and binding granting cert-manager use of the
// CertificateRequestPolicy, so the webhook certificate requests are
// auto-approved.
#PolicyClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-policy-role"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		apiGroups: ["policy.cert-manager.io"]
		resources: ["certificaterequestpolicies"]
		verbs: ["use"]
		resourceNames: ["\(_config.metadata.name)-policy"]
	}]
}

#PolicyClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   "\(_config.metadata.name)-policy-binding"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "\(_config.metadata.name)-policy-role"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.webhook.tls.approverPolicy.certManagerServiceAccount
		namespace: _config.webhook.tls.approverPolicy.certManagerNamespace
	}]
}
