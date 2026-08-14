package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

// The binding granting the operator service account the cluster-admin
// role, required for deploying arbitrary cluster components from a
// FluxInstance and for reconciling ResourceSets.
#AdminClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   _config.metadata.name
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "cluster-admin"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// The ClusterRole aggregating write access over the ResourceSet APIs
// into the Kubernetes edit and admin roles.
#AggregateEditClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-edit"
		labels: _config.metadata.labels
		labels: {
			"rbac.authorization.k8s.io/aggregate-to-edit":  "true"
			"rbac.authorization.k8s.io/aggregate-to-admin": "true"
		}
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		apiGroups: ["fluxcd.controlplane.io"]
		resources: ["resourcesets", "resourcesetinputproviders"]
		verbs: ["create", "delete", "deletecollection", "patch", "update"]
	}]
}

// The ClusterRole aggregating read access over the ResourceSet APIs
// into the Kubernetes view, edit and admin roles.
#AggregateViewClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-view"
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
		apiGroups: ["fluxcd.controlplane.io"]
		resources: ["resourcesets", "resourcesetinputproviders"]
		verbs: ["get", "list", "watch"]
	}]
}
