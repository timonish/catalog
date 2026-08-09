package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

// ClusterRole granting metrics-server access to the resources
// it collects metrics from.
#ClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "system:\(_config.metadata.name)"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [
		{
			apiGroups: [""]
			resources: ["nodes/metrics"]
			verbs: ["get"]
		},
		{
			apiGroups: [""]
			resources: ["pods", "nodes", "namespaces", "configmaps"]
			verbs: ["get", "list", "watch"]
		},
	]
}

// ClusterRole aggregated to the admin, edit and view built-in roles,
// granting read access to the metrics API.
#AggregatedClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "system:\(_config.metadata.name)-aggregated-reader"
		labels: _config.metadata.labels
		labels: {
			"rbac.authorization.k8s.io/aggregate-to-admin": "true"
			"rbac.authorization.k8s.io/aggregate-to-edit":  "true"
			"rbac.authorization.k8s.io/aggregate-to-view":  "true"
		}
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		apiGroups: ["metrics.k8s.io"]
		resources: ["pods", "nodes"]
		verbs: ["get", "list", "watch"]
	}]
}

#ClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   "system:\(_config.metadata.name)"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "system:\(_config.metadata.name)"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// Binding to the system:auth-delegator role for delegated
// authentication and authorization checks.
#AuthDelegatorClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   "\(_config.metadata.name):system:auth-delegator"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "system:auth-delegator"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// Binding to the extension-apiserver-authentication-reader role
// in kube-system, required to read the authentication configuration.
#AuthReaderRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(_config.metadata.name)-auth-reader"
		namespace: "kube-system"
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "extension-apiserver-authentication-reader"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}
