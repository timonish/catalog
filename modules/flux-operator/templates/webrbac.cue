package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

// The Flux API groups covered by the GitOps user actions.
_fluxAPIGroups: [
	"fluxcd.controlplane.io",
	"source.toolkit.fluxcd.io",
	"source.extensions.fluxcd.io",
	"kustomize.toolkit.fluxcd.io",
	"helm.toolkit.fluxcd.io",
	"image.toolkit.fluxcd.io",
	"notification.toolkit.fluxcd.io",
]

// The read-only ClusterRole of the standalone web server, replacing
// the cluster-admin binding in `web.serverOnly` mode.
#WebClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-view"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [
		{
			apiGroups: ["*"]
			resources: ["*"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create"]
		},
		{
			apiGroups: [""]
			resources: ["users", "groups"]
			verbs: ["impersonate"]
		},
		// Fine-grained access: GitOps actions are performed using the
		// web server's own privileges instead of impersonating the
		// user. These are the native Kubernetes verbs required by the
		// privileged API calls behind each action (reconcile, suspend,
		// resume and download patch/read Flux resources; restart
		// patches workloads and creates Jobs from CronJobs; delete
		// removes Pods). They are not the custom GitOps verbs, which
		// are only checked against the user's identity.
		if _config._webFineGrained {
			{
				apiGroups: _fluxAPIGroups
				resources: ["*"]
				verbs: ["patch"]
			}
		},
		if _config._webFineGrained {
			{
				apiGroups: ["apps"]
				resources: ["deployments", "statefulsets", "daemonsets"]
				verbs: ["patch"]
			}
		},
		if _config._webFineGrained {
			{
				apiGroups: ["batch"]
				resources: ["jobs"]
				verbs: ["create"]
			}
		},
		if _config._webFineGrained {
			{
				apiGroups: [""]
				resources: ["pods"]
				verbs: ["delete"]
			}
		},
	]
}

#WebClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
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
		name:     "\(_config.metadata.name)-view"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// The standard role granting web users read-only access to the Flux
// Status Page; bind users or groups to it with a ClusterRoleBinding.
#WebUserClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "flux-web-user"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		apiGroups: ["*"]
		resources: ["*"]
		verbs: ["get", "list", "watch"]
	}]
}

// The standard role granting web users read access plus all the
// GitOps actions on the Flux resources and their workloads.
#WebAdminClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "flux-web-admin"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [
		{
			apiGroups: ["*"]
			resources: ["*"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: _fluxAPIGroups
			resources: ["*"]
			verbs: ["patch", "reconcile", "suspend", "resume", "download"]
		},
		{
			apiGroups: ["apps"]
			resources: ["deployments", "statefulsets", "daemonsets"]
			verbs: ["patch", "restart"]
		},
		{
			apiGroups: ["batch"]
			resources: ["cronjobs", "jobs"]
			verbs: ["create", "restart"]
		},
		{
			apiGroups: [""]
			resources: ["pods"]
			verbs: ["delete"]
		},
	]
}

// The ClusterRole aggregating the GitOps action verbs into the
// Kubernetes edit role.
#WebEditClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "flux-web-edit"
		labels: _config.metadata.labels
		labels: "rbac.authorization.k8s.io/aggregate-to-edit": "true"
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [
		{
			apiGroups: _fluxAPIGroups
			resources: ["*"]
			verbs: ["reconcile", "suspend", "resume", "download"]
		},
		{
			apiGroups: ["apps"]
			resources: ["deployments", "statefulsets", "daemonsets"]
			verbs: ["patch", "restart"]
		},
		{
			apiGroups: ["batch"]
			resources: ["cronjobs", "jobs"]
			verbs: ["create", "restart"]
		},
		{
			apiGroups: [""]
			resources: ["pods"]
			verbs: ["delete"]
		},
	]
}
