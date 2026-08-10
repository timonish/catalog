package templates

import (
	rbacv1 "k8s.io/api/rbac/v1"
)

// The monitoring.coreos.com custom resources managed by the operator,
// shared between the operator ClusterRole and the aggregated roles.
_monitoringResources: [
	"alertmanagers",
	"alertmanagerconfigs",
	"prometheuses",
	"prometheusagents",
	"thanosrulers",
	"scrapeconfigs",
	"servicemonitors",
	"podmonitors",
	"probes",
	"prometheusrules",
]

// ClusterRole granting the operator access to its custom resources
// and the objects it reconciles them into.
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
			apiGroups: ["monitoring.coreos.com"]
			resources: [
				"alertmanagers",
				"alertmanagers/finalizers",
				"alertmanagers/status",
				"alertmanagerconfigs",
				"prometheuses",
				"prometheuses/finalizers",
				"prometheuses/status",
				"prometheusagents",
				"prometheusagents/finalizers",
				"prometheusagents/status",
				"thanosrulers",
				"thanosrulers/finalizers",
				"thanosrulers/status",
				"scrapeconfigs",
				"scrapeconfigs/status",
				"servicemonitors",
				"servicemonitors/status",
				"podmonitors",
				"podmonitors/status",
				"probes",
				"probes/status",
				"prometheusrules",
				"prometheusrules/status",
			]
			verbs: ["*"]
		},
		{
			apiGroups: ["apps"]
			resources: ["statefulsets"]
			verbs: ["*"]
		},
		// The operator refuses to start the PrometheusAgent DaemonSet
		// reconciler without this permission.
		if _config._prometheusAgentDaemonSet {
			{
				apiGroups: ["apps"]
				resources: ["daemonsets"]
				verbs: ["*"]
			}
		},
		{
			apiGroups: [""]
			resources: ["configmaps", "secrets"]
			verbs: ["*"]
		},
		{
			apiGroups: [""]
			resources: ["pods"]
			verbs: ["list", "delete"]
		},
		{
			apiGroups: [""]
			resources: ["services", "services/finalizers"]
			verbs: ["get", "create", "update", "delete"]
		},
		{
			apiGroups: [""]
			resources: ["nodes"]
			verbs: ["list", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["namespaces"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["events.k8s.io"]
			resources: ["events"]
			verbs: ["patch", "create"]
		},
		{
			apiGroups: ["networking.k8s.io"]
			resources: ["ingresses"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["storage.k8s.io"]
			resources: ["storageclasses"]
			verbs: ["get"]
		},
		{
			apiGroups: [""]
			resources: ["endpoints"]
			verbs: ["get", "create", "update", "delete"]
		},
		// The EndpointSlice mirror of the kubelet Endpoints object.
		if _config.kubeletEndpointSlice {
			{
				apiGroups: ["discovery.k8s.io"]
				resources: ["endpointslices"]
				verbs: ["get", "list", "watch", "create", "update", "delete"]
			}
		},
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

// ClusterRole aggregated to the admin, edit and view built-in roles,
// granting read access to the monitoring custom resources.
#AggregatedViewClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-crd-view"
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
		apiGroups: ["monitoring.coreos.com"]
		resources: _monitoringResources
		verbs: ["get", "list", "watch"]
	}]
}

// ClusterRole aggregated to the admin and edit built-in roles,
// granting write access to the monitoring custom resources.
#AggregatedEditClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-crd-edit"
		labels: _config.metadata.labels
		labels: {
			"rbac.authorization.k8s.io/aggregate-to-admin": "true"
			"rbac.authorization.k8s.io/aggregate-to-edit":  "true"
		}
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		apiGroups: ["monitoring.coreos.com"]
		resources: _monitoringResources
		verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
	}]
}
