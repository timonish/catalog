package webhook

import (
	rbacv1 "k8s.io/api/rbac/v1"
	"timoni.sh/cert-manager/templates/config"
)

#RBACObjects: {
	#config: config.#Config
	_config: #config
	_name:   "\(_config.metadata.name)-\(_component)"

	objects: {
		// Dynamic serving: the webhook manages its self-signed CA in a
		// Secret; the Role lives in the Secret's namespace. The metrics
		// CA Secret is included when it shares that namespace.
		if _config.webhook.config.tlsConfig.dynamic != _|_ {
			"\(_name)-role-serving": rbacv1.#Role & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "Role"
				metadata: #ClusterObjectMeta & {#config: _config}
				metadata: name:      "\(_name):dynamic-serving"
				metadata: namespace: _config.webhook.config.tlsConfig.dynamic.secretNamespace
				rules: [
					{
						apiGroups: [""]
						resources: ["secrets"]
						resourceNames: [
							_config.webhook.config.tlsConfig.dynamic.secretName,
							if _config.webhook.config.metricsTLSConfig != _|_
							if _config.webhook.config.metricsTLSConfig.dynamic != _|_
							if _config.webhook.config.metricsTLSConfig.dynamic.secretNamespace == _config.webhook.config.tlsConfig.dynamic.secretNamespace {
								_config.webhook.config.metricsTLSConfig.dynamic.secretName
							},
						]
						verbs: ["get", "list", "watch", "update"]
					},
					// CREATE cannot be granted per resourceName.
					{
						apiGroups: [""]
						resources: ["secrets"]
						verbs: ["create"]
					},
				]
			}
			"\(_name)-rb-serving": rbacv1.#RoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "RoleBinding"
				metadata: #ClusterObjectMeta & {#config: _config}
				metadata: name:      "\(_name):dynamic-serving"
				metadata: namespace: _config.webhook.config.tlsConfig.dynamic.secretNamespace
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "Role"
					name:     "\(_name):dynamic-serving"
				}
				subjects: [{
					kind:      "ServiceAccount"
					name:      _config.webhook.serviceAccount.name
					namespace: _config.metadata.namespace
				}]
			}
		}

		// The webhook authorizes approval requests with
		// SubjectAccessReviews.
		"\(_name)-cr-sar": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name):subjectaccessreviews"
			rules: [{
				apiGroups: ["authorization.k8s.io"]
				resources: ["subjectaccessreviews"]
				verbs: ["create"]
			}]
		}
		"\(_name)-crb-sar": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name):subjectaccessreviews"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name):subjectaccessreviews"
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      _config.webhook.serviceAccount.name
				namespace: _config.metadata.namespace
			}]
		}
	}
}
