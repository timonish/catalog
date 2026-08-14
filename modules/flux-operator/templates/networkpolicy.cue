package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

// The NetworkPolicy allowing ingress to the Flux Status web interface
// from any namespace, and to the metrics port when the ServiceMonitor
// scrapes it.
#NetworkPolicy: networkingv1.#NetworkPolicy & {
	_config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(_config.metadata.name)-web"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	spec: networkingv1.#NetworkPolicySpec & {
		policyTypes: ["Ingress"]
		podSelector: matchLabels: _config.selector.labels
		ingress: [{
			from: [{namespaceSelector: {}}]
			ports: [
				{
					protocol: "TCP"
					port:     "http-web"
				},
				if _config.serviceMonitor.enabled {
					{
						protocol: "TCP"
						port:     "http-metrics"
					}
				},
			]
		}]
	}
}
