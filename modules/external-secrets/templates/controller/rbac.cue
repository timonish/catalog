package controller

import (
	"list"

	rbacv1 "k8s.io/api/rbac/v1"
	"timoni.sh/external-secrets/templates/config"
)

// The generator kinds the controller reads.
_generators: {
	#config: config.#Config
	list: [
		"acraccesstokens",
		"beyondtrustworkloadcredentialsdynamicsecrets",
		"cloudsmithaccesstokens",
		if #config.controller.reconcilers.clusterGenerator {"clustergenerators"},
		"ecrauthorizationtokens",
		"fakes",
		"gcraccesstokens",
		"githubaccesstokens",
		"gitlabdeploytokens",
		"grafanas",
		"mfas",
		"passwords",
		"quayaccesstokens",
		"sshkeys",
		"stssessiontokens",
		"uuids",
		"vaultdynamicsecrets",
		"webhooks",
	]
}

// The external-secrets.io kinds the controller reconciles, and the
// ones exposed through the user-facing view/edit roles.
_reconciledKinds: {
	#config: config.#Config
	_r:      #config.controller.reconcilers
	list: [
		"secretstores",
		if _r.clusterStore {"clustersecretstores"},
		"externalsecrets",
		if _r.clusterExternalSecret {"clusterexternalsecrets"},
		if _r.pushSecret {"pushsecrets"},
		if _r.clusterPushSecret {"clusterpushsecrets"},
	]
	// The kinds with the status (and finalizers) subresources.
	subresources: [
		for k in list {k},
		for k in list {"\(k)/status"},
		if #config.rbac.openshiftFinalizers for k in list {"\(k)/finalizers"},
	]
	userFacing: [
		"externalsecrets",
		"secretstores",
		if _r.clusterStore {"clustersecretstores"},
		if _r.pushSecret {"pushsecrets"},
		if _r.clusterPushSecret {"clusterpushsecrets"},
	]
}

// The controller permissions, mirroring the upstream chart. The kind
// lists are computed by the caller from the concrete config: deriving
// them here from the #config parameter would see the schema defaults
// instead of the user values.
_controllerRules: {
	#config: config.#Config
	#kinds: [...string]
	#subresources: [...string]
	#generators: [...string]
	_r: #config.controller.reconcilers
	rules: [
		{
			apiGroups: ["external-secrets.io"]
			resources: #kinds
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["external-secrets.io"]
			resources: #subresources
			verbs: ["get", "update", "patch"]
		},
		{
			apiGroups: ["generators.external-secrets.io"]
			resources: ["generatorstates"]
			verbs: ["get", "list", "watch", "create", "update", "patch", "delete", "deletecollection"]
		},
		{
			apiGroups: ["generators.external-secrets.io"]
			resources: #generators
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["serviceaccounts", "namespaces"]
			verbs: ["get", "list", "watch"]
		},
		// Namespace finalizers of ClusterExternalSecrets.
		if _r.clusterExternalSecret {
			{
				apiGroups: [""]
				resources: ["namespaces"]
				verbs: ["update", "patch"]
			}
		},
		{
			apiGroups: [""]
			resources: ["configmaps"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["secrets"]
			verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]
		},
		if #config.controller.genericTargets.enabled {
			{
				apiGroups: [""]
				resources: ["configmaps"]
				verbs: ["create", "update", "delete", "patch"]
			}
		},
		if #config.controller.genericTargets.enabled && #config.controller.genericTargets.resources != _|_
		for t in #config.controller.genericTargets.resources {
			{
				apiGroups: [t.apiGroup]
				resources: t.resources
				verbs:     t.verbs
			}
		},
		if #config.rbac.serviceAccountTokenCreate {
			{
				apiGroups: [""]
				resources: ["serviceaccounts/token"]
				verbs: ["create"]
			}
		},
		{
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		},
		if _r.clusterExternalSecret {
			{
				apiGroups: ["external-secrets.io"]
				resources: ["externalsecrets"]
				verbs: ["create", "update", "delete"]
			}
		},
		if _r.pushSecret {
			{
				apiGroups: ["external-secrets.io"]
				resources: ["pushsecrets"]
				verbs: ["create", "update", "delete"]
			}
		},
		if #config.controller.metrics.auth.enabled for r in config.#MetricsAuthRules {r},
		if #config.rbac.extraRules != _|_ for r in #config.rbac.extraRules {r},
	]
}

