package controller

import (
	netv1 "k8s.io/api/networking/v1"
	"timoni.sh/cert-manager/templates/config"
)

#NetworkPolicyIngress: netv1.#NetworkPolicy & {
	#config: config.#Config
	_config: #config

	_meta: #ObjectMeta & {#config: _config}
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(_config.metadata.name)-allow-ingress"
		namespace: _meta.namespace
		labels:    _meta.labels
		if _meta.annotations != _|_ {annotations: _meta.annotations}
	}
	spec: {
		podSelector: matchLabels: #SelectorLabels & {#config: _config}
		policyTypes: ["Ingress"]
		ingress: _config.controller.networkPolicy.ingress
	}
}

#NetworkPolicyEgress: netv1.#NetworkPolicy & {
	#config: config.#Config
	_config: #config

	_meta: #ObjectMeta & {#config: _config}
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata: {
		name:      "\(_config.metadata.name)-allow-egress"
		namespace: _meta.namespace
		labels:    _meta.labels
		if _meta.annotations != _|_ {annotations: _meta.annotations}
	}
	spec: {
		podSelector: matchLabels: #SelectorLabels & {#config: _config}
		policyTypes: ["Egress"]
		egress: _config.controller.networkPolicy.egress
	}
}
