package templates

import (
	"list"

	rbacv1 "k8s.io/api/rbac/v1"
)

// One list/watch RBAC rule per collector; only the rules of the
// enabled collectors are rendered.
_collectorRules: [
	{collector: "certificatesigningrequests", apiGroups: ["certificates.k8s.io"], resources: ["certificatesigningrequests"]},
	{collector: "configmaps", apiGroups: [""], resources: ["configmaps"]},
	{collector: "cronjobs", apiGroups: ["batch"], resources: ["cronjobs"]},
	{collector: "daemonsets", apiGroups: ["apps"], resources: ["daemonsets"]},
	{collector: "deployments", apiGroups: ["apps"], resources: ["deployments"]},
	{collector: "endpoints", apiGroups: [""], resources: ["endpoints"]},
	{collector: "endpointslices", apiGroups: ["discovery.k8s.io"], resources: ["endpointslices"]},
	{collector: "horizontalpodautoscalers", apiGroups: ["autoscaling"], resources: ["horizontalpodautoscalers"]},
	{collector: "ingresses", apiGroups: ["networking.k8s.io"], resources: ["ingresses"]},
	{collector: "jobs", apiGroups: ["batch"], resources: ["jobs"]},
	{collector: "leases", apiGroups: ["coordination.k8s.io"], resources: ["leases"]},
	{collector: "limitranges", apiGroups: [""], resources: ["limitranges"]},
	{collector: "mutatingwebhookconfigurations", apiGroups: ["admissionregistration.k8s.io"], resources: ["mutatingwebhookconfigurations"]},
	{collector: "namespaces", apiGroups: [""], resources: ["namespaces"]},
	{collector: "networkpolicies", apiGroups: ["networking.k8s.io"], resources: ["networkpolicies"]},
	{collector: "ingressclasses", apiGroups: ["networking.k8s.io"], resources: ["ingressclasses"]},
	{collector: "clusterrolebindings", apiGroups: ["rbac.authorization.k8s.io"], resources: ["clusterrolebindings"]},
	{collector: "clusterroles", apiGroups: ["rbac.authorization.k8s.io"], resources: ["clusterroles"]},
	{collector: "roles", apiGroups: ["rbac.authorization.k8s.io"], resources: ["roles"]},
	{collector: "rolebindings", apiGroups: ["rbac.authorization.k8s.io"], resources: ["rolebindings"]},
	{collector: "nodes", apiGroups: [""], resources: ["nodes"]},
	{collector: "persistentvolumeclaims", apiGroups: [""], resources: ["persistentvolumeclaims"]},
	{collector: "persistentvolumes", apiGroups: [""], resources: ["persistentvolumes"]},
	{collector: "poddisruptionbudgets", apiGroups: ["policy"], resources: ["poddisruptionbudgets"]},
	{collector: "pods", apiGroups: [""], resources: ["pods"]},
	{collector: "replicasets", apiGroups: ["apps"], resources: ["replicasets"]},
	{collector: "replicationcontrollers", apiGroups: [""], resources: ["replicationcontrollers"]},
	{collector: "resourcequotas", apiGroups: [""], resources: ["resourcequotas"]},
	{collector: "secrets", apiGroups: [""], resources: ["secrets"]},
	{collector: "serviceaccounts", apiGroups: [""], resources: ["serviceaccounts"]},
	{collector: "services", apiGroups: [""], resources: ["services"]},
	{collector: "statefulsets", apiGroups: ["apps"], resources: ["statefulsets"]},
	{collector: "storageclasses", apiGroups: ["storage.k8s.io"], resources: ["storageclasses"]},
	{collector: "validatingwebhookconfigurations", apiGroups: ["admissionregistration.k8s.io"], resources: ["validatingwebhookconfigurations"]},
	{collector: "volumeattachments", apiGroups: ["storage.k8s.io"], resources: ["volumeattachments"]},
]

// PolicyRules computes the rules shared between the ClusterRole and
// the namespaced Roles: the enabled collectors and the user-supplied
// extra rules.
#PolicyRules: {
	_config: #Config
	rules: [
		for r in _collectorRules if list.Contains(_config.collectors, r.collector) {
			{apiGroups: r.apiGroups, resources: r.resources, verbs: ["list", "watch"]}
		},
		if _config.rbac.extraRules != _|_ for r in _config.rbac.extraRules {r},
	]
}

// ClusterScopedRules computes the cluster-scoped permissions required
// by the auth filter (token and access reviews) and Custom Resource
// State (reading the custom resource definitions). They are part of
// the ClusterRole, or granted through a supplemental ClusterRole when
// `rbac.useClusterRole` is disabled, as namespaced Roles cannot carry
// them.
#ClusterScopedRules: {
	_config: #Config
	rules: [
		if _config.authFilter.enabled {
			{apiGroups: ["authentication.k8s.io"], resources: ["tokenreviews"], verbs: ["create"]}
		},
		if _config.authFilter.enabled {
			{apiGroups: ["authorization.k8s.io"], resources: ["subjectaccessreviews"], verbs: ["create"]}
		},
		if _config.customResourceState.enabled {
			{apiGroups: ["apiextensions.k8s.io"], resources: ["customresourcedefinitions"], verbs: ["list", "watch"]}
		},
	]
}

#ClusterRole: rbacv1.#ClusterRole & {
	_config: #Config
	let Config = _config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   _config.metadata.name
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: list.Concat([
		(#PolicyRules & {_config: Config}).rules,
		(#ClusterScopedRules & {_config: Config}).rules,
	])
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

// Role grants the collector permissions in a single collected
// namespace when `rbac.useClusterRole` is disabled.
#Role: rbacv1.#Role & {
	_config: #Config
	let Config = _config
	#namespace: string
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      _config.metadata.name
		namespace: #namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: (#PolicyRules & {_config: Config}).rules
}

#RoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	#namespace: string
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      _config.metadata.name
		namespace: #namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     _config.metadata.name
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// ClusterAccessClusterRole grants the cluster-scoped permissions of
// the auth filter and Custom Resource State when `rbac.useClusterRole`
// is disabled.
#ClusterAccessClusterRole: rbacv1.#ClusterRole & {
	_config: #Config
	let Config = _config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-cluster-access"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: (#ClusterScopedRules & {_config: Config}).rules
}

#ClusterAccessClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   "\(_config.metadata.name)-cluster-access"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "\(_config.metadata.name)-cluster-access"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// StsDiscoveryRole lets the autosharding pods discover their shard
// number from their StatefulSet ordinal.
#StsDiscoveryRole: rbacv1.#Role & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "\(_config.metadata.name)-stsdiscovery"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [
		{
			apiGroups: [""]
			resources: ["pods"]
			verbs: ["get"]
		},
		{
			apiGroups: ["apps"]
			resourceNames: [_config.metadata.name]
			resources: ["statefulsets"]
			verbs: ["get", "list", "watch"]
		},
	]
}

#StsDiscoveryRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(_config.metadata.name)-stsdiscovery"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "\(_config.metadata.name)-stsdiscovery"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}
