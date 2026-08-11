package admission

import (
	rbacv1 "k8s.io/api/rbac/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

// The admission-controller cluster role and binding; the subject is
// the admission-controller service account.
#RBACObjects: {
	#config: config.#Config
	_config: #config
	_name:   "\(_config.metadata.name)-\(_component)"

	objects: {
		"\(_name)-cr": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			rules: [
				{
					apiGroups: [""]
					resources: ["pods", "configmaps", "nodes", "limitranges", "replicationcontrollers"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: ["apps"]
					resources: ["deployments", "replicasets", "daemonsets", "statefulsets"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: ["batch"]
					resources: ["jobs", "cronjobs"]
					verbs: ["get", "list", "watch"]
				},
				// The webhook configuration is written by the
				// application itself only in registerWebhook mode.
				if _config.admissionController.registerWebhook {
					{
						apiGroups: ["admissionregistration.k8s.io"]
						resources: ["mutatingwebhookconfigurations"]
						verbs: ["list", "get", "create", "patch", "delete"]
					}
				},
				{
					apiGroups: ["autoscaling.k8s.io"]
					resources: ["verticalpodautoscalers"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: ["coordination.k8s.io"]
					resources: ["leases"]
					verbs: ["create", "update", "get", "list", "watch"]
				},
				// Scale subresources for resolving target selectors.
				{
					apiGroups: ["*"]
					resources: ["*/scale"]
					verbs: ["get", "watch"]
				},
			]
		}
		"\(_name)-crb": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     _name
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      _config.admissionController.serviceAccount.name
				namespace: _config.metadata.namespace
			}]
		}
	}
}
