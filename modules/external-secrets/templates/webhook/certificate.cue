package webhook

import (
	certv1 "cert-manager.io/certificate/v1"
	issuerv1 "cert-manager.io/issuer/v1"
	"timoni.sh/external-secrets/templates/config"
)

_certMeta: {
	#config: config.#Config
	#ObjectMeta & {#config: #config}
	if #config.webhook.tls.certManager.annotations != _|_ {
		annotations: #config.webhook.tls.certManager.annotations
	}
	if #config.webhook.tls.certManager.labels != _|_ {
		labels: #config.webhook.tls.certManager.labels
	}
}

// Self-signed Issuer used when no existing issuer is configured.
#Issuer: issuerv1.#Issuer & {
	#config: config.#Config
	_config: #config

	apiVersion: "cert-manager.io/v1"
	kind:       "Issuer"
	metadata: _certMeta & {#config: _config}
	spec: selfSigned: {}
}

// The webhook serving Certificate issued by cert-manager.
#Certificate: certv1.#Certificate & {
	#config: config.#Config
	_config: #config
	_cm:     _config.webhook.tls.certManager
	_name:   "\(_config.metadata.name)-webhook"

	apiVersion: "cert-manager.io/v1"
	kind:       "Certificate"
	metadata: _certMeta & {#config: _config}
	spec: {
		commonName: _name
		dnsNames: [
			_name,
			"\(_name).\(_config.metadata.namespace)",
			"\(_name).\(_config.metadata.namespace).svc",
		]
		secretName: _config.webhook.tls.secretName
		duration:   _cm.duration
		if _cm.renewBefore != _|_ {
			renewBefore: _cm.renewBefore
		}
		if _cm.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _cm.revisionHistoryLimit
		}
		if _cm.privateKey != _|_ {
			privateKey: _cm.privateKey
		}
		if _cm.signatureAlgorithm != _|_ {
			signatureAlgorithm: _cm.signatureAlgorithm
		}
		issuerRef: {
			if _cm.existingIssuer.enabled {
				name:  _cm.existingIssuer.name
				kind:  _cm.existingIssuer.kind
				group: _cm.existingIssuer.group
			}
			if !_cm.existingIssuer.enabled {
				name:  _name
				kind:  "Issuer"
				group: "cert-manager.io"
			}
		}
	}
}
