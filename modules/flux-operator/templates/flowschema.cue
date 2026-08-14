package templates

import (
	flowcontrolv1 "k8s.io/api/flowcontrol/v1"
)

// The FlowSchema assigning the Kubernetes API requests of the operator
// service account — and of the extra service accounts, e.g. the Flux
// controllers — to the configured priority level.
#FlowSchema: flowcontrolv1.#FlowSchema & {
	_config:    #Config
	apiVersion: "flowcontrol.apiserver.k8s.io/v1"
	kind:       "FlowSchema"
	metadata: {
		name:   _config.metadata.name
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}

		// Keep the API server from reconciling the spec back to the
		// suggested defaults.
		annotations: "apf.kubernetes.io/autoupdate-spec": "false"
	}
	spec: {
		distinguisherMethod: type: "ByUser"
		matchingPrecedence: 950
		priorityLevelConfiguration: name: _config.apiPriority.level
		rules: [{
			nonResourceRules: [{
				nonResourceURLs: ["*"]
				verbs: ["*"]
			}]
			resourceRules: [{
				apiGroups: ["*"]
				clusterScope: true
				namespaces: ["*"]
				resources: ["*"]
				verbs: ["*"]
			}]
			subjects: [
				{
					kind: "ServiceAccount"
					serviceAccount: {
						name:      _config.serviceAccount.name
						namespace: _config.metadata.namespace
					}
				},
				for sa in _config.apiPriority.extraServiceAccounts {
					{
						kind: "ServiceAccount"
						serviceAccount: {
							name:      sa.name
							namespace: sa.namespace
						}
					}
				},
			]
		}]
	}
}