#RBACObjects: {
	#config: config.#Config
	_config: #config
	_name:   _config.metadata.name
	let cfg = _config

	// With scoped RBAC the controller, view and edit roles are
	// namespaced to the scoped namespace.
	_scoped: _config.scopedRBAC
	_scopedNamespace: [
		if _config.scopedNamespace != _|_ {_config.scopedNamespace},
		_config.metadata.namespace,
	][0]
	_roleKind: [if _scoped {"Role"}, "ClusterRole"][0]
	_roleMeta: {
		#name: string
		#ClusterObjectMeta & {#config: cfg}
		name: #name
		if _scoped {
			namespace: _scopedNamespace
		}
	}

	_aggregation: {
		if _config.rbac.aggregateClusterRoles {
			"rbac.authorization.k8s.io/aggregate-to-view":  "true"
			"rbac.authorization.k8s.io/aggregate-to-edit":  "true"
			"rbac.authorization.k8s.io/aggregate-to-admin": "true"
		}
	}

	_kinds: _reconciledKinds & {#config: cfg}
	_gens: _generators & {#config: cfg}

	_subject: {
		kind:      "ServiceAccount"
		name:      _config.controller.serviceAccount.name
		namespace: _config.metadata.namespace
	}

	objects: {
		"controller-role": {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       _roleKind
			metadata: _roleMeta & {#name: "\(_name)-controller"}
			rules: (_controllerRules & {
				#config:       cfg
				#kinds:        _kinds.list
				#subresources: _kinds.subresources
				#generators:   _gens.list
			}).rules
		}
		"controller-rolebinding": {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "\(_roleKind)Binding"
			metadata: _roleMeta & {#name: "\(_name)-controller"}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     _roleKind
				name:     "\(_name)-controller"
			}
			subjects: [_subject]
		}

		// The user-facing roles, aggregated into the Kubernetes
		// view/edit/admin ClusterRoles.
		"view-role": {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       _roleKind
			metadata: _roleMeta & {#name: "\(_name)-view"}
			metadata: labels: _aggregation
			rules: [
				{
					apiGroups: ["external-secrets.io"]
					resources: _kinds.userFacing
					verbs: ["get", "watch", "list"]
				},
				{
					apiGroups: ["generators.external-secrets.io"]
					resources: list.Concat([_gens.list, ["generatorstates"]])
					verbs: ["get", "watch", "list"]
				},
			]
		}
		"edit-role": {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       _roleKind
			metadata: _roleMeta & {#name: "\(_name)-edit"}
			metadata: labels: {
				if _config.rbac.aggregateClusterRoles {
					"rbac.authorization.k8s.io/aggregate-to-edit":  "true"
					"rbac.authorization.k8s.io/aggregate-to-admin": "true"
				}
			}
			rules: [
				{
					apiGroups: ["external-secrets.io"]
					resources: _kinds.userFacing
					verbs: ["create", "delete", "deletecollection", "patch", "update"]
				},
				{
					apiGroups: ["generators.external-secrets.io"]
					resources: list.Concat([_gens.list, ["generatorstates"]])
					verbs: ["create", "delete", "deletecollection", "patch", "update"]
				},
			]
		}

		// Leader election leases in the instance namespace.
		"leaderelection-role": rbacv1.#Role & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "Role"
			metadata: #ClusterObjectMeta & {#config: cfg}
			metadata: {
				name:      "\(_name)-leaderelection"
				namespace: _config.metadata.namespace
			}
			rules: [
				{
					apiGroups: [""]
					resources: ["configmaps"]
					resourceNames: [_config.controller.leaderElection.id]
					verbs: ["get", "update", "patch"]
				},
				{
					apiGroups: [""]
					resources: ["configmaps"]
					verbs: ["create"]
				},
				{
					apiGroups: ["coordination.k8s.io"]
					resources: ["leases"]
					verbs: ["get", "create", "update", "patch"]
				},
			]
		}
		"leaderelection-rolebinding": rbacv1.#RoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "RoleBinding"
			metadata: #ClusterObjectMeta & {#config: cfg}
			metadata: {
				name:      "\(_name)-leaderelection"
				namespace: _config.metadata.namespace
			}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "Role"
				name:     "\(_name)-leaderelection"
			}
			subjects: [_subject]
		}

		if _config.rbac.serviceBindings {
			"servicebindings-clusterrole": rbacv1.#ClusterRole & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: #ClusterObjectMeta & {#config: cfg}
				metadata: name: "\(_name)-servicebindings"
				metadata: labels: "servicebinding.io/controller": "true"
				rules: [{
					apiGroups: ["external-secrets.io"]
					resources: [
						"externalsecrets",
						if _config.controller.reconcilers.pushSecret {"pushsecrets"},
					]
					verbs: ["get", "list", "watch"]
				}]
			}
		}

		if _config.rbac.systemAuthDelegator {
			"auth-delegator-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: #ClusterObjectMeta & {#config: cfg}
				metadata: name: "\(_name)-auth-delegator"
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "ClusterRole"
					name:     "system:auth-delegator"
				}
				subjects: [_subject]
			}
		}
	}
}
