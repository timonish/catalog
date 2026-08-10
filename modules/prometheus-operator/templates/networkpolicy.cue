package templates

import (
	netv1 "k8s.io/api/networking/v1"
)

#NetworkPolicyIngress: netv1.#NetworkPolicy & {
	_config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(_config.metadata.name)-allow-ingress"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	spec: {
		podSelector: matchLabels: _config.selector.labels
		policyTypes: ["Ingress"]
		ingress: _config.networkPolicy.ingress
	}
}

#NetworkPolicyEgress: netv1.#NetworkPolicy & {
	_config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(_config.metadata.name)-allow-egress"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	spec: {
		podSelector: matchLabels: _config.selector.labels
		policyTypes: ["Egress"]
		egress: _config.networkPolicy.egress
	}
}
