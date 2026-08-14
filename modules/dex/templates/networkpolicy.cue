package templates

import (
	networkingv1 "k8s.io/api/networking/v1"
)

// The NetworkPolicy allowing ingress to the exposed Dex ports from
// any peer; egress is restricted only when egress rules are set.
#NetworkPolicy: networkingv1.#NetworkPolicy & {
	_config:    #Config
	apiVersion: "networking.k8s.io/v1"
	kind:       "NetworkPolicy"
	metadata:   _config.metadata
	spec: networkingv1.#NetworkPolicySpec & {
		policyTypes: [
			if _config.networkPolicy.egress != _|_ {"Egress"},
			"Ingress",
		]
		podSelector: matchLabels: _config.selector.labels
		ingress: [{
			ports: [
				{port: "http"},
				if _config._httpsEnabled {
					{port: "https"}
				},
				if _config._grpcEnabled {
					{port: "grpc"}
				},
				{port: "telemetry"},
			]
		}]
		if _config.networkPolicy.egress != _|_ {
			egress: _config.networkPolicy.egress
		}
	}
}
