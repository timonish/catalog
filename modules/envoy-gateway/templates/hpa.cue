package templates

import (
	autoscalingv2 "k8s.io/api/autoscaling/v2"
)

#HorizontalPodAutoscaler: autoscalingv2.#HorizontalPodAutoscaler & {
	_config:    #Config
	apiVersion: "autoscaling/v2"
	kind:       "HorizontalPodAutoscaler"
	metadata:   _config.metadata
	spec: {
		scaleTargetRef: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			name:       _config.metadata.name
		}
		minReplicas: _config.hpa.minReplicas
		maxReplicas: _config.hpa.maxReplicas
		if len(_config.hpa.metrics) > 0 {
			metrics: _config.hpa.metrics
		}
		if _config.hpa.behavior != _|_ {
			behavior: _config.hpa.behavior
		}
	}
}
