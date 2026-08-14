package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

// ClusterRole granting the operator access to its custom resources
// and the objects it reconciles them into. The operator creates the
// RBAC for the Fluent Bit and Fluentd workloads at runtime, so it
// holds the create/patch verbs on roles and bindings; it can only
// grant permissions it holds itself.
#ClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   _config.metadata.name
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [
		{
			apiGroups: ["apps"]
			resources: ["daemonsets", "statefulsets"]
			verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["pods"]
			verbs: ["get"]
		},
		{
			apiGroups: [""]
			resources: ["events"]
			verbs: ["list", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["secrets", "configmaps", "serviceaccounts", "services"]
			verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
		},
		// The controller only reads namespaces; write access would also
		// be delegable to the managed workloads through the FluentBit
		// rbacRules field.
		{
			apiGroups: [""]
			resources: ["namespaces"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["fluentbit.fluent.io"]
			resources: [
				"collectors",
				"fluentbits",
				"fluentbits/finalizers",
				"clusterfluentbitconfigs",
				"clusterfluentbitconfigs/finalizers",
				"clusterfilters",
				"clusterfilters/finalizers",
				"clusterinputs",
				"clusterinputs/finalizers",
				"clusteroutputs",
				"clusteroutputs/finalizers",
				"clusterparsers",
				"clusterparsers/finalizers",
				"fluentbitconfigs",
				"fluentbitconfigs/finalizers",
				"multilineparsers",
				"multilineparsers/finalizers",
				"clustermultilineparsers",
				"clustermultilineparsers/finalizers",
				"filters",
				"outputs",
				"parsers",
			]
			verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
		},
		{
			apiGroups: ["fluentd.fluent.io"]
			resources: [
				"fluentds",
				"fluentds/status",
				"clusterfluentdconfigs",
				"clusterfluentdconfigs/status",
				"fluentdconfigs",
				"fluentdconfigs/status",
				"clusterfilters",
				"filters",
				"clusteroutputs",
				"outputs",
				"inputs",
				"clusterinputs",
			]
			verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
		},
		{
			apiGroups: ["rbac.authorization.k8s.io"]
			resources: ["clusterrolebindings", "clusterroles"]
			verbs: ["create", "list", "get", "watch", "patch"]
		},
		// The namespaced-mode finalizer (--watch-namespaces) deletes the
		// per-workload Role and RoleBinding it created.
		{
			apiGroups: ["rbac.authorization.k8s.io"]
			resources: ["rolebindings", "roles"]
			verbs: ["create", "list", "get", "watch", "patch", "delete"]
		},
		if _config.rbac.extraRules != _|_ for r in _config.rbac.extraRules {r},
	]
}

#ClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
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
		name:     _config.metadata.name
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// Role granting the leader election lease in the instance namespace,
// rendered only when leader election is enabled.
#LeaderElectionRole: rbacv1.#Role & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "\(_config.metadata.name)-leader-election"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [
		{
			apiGroups: ["coordination.k8s.io"]
			resources: ["leases"]
			verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
		},
		{
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		},
	]
}

#LeaderElectionRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(_config.metadata.name)-leader-election"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "\(_config.metadata.name)-leader-election"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}
