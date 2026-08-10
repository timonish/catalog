package templates

import (
	"list"

	rbacv1 "k8s.io/api/rbac/v1"
)

// The controller rules over namespaced resources: the watched Gateway
// API objects, this module's policy custom resources and the discovery
// of referenced Services and workloads.
_namespacedRules: [...rbacv1.#PolicyRule]
_namespacedRules: [
	{
		apiGroups: [""]
		resources: ["configmaps", "secrets", "services"]
		verbs: ["get", "list", "watch"]
	},
	{
		apiGroups: ["apps"]
		resources: ["deployments", "daemonsets"]
		verbs: ["get", "list", "watch"]
	},
	{
		apiGroups: ["discovery.k8s.io"]
		resources: ["endpointslices"]
		verbs: ["get", "list", "watch"]
	},
	{
		apiGroups: ["gateway.envoyproxy.io"]
		resources: [
			"envoyproxies",
			"envoypatchpolicies",
			"clienttrafficpolicies",
			"backendtrafficpolicies",
			"securitypolicies",
			"envoyextensionpolicies",
			"backends",
			"httproutefilters",
		]
		verbs: ["get", "list", "watch"]
	},
	{
		apiGroups: ["gateway.envoyproxy.io"]
		resources: [
			"envoyproxies/status",
			"envoypatchpolicies/status",
			"clienttrafficpolicies/status",
			"backendtrafficpolicies/status",
			"securitypolicies/status",
			"envoyextensionpolicies/status",
			"backends/status",
		]
		verbs: ["update"]
	},
	{
		apiGroups: ["gateway.networking.k8s.io"]
		resources: [
			"gateways",
			"listenersets",
			"grpcroutes",
			"httproutes",
			"referencegrants",
			"tcproutes",
			"tlsroutes",
			"udproutes",
			"backendtlspolicies",
		]
		verbs: ["get", "list", "watch"]
	},
	{
		apiGroups: ["gateway.networking.k8s.io"]
		resources: [
			"gateways/status",
			"listenersets/status",
			"grpcroutes/status",
			"httproutes/status",
			"tcproutes/status",
			"tlsroutes/status",
			"udproutes/status",
			"backendtlspolicies/status",
		]
		verbs: ["update"]
	},
]

// The topology injector webhook labels the Envoy fleet pods at
// binding time.
_topologyInjectorRule: rbacv1.#PolicyRule & {
	apiGroups: [""]
	resources: ["pods", "pods/binding"]
	verbs: ["get", "list", "patch", "update", "watch"]
}

// The controller rules over cluster-scoped resources.
_clusterRules: [...rbacv1.#PolicyRule]
_clusterRules: [
	{
		apiGroups: [""]
		resources: ["nodes", "namespaces"]
		verbs: ["get", "list", "watch"]
	},
	{
		apiGroups: ["gateway.networking.k8s.io"]
		resources: ["gatewayclasses"]
		verbs: ["get", "list", "patch", "update", "watch"]
	},
	{
		apiGroups: ["gateway.networking.k8s.io"]
		resources: ["gatewayclasses/status"]
		verbs: ["update"]
	},
	{
		apiGroups: ["multicluster.x-k8s.io"]
		resources: ["serviceimports"]
		verbs: ["get", "list", "watch"]
	},
]

// The infrastructure manager rules: full control over the managed
// Envoy fleet workloads and read access to ClusterTrustBundles
// referenced from ClientTrafficPolicies.
_infraRules: [...rbacv1.#PolicyRule]
_infraRules: [
	{
		apiGroups: [""]
		resources: ["serviceaccounts", "services", "configmaps"]
		verbs: ["create", "get", "list", "delete", "deletecollection", "patch", "watch"]
	},
	{
		apiGroups: ["apps"]
		resources: ["deployments", "daemonsets"]
		verbs: ["create", "get", "list", "delete", "deletecollection", "patch", "watch"]
	},
	{
		apiGroups: ["autoscaling"]
		resources: ["horizontalpodautoscalers"]
		verbs: ["create", "get", "list", "delete", "deletecollection", "patch", "watch"]
	},
	{
		apiGroups: ["policy"]
		resources: ["poddisruptionbudgets"]
		verbs: ["create", "get", "list", "delete", "deletecollection", "patch", "watch"]
	},
	{
		apiGroups: ["certificates.k8s.io"]
		resources: ["clustertrustbundles"]
		verbs: ["list", "get", "watch"]
	},
]

_secretsReadRule: rbacv1.#PolicyRule & {
	apiGroups: [""]
	resources: ["secrets"]
	verbs: ["get", "list", "watch"]
}

_tokenReviewRule: rbacv1.#PolicyRule & {
	apiGroups: ["authentication.k8s.io"]
	resources: ["tokenreviews"]
	verbs: ["create"]
}

