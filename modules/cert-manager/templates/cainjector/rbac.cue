package cainjector

import (
	rbacv1 "k8s.io/api/rbac/v1"
	"timoni.sh/cert-manager/templates/config"
)

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
					apiGroups: ["cert-manager.io"]
					resources: ["certificates"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: [""]
					resources: ["secrets"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: [""]
					resources: ["events"]
					verbs: ["get", "create", "update", "patch"]
				},
				{
					apiGroups: ["admissionregistration.k8s.io"]
					resources: ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"]
					verbs: ["get", "list", "watch", "update", "patch"]
				},
				{
					apiGroups: ["apiregistration.k8s.io"]
					resources: ["apiservices"]
					verbs: ["get", "list", "watch", "update", "patch"]
				},
				{
					apiGroups: ["apiextensions.k8s.io"]
					resources: ["customresourcedefinitions"]
					verbs: ["get", "list", "watch", "update", "patch"]
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
				name:      _config.cainjector.serviceAccount.name
				namespace: _config.metadata.namespace
			}]
		}

		// Leader election in the configured lease namespace; the lease
		// names are fixed by the cainjector binary (certificate-based
		// and secret-based injector controllers).
		"\(_name)-le-role": rbacv1.#Role & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "Role"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name:      "\(_name):leaderelection"
			metadata: namespace: _config.cainjector.config.leaderElectionConfig.namespace
			rules: [
				{
					apiGroups: ["coordination.k8s.io"]
					resources: ["leases"]
					resourceNames: ["cert-manager-cainjector-leader-election", "cert-manager-cainjector-leader-election-core"]
					verbs: ["get", "update", "patch"]
				},
				{
					apiGroups: ["coordination.k8s.io"]
					resources: ["leases"]
					verbs: ["create"]
				},
			]
		}
		"\(_name)-le-rb": rbacv1.#RoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "RoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name:      "\(_name):leaderelection"
			metadata: namespace: _config.cainjector.config.leaderElectionConfig.namespace
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "Role"
				name:     "\(_name):leaderelection"
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      _config.cainjector.serviceAccount.name
				namespace: _config.metadata.namespace
			}]
		}

		// Dynamic serving of the metrics endpoint: the cainjector
		// manages the metrics CA Secret in its namespace.
		if _config.cainjector.config.metricsTLSConfig != _|_
		if _config.cainjector.config.metricsTLSConfig.dynamic != _|_ {
			"\(_name)-role-serving": rbacv1.#Role & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "Role"
				metadata: #ClusterObjectMeta & {#config: _config}
				metadata: name:      "\(_name):dynamic-serving"
				metadata: namespace: _config.cainjector.config.metricsTLSConfig.dynamic.secretNamespace
				rules: [
					{
						apiGroups: [""]
						resources: ["secrets"]
						resourceNames: [_config.cainjector.config.metricsTLSConfig.dynamic.secretName]
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
				metadata: namespace: _config.cainjector.config.metricsTLSConfig.dynamic.secretNamespace
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "Role"
					name:     "\(_name):dynamic-serving"
				}
				subjects: [{
					kind:      "ServiceAccount"
					name:      _config.cainjector.serviceAccount.name
					namespace: _config.metadata.namespace
				}]
			}
		}
	}
}
