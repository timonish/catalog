package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

// The Ingress routing to the web port of the Service.
#Ingress: networkingv1.#Ingress & {
	_config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
	metadata:   _config.metadata
	if _config.web.ingress.labels != _|_ {
		metadata: labels: _config.web.ingress.labels
	}
	if _config.web.ingress.annotations != _|_ {
		metadata: annotations: _config.web.ingress.annotations
	}
	spec: networkingv1.#IngressSpec & {
		if _config.web.ingress.className != _|_ {
			ingressClassName: _config.web.ingress.className
		}
		if _config.web.ingress.tls != _|_ {
			tls: _config.web.ingress.tls
		}
		rules: [for h in _config.web.ingress.hosts {
			host: h.host
			http: paths: [for p in h.paths {
				path:     p.path
				pathType: p.pathType
				backend: service: {
					name: _config.metadata.name
					port: number: _config.service.webPort
				}
			}]
		}]
	}
}
