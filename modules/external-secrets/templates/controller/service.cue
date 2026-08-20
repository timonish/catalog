package controller

import (
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/external-secrets/templates/config"
)

// The controller metrics Service, created when
// `controller.metrics.service.enabled` or the ServiceMonitor is set.
#Service: corev1.#Service & {
	#config: config.#Config
	_config: #config
	_svc:    _config.controller.metrics.service

	apiVersion: "v1"
	kind:       "Service"
	metadata: #ClusterObjectMeta & {#config: _config}
	metadata: {
		name:      "\(_config.metadata.name)-metrics"
		namespace: _config.metadata.namespace
	}
	if _svc.annotations != _|_ {
		metadata: annotations: _svc.annotations
	}
	if _svc.labels != _|_ {
		metadata: labels: _svc.labels
	}
	spec: corev1.#ServiceSpec & {
		type: "ClusterIP"
		if _svc.clusterIP != _|_ {
			clusterIP: _svc.clusterIP
		}
		if _svc.ipFamilyPolicy != _|_ {
			ipFamilyPolicy: _svc.ipFamilyPolicy
		}
		if _svc.ipFamilies != _|_ {
			ipFamilies: _svc.ipFamilies
		}
		selector: #SelectorLabels & {#config: _config}
		ports: [{
			name:       "metrics"
			protocol:   "TCP"
			port:       _svc.port
			targetPort: "metrics"
		}]
	}
}
