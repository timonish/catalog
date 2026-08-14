package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// Static Endpoints for node exporters running outside the cluster,
// named after the Service so they are scraped through it on the
// exporter default port.
#Endpoints: corev1.#Endpoints & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "Endpoints"
	metadata:   _config.metadata
	subsets: [{
		addresses: [for a in _config.endpoints {ip: a}]
		ports: [{
			name:     _config.service.portName
			port:     9100
			protocol: "TCP"
		}]
	}]
}
