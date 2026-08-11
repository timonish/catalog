package updater

import (
	rbacv1 "k8s.io/api/rbac/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

// The updater cluster roles and bindings; the subject is the updater
// service account.
#RBACObjects: {
	#config: config.#Config
	_config: #config
	_name:   "\(_config.metadata.name)-\(_component)"

	_subjects: [{
		kind:      "ServiceAccount"
		name:      _config.updater.serviceAccount.name
		namespace: _config.metadata.namespace
	}]

	objects: {
		// Applies in-place resource updates without evicting the pods.
		"\(_name)-cr-in-place": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-in-place"
			rules: [{
				apiGroups: [""]
				resources: ["pods/resize", "pods"]
				verbs: ["patch"]
			}]
		}
		"\(_name)-crb-in-place": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-in-place-binding"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-in-place"
			}
			subjects: _subjects
		}

		"\(_name)-cr-actor": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-actor"
			rules: [
				{
					apiGroups: [""]
					resources: ["pods", "nodes", "limitranges"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: ["", "events.k8s.io"]
					resources: ["events"]
					verbs: ["create", "get", "list", "watch", "patch", "update"]
				},
				{
					apiGroups: ["poc.autoscaling.k8s.io"]
					resources: ["verticalpodautoscalers"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: ["autoscaling.k8s.io"]
					resources: ["verticalpodautoscalers"]
					verbs: ["get", "list", "watch"]
				},
			]
		}
		"\(_name)-crb-actor": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-actor-binding"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-actor"
			}
			subjects: _subjects
		}

		// Evicts the pods whose resources diverge from the
		// recommendation.
		"\(_name)-cr-evictioner": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-evictioner"
			rules: [
				{
					apiGroups: ["apps", "extensions"]
					resources: ["replicasets"]
					verbs: ["get"]
				},
				{
					apiGroups: [""]
					resources: ["pods/eviction"]
					verbs: ["create"]
				},
			]
		}
		"\(_name)-crb-evictioner": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-evictioner-binding"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-evictioner"
			}
			subjects: _subjects
		}

		"\(_name)-cr-target-reader": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-target-reader"
			rules: #TargetReaderRules
		}
		"\(_name)-crb-target-reader": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-target-reader-binding"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-target-reader"
			}
			subjects: _subjects
		}

		// Observes the recommender leases to skip pods whose
		// recommendations are stale.
		"\(_name)-cr-status-reader": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-status-reader"
			rules: [{
				apiGroups: ["coordination.k8s.io"]
				resources: ["leases"]
				verbs: ["get", "list", "watch"]
			}]
		}
		"\(_name)-crb-status-reader": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-status-reader-binding"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-status-reader"
			}
			subjects: _subjects
		}

		// Leases for electing the acting updater replica.
		if _config.updater.leaderElection.enabled {
			"\(_name)-role-leader-locking": rbacv1.#Role & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "Role"
				metadata: #ClusterObjectMeta & {#config: _config}
				metadata: name:      "\(_name)-leader-locking"
				metadata: namespace: _config.updater.leaderElection.resourceNamespace
				rules: [
					{
						apiGroups: ["coordination.k8s.io"]
						resources: ["leases"]
						verbs: ["create"]
					},
					{
						apiGroups: ["coordination.k8s.io"]
						resources: ["leases"]
						resourceNames: [_config.updater.leaderElection.resourceName]
						verbs: ["get", "watch", "update"]
					},
				]
			}
			"\(_name)-rb-leader-locking": rbacv1.#RoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "RoleBinding"
				metadata: #ClusterObjectMeta & {#config: _config}
				metadata: name:      "\(_name)-leader-locking-binding"
				metadata: namespace: _config.updater.leaderElection.resourceNamespace
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "Role"
					name:     "\(_name)-leader-locking"
				}
				subjects: _subjects
			}
		}
	}
}

// Rules granting read access to the workload kinds a
// VerticalPodAutoscaler can target.
#TargetReaderRules: [
	{
		apiGroups: ["*"]
		resources: ["*/scale"]
		verbs: ["get", "watch"]
	},
	{
		apiGroups: [""]
		resources: ["replicationcontrollers"]
		verbs: ["get", "list", "watch"]
	},
	{
		apiGroups: ["apps"]
		resources: ["daemonsets", "deployments", "replicasets", "statefulsets"]
		verbs: ["get", "list", "watch"]
	},
	{
		apiGroups: ["batch"]
		resources: ["jobs", "cronjobs"]
		verbs: ["get", "list", "watch"]
	},
]
