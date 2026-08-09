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
		if _config.tls.certManager.annotations != _|_ {
			annotations: _config.tls.certManager.annotations
		}
		if _config.tls.certManager.labels != _|_ {
			labels: _config.tls.certManager.labels
		}
	}
	spec: selfSigned: {}
}

// Certificate for serving the metrics API over TLS.
#Certificate: certv1.#Certificate & {
	_config: #Config
	metadata: {
		name:      _config.metadata.name
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.tls.certManager.annotations != _|_ {
			annotations: _config.tls.certManager.annotations
		}
		if _config.tls.certManager.labels != _|_ {
			labels: _config.tls.certManager.labels
		}
	}
	spec: {
		commonName: _config.metadata.name
		dnsNames: [
			"\(_config.metadata.name).\(_config.metadata.namespace)",
			"\(_config.metadata.name).\(_config.metadata.namespace).svc",
			"\(_config.metadata.name).\(_config.metadata.namespace).svc.\(_config.tls.clusterDomain)",
		]
		secretName: _config.metadata.name
		usages: ["server auth", "client auth"]
		privateKey: {
			algorithm: "RSA"
			size:      2048
		}
		if _config.tls.certManager.duration != _|_ {
			duration: _config.tls.certManager.duration
		}
		if _config.tls.certManager.renewBefore != _|_ {
			renewBefore: _config.tls.certManager.renewBefore
		}
		issuerRef: {
			group: "cert-manager.io"
			if _config.tls.certManager.existingIssuer.enabled {
				name: _config.tls.certManager.existingIssuer.name
				kind: _config.tls.certManager.existingIssuer.kind
			}
			if !_config.tls.certManager.existingIssuer.enabled {
				name: "\(_config.metadata.name)-issuer"
				kind: "Issuer"
			}
		}
	}
}
