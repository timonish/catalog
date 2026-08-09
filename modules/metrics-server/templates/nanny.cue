package templates

import (
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
)

// The addon-resizer nanny configuration.
#NannyConfigMap: corev1.#ConfigMap & {
	_config:    #Config
	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      "\(_config.metadata.name)-nanny-config"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	data: NannyConfiguration: """
		apiVersion: nannyconfig/v1alpha1
		kind: NannyConfiguration
		baseCPU: \(_config.addonResizer.nanny.cpu)
		cpuPerNode: \(_config.addonResizer.nanny.extraCpu)
		baseMemory: \(_config.addonResizer.nanny.memory)
		memoryPerNode: \(_config.addonResizer.nanny.extraMemory)
		"""
}

#NannyClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "system:\(_config.metadata.name)-nanny"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		nonResourceURLs: ["/metrics"]
		verbs: ["get"]
	}]
}

#NannyClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   "system:\(_config.metadata.name)-nanny"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "system:\(_config.metadata.name)-nanny"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// Role allowing the nanny to patch the metrics-server Deployment.
#NannyRole: rbacv1.#Role & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "system:\(_config.metadata.name)-nanny"
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
			resources: ["deployments"]
			resourceNames: [_config.metadata.name]
			verbs: ["get", "patch"]
		},
	]
}

#NannyRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(_config.metadata.name)-nanny"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "system:\(_config.metadata.name)-nanny"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}
