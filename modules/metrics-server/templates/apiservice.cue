package templates

import (
	"encoding/base64"
)

// The v1beta1.metrics.k8s.io APIService registration.
// Note that the apiregistration.k8s.io schema is not part of the
// vendored Kubernetes APIs, the relevant fields are typed inline.
#APIService: {
	_config:    #Config
	apiVersion: "apiregistration.k8s.io/v1"
	kind:       "APIService"
	metadata: {
		name:   "v1beta1.metrics.k8s.io"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.tls.type == "cert-manager" && _config.tls.certManager.addInjectorAnnotations {
			annotations: "cert-manager.io/inject-ca-from": "\(_config.metadata.namespace)/\(_config.metadata.name)"
		}
		if _config.apiService.annotations != _|_ {
			annotations: _config.apiService.annotations
		}
	}
	spec: {
		group:                 "metrics.k8s.io"
		version:               "v1beta1"
		groupPriorityMinimum:  100
		versionPriority:       100
		insecureSkipTLSVerify: _config.apiService.insecureSkipTLSVerify
		service: {
			name:      _config.metadata.name
			namespace: _config.metadata.namespace
			port:      _config.service.port
		}
		if _config.apiService.caBundle != _|_ && _config.tls.type != "cert-manager" {
			caBundle: base64.Encode(null, _config.apiService.caBundle)
		}
	}
}
