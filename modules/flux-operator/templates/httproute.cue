package templates

import (
	gatewayv1 "gateway.networking.k8s.io/httproute/v1"
)

// The Gateway API HTTPRoute directing traffic from the referenced
// Gateways to the web port of the Service.
#HTTPRoute: gatewayv1.#HTTPRoute & {
	_config: #Config
	metadata: {
		name:      _config.metadata.name
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.web.httpRoute.labels != _|_ {
			labels: _config.web.httpRoute.labels
		}
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.web.httpRoute.annotations != _|_ {
			annotations: _config.web.httpRoute.annotations
		}
	}
	spec: {
		parentRefs: _config.web.httpRoute.parentRefs
		if _config.web.httpRoute.hostnames != _|_ {
			hostnames: _config.web.httpRoute.hostnames
		}
		rules: [for r in _config.web.httpRoute.rules {
			if r.matches != _|_ {
				matches: r.matches
			}
			if r.filters != _|_ {
				filters: r.filters
			}
			backendRefs: [{
				group:  ""
				kind:   "Service"
				name:   _config.metadata.name
				port:   _config.service.webPort
				weight: 1
			}]
		}]
	}
}
