package templates

import (
	corev1 "k8s.io/api/core/v1"
)

// The controller Service is named `envoy-gateway`: the managed Envoy
// fleet dials the xDS server at that fixed DNS name, and the topology
// injector webhook is served through it.
#Service: corev1.#Service & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      _config._serviceName
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.service.annotations != _|_ {
			annotations: _config.service.annotations
		}
	}
	spec: corev1.#ServiceSpec & {
		type:     _config.service.type
		selector: _config.selector.labels
		ports: [
			{name: "grpc", port: _config.ports.grpc, targetPort: "grpc", protocol: "TCP"},
			{name: "ratelimit", port: _config.ports.ratelimit, targetPort: "ratelimit", protocol: "TCP"},
			{name: "wasm", port: _config.ports.wasm, targetPort: "wasm", protocol: "TCP"},
			{name: "metrics", port: _config.ports.metrics, targetPort: "metrics", protocol: "TCP"},
			if _config.topologyInjector.enabled {
				{name: "webhook", port: 9443, targetPort: 9443, protocol: "TCP"}
			},
		]
		if _config.service.trafficDistribution != _|_ {
			trafficDistribution: _config.service.trafficDistribution
		}
		if _config.service.ipFamilies != _|_ {
			ipFamilies: _config.service.ipFamilies
		}
		if _config.service.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _config.service.ipFamilyPolicy
		}
		if _config.service.type == "LoadBalancer" {
			if _config.service.loadBalancerIP != _|_ {
				loadBalancerIP: _config.service.loadBalancerIP
			}
			if _config.service.loadBalancerClass != _|_ {
				loadBalancerClass: _config.service.loadBalancerClass
			}
		}
	}
}
