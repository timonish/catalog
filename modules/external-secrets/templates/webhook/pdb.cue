package webhook

import (
	policyv1 "k8s.io/api/policy/v1"
	"timoni.sh/external-secrets/templates/config"
)

#PodDisruptionBudget: policyv1.#PodDisruptionBudget & {
	#config: config.#Config
	_config: #config
	_pdb:    _config.webhook.podDisruptionBudget

	apiVersion: "policy/v1"
	kind:       "PodDisruptionBudget"
	metadata: #ObjectMeta & {#config: _config}
	spec: {
		selector: matchLabels: #SelectorLabels & {#config: _config}
		if _pdb.minAvailable != _|_ {
			minAvailable: _pdb.minAvailable
		}
		if _pdb.maxUnavailable != _|_ {
			maxUnavailable: _pdb.maxUnavailable
		}

		// unhealthyPodEvictionPolicy requires Kubernetes 1.27 or newer.
		if _pdb.unhealthyPodEvictionPolicy != _|_ &&
			(_config.clusterVersion.major > 1 || _config.clusterVersion.minor >= 27) {
			unhealthyPodEvictionPolicy: _pdb.unhealthyPodEvictionPolicy
		}
	}
}
