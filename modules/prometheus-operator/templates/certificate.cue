package templates

import (
	certv1 "cert-manager.io/certificate/v1"
	issuerv1 "cert-manager.io/issuer/v1"
)

// Self-signed Issuer used when no existing issuer is configured.
#Issuer: issuerv1.#Issuer & {
	_config: #Config
	metadata: {
		name:      "\(_config.metadata.name)-issuer"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.webhook.tls.certManager.annotations != _|_ {
			annotations: _config.webhook.tls.certManager.annotations
		}
		if _config.webhook.tls.certManager.labels != _|_ {
			labels: _config.webhook.tls.certManager.labels
		}
	}
	spec: selfSigned: {}
}

// Certificate for serving the operator web server and admission
// webhook over TLS. cert-manager's cainjector picks the CA up from
// here for the webhook configurations.
#Certificate: certv1.#Certificate & {
	_config: #Config
	metadata: {
		name:      "\(_config.metadata.name)-webhook-tls"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.webhook.tls.certManager.annotations != _|_ {
			annotations: _config.webhook.tls.certManager.annotations
		}
		if _config.webhook.tls.certManager.labels != _|_ {
			labels: _config.webhook.tls.certManager.labels
		}
	}
	spec: {
		commonName: _config.metadata.name
		dnsNames: [
			"\(_config.metadata.name).\(_config.metadata.namespace)",
			"\(_config.metadata.name).\(_config.metadata.namespace).svc",
			if _config.clusterDomain != "" {
				"\(_config.metadata.name).\(_config.metadata.namespace).svc.\(_config.clusterDomain)"
			},
		]
		secretName: "\(_config.metadata.name)-webhook-tls"
		usages: ["server auth"]
		privateKey: {
			algorithm: "RSA"
			size:      2048
		}
		if _config.webhook.tls.certManager.duration != _|_ {
			duration: _config.webhook.tls.certManager.duration
		}
		if _config.webhook.tls.certManager.renewBefore != _|_ {
			renewBefore: _config.webhook.tls.certManager.renewBefore
		}
		issuerRef: {
			group: "cert-manager.io"
			if _config.webhook.tls.certManager.existingIssuer.enabled {
				name: _config.webhook.tls.certManager.existingIssuer.name
				kind: _config.webhook.tls.certManager.existingIssuer.kind
			}
			if !_config.webhook.tls.certManager.existingIssuer.enabled {
				name: "\(_config.metadata.name)-issuer"
				kind: "Issuer"
			}
		}
	}
}
