package webhook

import (
	rbacv1 "k8s.io/api/rbac/v1"
	"timoni.sh/external-secrets/templates/config"
)

// The webhook needs cluster permissions only for authenticating
// metrics requests.
#RBACObjects: {
	#config: config.#Config
	_config: #config
	_name:   "\(_config.metadata.name)-\(_component)-metrics-auth"

	objects: {
		if _config.webhook.metrics.auth.enabled {
			"webhook-metrics-auth-clusterrole": rbacv1.#ClusterRole & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: #ClusterObjectMeta & {#config: _config}
				metadata: name: _name
				rules: config.#MetricsAuthRules
			}
			"webhook-metrics-auth-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: #ClusterObjectMeta & {#config: _config}
				metadata: name: _name
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "ClusterRole"
					name:     _name
				}
				subjects: [{
					kind:      "ServiceAccount"
					name:      _config.webhook.serviceAccount.name
					namespace: _config.metadata.namespace
				}]
			}
		}
	}
}
