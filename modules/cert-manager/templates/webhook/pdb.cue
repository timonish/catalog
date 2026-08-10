package webhook

import (
	policyv1 "k8s.io/api/policy/v1"
	"timoni.sh/cert-manager/templates/config"
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
		if _pdb.minAvailable == _|_ && _pdb.maxUnavailable == _|_ {
			minAvailable: 1
		}
	}
}
