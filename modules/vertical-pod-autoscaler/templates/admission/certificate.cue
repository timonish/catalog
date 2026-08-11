package admission

import (
	certv1 "cert-manager.io/certificate/v1"
	issuerv1 "cert-manager.io/issuer/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

// The cert-manager resources managing the webhook serving certificate:
// an optional self-signed issuer chain (SelfSigned Issuer -> CA
// Certificate -> CA Issuer) and the serving Certificate written to the
// Secret mounted by the admission controller.
#CertManagerObjects: {
	#config: config.#Config
	_config: #config
	_cm:     _config.admissionController.certManager
	_name:   _config.metadata.name

	_metadata: {
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		labels: "app.kubernetes.io/component": _component
		annotations?: {[string]: string}
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _cm.annotations != _|_ {
			annotations: _cm.annotations
		}
	}

	_privateKey: {
		algorithm: _cm.privateKey.algorithm
		if _cm.privateKey.algorithm != "Ed25519" {
			size: _cm.privateKey.size
		}
	}

	objects: {
		if _cm.createSelfSignedIssuer.enabled {
			// Bootstraps the chain by signing the CA certificate.
			"admission-issuer-selfsigned": issuerv1.#Issuer & {
				metadata: _metadata
				metadata: name: "\(_name)-selfsigned"
				spec: selfSigned: {}
			}

			// The intermediate CA signing the serving certificate.
			"admission-cert-ca": certv1.#Certificate & {
				metadata: _metadata
				metadata: name: "\(_name)-webhook-ca"
				spec: {
					isCA:       true
					secretName: "\(_name)-webhook-ca"
					commonName: "\(_name)-webhook-ca"
					privateKey: _privateKey
					issuerRef: {
						name:  "\(_name)-selfsigned"
						kind:  "Issuer"
						group: "cert-manager.io"
					}
					duration:    _cm.createSelfSignedIssuer.duration
					renewBefore: _cm.createSelfSignedIssuer.renewBefore
				}
			}

			"admission-issuer-ca": issuerv1.#Issuer & {
				metadata: _metadata
				metadata: name: "\(_name)-ca"
				spec: ca: secretName: "\(_name)-webhook-ca"
			}
		}

		// The serving certificate; its name is referenced by the
		// cainjector annotation on the webhook configuration.
		"admission-cert": certv1.#Certificate & {
			metadata: _metadata
			metadata: name: "\(_name)-webhook-cert"
			spec: {
				secretName: _config.admissionController.tls.secretName
				dnsNames: [
					_config.admissionController.service.name,
					"\(_config.admissionController.service.name).\(_config.metadata.namespace)",
					"\(_config.admissionController.service.name).\(_config.metadata.namespace).svc",
					"\(_config.admissionController.service.name).\(_config.metadata.namespace).svc.cluster.local",
				]
				privateKey: _privateKey
				usages: ["digital signature", "key encipherment", "server auth"]
				issuerRef: {
					if _cm.createSelfSignedIssuer.enabled {
						name:  "\(_name)-ca"
						kind:  "Issuer"
						group: "cert-manager.io"
					}
					if !_cm.createSelfSignedIssuer.enabled {
						name:  _cm.issuerRef.name
						kind:  _cm.issuerRef.kind
						group: _cm.issuerRef.group
					}
				}
				duration:    _cm.duration
				renewBefore: _cm.renewBefore
			}
		}
	}
}
