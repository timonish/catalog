package templates

import (
	corev1 "k8s.io/api/core/v1"
)

#Service: corev1.#Service & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "Service"
	metadata:   _config.metadata
	if _config.service.labels != _|_ {
		metadata: labels: _config.service.labels
	}
	if _config.service.annotations != _|_ {
		metadata: annotations: _config.service.annotations
	}
	spec: corev1.#ServiceSpec & {
		type: _config.service.type
		if _config.service.clusterIP != _|_ {
			clusterIP: _config.service.clusterIP
		}
		if _config.service.ipFamilies != _|_ {
			ipFamilies: _config.service.ipFamilies
		}
		if _config.service.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _config.service.ipFamilyPolicy
		}
		if _config.service.externalIPs != _|_ {
			externalIPs: _config.service.externalIPs
		}
		if _config.service.type == "LoadBalancer" {
			if _config.service.loadBalancerIP != _|_ {
				loadBalancerIP: _config.service.loadBalancerIP
			}
			if _config.service.loadBalancerClass != _|_ {
				loadBalancerClass: _config.service.loadBalancerClass
			}
			if _config.service.loadBalancerSourceRanges != _|_ {
				loadBalancerSourceRanges: _config.service.loadBalancerSourceRanges
			}
		}
		if _config.service.type != "ClusterIP" {
			if _config.service.externalTrafficPolicy != _|_ {
				externalTrafficPolicy: _config.service.externalTrafficPolicy
			}
		}
		ports: [
			{
				name:        "http"
				port:        _config.service.port
				protocol:    "TCP"
				targetPort:  "http-metrics"
				appProtocol: "http"
				if _config.service.type != "ClusterIP" {
					if _config.service.nodePort > 0 {
						nodePort: _config.service.nodePort
					}
				}
			},
			if _config.web.enabled {
				{
					name:        "http-web"
					port:        _config.service.webPort
					protocol:    "TCP"
					targetPort:  "http-web"
					appProtocol: "http"
					if _config.service.type != "ClusterIP" {
						if _config.service.webNodePort > 0 {
							nodePort: _config.service.webNodePort
						}
					}
				}
			},
		]
		selector: _config.selector.labels
	}
}