// The controller ClusterRole. Without watched namespaces it carries
// the namespaced rules cluster-wide; with watched namespaces those
// move into per-namespace Roles and only the cluster-scoped rules
// remain here.
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
	rules: list.Concat([
		_clusterRules,
		if len(_config._watchNamespaces) == 0 {
			list.Concat([
				_namespacedRules,
				if _config.topologyInjector.enabled {[_topologyInjectorRule]},
				[],
			])
		},
		[],
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

// Per-namespace controller Role rendered for each watched namespace.
#WatchedNamespaceRole: rbacv1.#Role & {
	_config:    #Config
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
	rules: list.Concat([
		_namespacedRules,
		if _config.topologyInjector.enabled {[_topologyInjectorRule]},
		[],
	])
}

#WatchedNamespaceRoleBinding: rbacv1.#RoleBinding & {
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

// The infrastructure manager Role in the controller namespace, where
// the Envoy fleet runs by default. In GatewayNamespace deploy mode
// with watched namespaces, the fleet also reads the control plane
// certificate secrets from the controller namespace.
#InfraManagerRole: rbacv1.#Role & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "\(_config.metadata.name)-infra-manager"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: list.Concat([
		_infraRules,
		if _config._gatewayNamespaceMode if len(_config._watchNamespaces) > 0 {[_secretsReadRule]},
		[],
	])
}

#InfraManagerRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(_config.metadata.name)-infra-manager"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "\(_config.metadata.name)-infra-manager"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// Per-namespace infrastructure manager Role rendered for each watched
// namespace in GatewayNamespace deploy mode.
#NamespacedInfraManagerRole: rbacv1.#Role & {
	_config:    #Config
	#namespace: string
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "\(_config.metadata.name)-infra-manager"
		namespace: #namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: _infraRules
}

#NamespacedInfraManagerRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	#namespace: string
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(_config.metadata.name)-infra-manager"
		namespace: #namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "\(_config.metadata.name)-infra-manager"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// The Envoy fleet service accounts authenticate to the ratelimit and
// wasm services with projected tokens the controller verifies through
// TokenReviews (GatewayNamespace deploy mode).
#InfraTokenReviewClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-infra-manager-tokenreview"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [_tokenReviewRule]
}

#InfraTokenReviewClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   "\(_config.metadata.name)-infra-manager-tokenreview"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "\(_config.metadata.name)-infra-manager-tokenreview"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// Cluster-wide infrastructure manager for GatewayNamespace deploy
// mode when the watched namespaces are not enumerated by name.
#ClusterInfraManagerClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-cluster-infra-manager"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: list.Concat([_infraRules, [_tokenReviewRule]])
}

#ClusterInfraManagerClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   "\(_config.metadata.name)-cluster-infra-manager"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "\(_config.metadata.name)-cluster-infra-manager"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// Leader election over Leases in the controller namespace.
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
			apiGroups: [""]
			resources: ["configmaps"]
			verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
		},
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

// The certificate generator creates the control plane secrets.
#CertgenRole: rbacv1.#Role & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "\(_config.metadata.name)-certgen"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		apiGroups: [""]
		resources: ["secrets"]
		verbs: ["get", "create", "update"]
	}]
}

#CertgenRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(_config.metadata.name)-certgen"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "\(_config.metadata.name)-certgen"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      "\(_config.metadata.name)-certgen"
		namespace: _config.metadata.namespace
	}]
}

// The certificate generator patches the CA bundle into the topology
// injector webhook configuration (certgen TLS mode only).
#CertgenClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-certgen"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [
		{
			apiGroups: ["admissionregistration.k8s.io"]
			resources: ["mutatingwebhookconfigurations"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["admissionregistration.k8s.io"]
			resources: ["mutatingwebhookconfigurations"]
			resourceNames: [_config._webhookName]
			verbs: ["update", "patch"]
		},
	]
}

#CertgenClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   "\(_config.metadata.name)-certgen"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "\(_config.metadata.name)-certgen"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      "\(_config.metadata.name)-certgen"
		namespace: _config.metadata.namespace
	}]
}
