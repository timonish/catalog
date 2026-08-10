package templates

import (
	policyv1 "k8s.io/api/policy/v1"
)

#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	_config:    #Config
	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata:   _config.metadata
	spec: {
		if _config.podDisruptionBudget.minAvailable != _|_ {
			minAvailable: _config.podDisruptionBudget.minAvailable
		}
		if _config.podDisruptionBudget.maxUnavailable != _|_ {
			maxUnavailable: _config.podDisruptionBudget.maxUnavailable
		}
		if _config.podDisruptionBudget.unhealthyPodEvictionPolicy != _|_ {
			unhealthyPodEvictionPolicy: _config.podDisruptionBudget.unhealthyPodEvictionPolicy
		}
		selector: matchLabels: _config.selector.labels
	}
}
