package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

// The ConfigMap, Event and Secret write rules of the reconciler.
// Without `targetNamespaces` they are granted cluster-wide through the
// ClusterRole; with a restricted write scope they become per-namespace
// Roles instead.
#TargetRules: {
	#config: #Config
	rules: [
		{
			apiGroups: [""]
			resources: ["configmaps"]
			verbs: ["get", "list", "create", "patch", "watch", "delete"]
		},
		{
			apiGroups: ["", "events.k8s.io"]
			resources: ["events"]
			verbs: ["create", "patch"]
		},
		if #config.secretTargets.enabled && #config.secretTargets.authorizedSecretsAll {
			{
				apiGroups: [""]
				resources: ["secrets"]
				verbs: ["get", "list", "create", "patch", "watch", "delete"]
			}
		},
		if #config.secretTargets.enabled && !#config.secretTargets.authorizedSecretsAll && len(#config.secretTargets.authorizedSecrets) > 0 {
			{
				apiGroups: [""]
				resources: ["secrets"]
				verbs: ["get", "list", "watch"]
			}
		},
		if #config.secretTargets.enabled && !#config.secretTargets.authorizedSecretsAll && len(#config.secretTargets.authorizedSecrets) > 0 {
			{
				apiGroups: [""]
				resources: ["secrets"]
				verbs: ["create", "patch", "delete"]
				resourceNames: #config.secretTargets.authorizedSecrets
			}
		},
	]
}

// ClusterRole granting trust-manager access to Bundles and namespace
// discovery; the write rules are included only when the write scope is
// not restricted to `targetNamespaces`.
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
			apiGroups: ["trust.cert-manager.io"]
			resources: ["bundles"]
			verbs: ["get", "list", "watch"]
		},
		// Updating finalizers is required for trust-manager to work
		// correctly on OpenShift, even though no finalizers are used.
		{
			apiGroups: ["trust.cert-manager.io"]
			resources: ["bundles/finalizers"]
			verbs: ["update"]
		},
		{
			apiGroups: ["trust.cert-manager.io"]
			resources: ["bundles/status"]
			verbs: ["patch"]
		},
		{
			apiGroups: [""]
			resources: ["namespaces"]
			verbs: ["get", "list", "watch"]
		},
		if _config.targetNamespaces == _|_ for rule in (#TargetRules & {#config: _config}).rules {rule},
	]
}

// ClusterRole aggregating Bundle read access into the OpenShift-style
// `cluster-reader` role; Bundle is cluster-scoped, so aggregating into
// the namespaced view/edit/admin roles would have no effect.
#AggregatedClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-cluster-view"
		labels: _config.metadata.labels
		labels: "rbac.authorization.k8s.io/aggregate-to-cluster-reader": "true"
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		apiGroups: ["trust.cert-manager.io"]
		resources: ["bundles"]
		verbs: ["get", "list", "watch"]
	}]
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

// Role granting read access to the Bundle sources (Secrets and
// ConfigMaps are read from the trust namespace only).
#TrustSourceRole: rbacv1.#Role & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      _config.metadata.name
		namespace: _config.trust.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		apiGroups: [""]
		resources: ["secrets"]
		verbs: ["get", "list", "watch"]
	}]
}

#TrustSourceRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      _config.metadata.name
		namespace: _config.trust.namespace
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

#LeaderElectionRole: rbacv1.#Role & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "\(_config.metadata.name):leaderelection"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		apiGroups: ["coordination.k8s.io"]
		resources: ["leases"]
		verbs: ["get", "create", "update", "watch", "list"]
	}]
}

#LeaderElectionRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(_config.metadata.name):leaderelection"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "\(_config.metadata.name):leaderelection"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// Per-namespace Role carrying the write rules when the write scope is
// restricted to `targetNamespaces`.
#TargetRole: rbacv1.#Role & {
	_config:    #Config
	_namespace: string
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "\(_config.metadata.name)-target"
		namespace: _namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: (#TargetRules & {#config: _config}).rules
}

#TargetRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	_namespace: string
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(_config.metadata.name)-target"
		namespace: _namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "\(_config.metadata.name)-target"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}
