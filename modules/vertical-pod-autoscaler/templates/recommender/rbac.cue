package recommender

import (
	rbacv1 "k8s.io/api/rbac/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

// The recommender cluster roles and bindings; the subject is the
// recommender service account.
#RBACObjects: {
	#config: config.#Config
	_config: #config
	_name:   "\(_config.metadata.name)-\(_component)"

	_subjects: [{
		kind:      "ServiceAccount"
		name:      _config.recommender.serviceAccount.name
		namespace: _config.metadata.namespace
	}]

	objects: {
		// Reads the pod metrics the recommendation model is built from;
		// `rbac.extraRules` extends it, e.g. for custom metrics.
		"\(_name)-cr-metrics-reader": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-metrics-reader"
			rules: [
				{
					apiGroups: ["metrics.k8s.io"]
					resources: ["pods"]
					verbs: ["get", "list"]
				},
				if _config.rbac.extraRules != _|_ for r in _config.rbac.extraRules {r},
			]
		}
		"\(_name)-crb-metrics-reader": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-metrics-reader"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-metrics-reader"
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
			metadata: name: "\(_name)-actor"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-actor"
			}
			subjects: _subjects
		}

		"\(_name)-cr-status-actor": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-status-actor"
			rules: [{
				apiGroups: ["autoscaling.k8s.io"]
				resources: ["verticalpodautoscalers/status"]
				verbs: ["get", "patch"]
			}]
		}
		"\(_name)-crb-status-actor": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-status-actor"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-status-actor"
			}
			subjects: _subjects
		}

		"\(_name)-cr-checkpoint-actor": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-checkpoint-actor"
			rules: [
				{
					apiGroups: ["poc.autoscaling.k8s.io"]
					resources: ["verticalpodautoscalercheckpoints"]
					verbs: ["get", "list", "watch", "create", "patch", "delete"]
				},
				{
					apiGroups: ["autoscaling.k8s.io"]
					resources: ["verticalpodautoscalercheckpoints"]
					verbs: ["get", "list", "watch", "create", "patch", "delete"]
				},
				{
					apiGroups: [""]
					resources: ["namespaces"]
					verbs: ["get", "list"]
				},
			]
		}
		"\(_name)-crb-checkpoint-actor": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			metadata: name: "\(_name)-checkpoint-actor"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-checkpoint-actor"
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
			metadata: name: "\(_name)-target-reader"
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-target-reader"
			}
			subjects: _subjects
		}

		// Leases for electing the acting recommender replica.
		if _config.recommender.leaderElection.enabled {
			"\(_name)-role-leader-locking": rbacv1.#Role & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "Role"
				metadata: #ClusterObjectMeta & {#config: _config}
				metadata: name:      "\(_name)-leader-locking"
				metadata: namespace: _config.recommender.leaderElection.resourceNamespace
				rules: [
					{
						apiGroups: ["coordination.k8s.io"]
						resources: ["leases"]
						verbs: ["create"]
					},
					{
						apiGroups: ["coordination.k8s.io"]
						resources: ["leases"]
						resourceNames: [_config.recommender.leaderElection.resourceName]
						verbs: ["get", "watch", "update"]
					},
				]
			}
			"\(_name)-rb-leader-locking": rbacv1.#RoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "RoleBinding"
				metadata: #ClusterObjectMeta & {#config: _config}
				metadata: name:      "\(_name)-leader-locking"
				metadata: namespace: _config.recommender.leaderElection.resourceNamespace
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
