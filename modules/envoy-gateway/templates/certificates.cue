package templates

import (
	certv1 "cert-manager.io/certificate/v1"
	issuerv1 "cert-manager.io/issuer/v1"
)

// Self-signed Issuer bootstrapping the control plane CA when no
// existing issuer is configured.
#SelfSignedIssuer: issuerv1.#Issuer & {
	_config:    #Config
	apiVersion: "cert-manager.io/v1"
	kind:       "Issuer"
	metadata: _certMeta & {_c: _config, _name: "\(_config.metadata.name)-selfsigned"}
	spec: selfSigned: {}
}

// The control plane CA certificate, mirroring the CA the certgen
// command would generate.
#CACertificate: certv1.#Certificate & {
	_config:    #Config
	apiVersion: "cert-manager.io/v1"
	kind:       "Certificate"
	metadata: _certMeta & {_c: _config, _name: _config._caSecretName}
	spec: {
		isCA: true
		// The CA common name must differ from the leaf certificates'
		// (`envoy-gateway`): an identical subject and issuer DN makes
		// the leaves look self-signed and fails the mTLS verification.
		commonName: "envoy-gateway-ca"
		secretName: _config._caSecretName
		privateKey: {
			algorithm: "RSA"
			size:      2048
		}
		if _config.tls.certManager.caDuration != _|_ {
			duration: _config.tls.certManager.caDuration
		}
		issuerRef: {
			group: "cert-manager.io"
			if _config.tls.certManager.existingIssuer.enabled {
				name: _config.tls.certManager.existingIssuer.name
				kind: _config.tls.certManager.existingIssuer.kind
			}
			if !_config.tls.certManager.existingIssuer.enabled {
				name: "\(_config.metadata.name)-selfsigned"
				kind: "Issuer"
			}
		}
	}
}

// CA Issuer signing the control plane leaf certificates.
#CAIssuer: issuerv1.#Issuer & {
	_config:    #Config
	apiVersion: "cert-manager.io/v1"
	kind:       "Issuer"
	metadata: _certMeta & {_c: _config, _name: "\(_config.metadata.name)-ca"}
	spec: ca: secretName: _config._caSecretName
}

// A control plane leaf certificate. The secret names and shapes
// (kubernetes.io/tls with ca.crt) match what the envoy-gateway binary
// looks up: `envoy-gateway` serves the xDS server and the topology
// injector webhook, `envoy` and `envoy-rate-limit` authenticate the
// data plane clients.
#ControlPlaneCertificate: certv1.#Certificate & {
	_config:    #Config
	_certName:  string
	apiVersion: "cert-manager.io/v1"
	kind:       "Certificate"
	metadata: _certMeta & {_c: _config, _name: "\(_config.metadata.name)-\(_certName)"}
	spec: {
		secretName: _certName
		if _certName == "envoy-gateway" {
			commonName: "envoy-gateway"
			dnsNames: [
				"envoy-gateway",
				"envoy-gateway.\(_config.metadata.namespace)",
				"envoy-gateway.\(_config.metadata.namespace).svc",
				"envoy-gateway.\(_config.metadata.namespace).svc.\(_config.kubernetesClusterDomain)",
			]
		}
		if _certName != "envoy-gateway" {
			commonName: "envoy"
			dnsNames: ["*.\(_config.metadata.namespace)"]
		}
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
			name:  "\(_config.metadata.name)-ca"
			kind:  "Issuer"
		}
	}
}

// Metadata shared by the cert-manager objects.
_certMeta: {
	_c:        #Config
	_name:     string
	name:      _name
	namespace: _c.metadata.namespace
	labels:    _c.metadata.labels
	if _c.metadata.annotations != _|_ {
		annotations: _c.metadata.annotations
	}
	if _c.tls.certManager.annotations != _|_ {
		annotations: _c.tls.certManager.annotations
	}
	if _c.tls.certManager.labels != _|_ {
		labels: _c.tls.certManager.labels
	}
}
