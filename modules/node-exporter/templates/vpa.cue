package templates

// Minimal typed schema for the autoscaling.k8s.io
// VerticalPodAutoscaler; the CRDs ship with the Vertical Pod
// Autoscaler and are not vendored per module.
#VerticalPodAutoscaler: {
	_config:    #Config
	apiVersion: "autoscaling.k8s.io/v1"
	kind:       "VerticalPodAutoscaler"
	metadata:   _config.metadata

	let cfg = _config.verticalPodAutoscaler
	spec: {
		targetRef: {
			apiVersion: "apps/v1"
			kind:       "DaemonSet"
			name:       _config.metadata.name
		}
		if cfg.recommenders != _|_ {
			recommenders: cfg.recommenders
		}
		resourcePolicy: containerPolicies: [{
			containerName: "node-exporter"
			if cfg.controlledResources != _|_ {
				controlledResources: cfg.controlledResources
			}
			if cfg.controlledValues != _|_ {
				controlledValues: cfg.controlledValues
			}
			if cfg.maxAllowed != _|_ {
				maxAllowed: cfg.maxAllowed
			}
			if cfg.minAllowed != _|_ {
				minAllowed: cfg.minAllowed
			}
		}]
		if cfg.updatePolicy != _|_ {
			updatePolicy: cfg.updatePolicy
		}
	}
}
