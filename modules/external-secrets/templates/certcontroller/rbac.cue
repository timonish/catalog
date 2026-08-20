package certcontroller

import (
	rbacv1 "k8s.io/api/rbac/v1"
	"timoni.sh/external-secrets/templates/config"
)

// The cert-controller permissions: it watches the CRDs, the webhook
// configurations and the webhook Service endpoints, and writes the
// serving certificate Secret and the CA bundles.
#RBACObjects: {
	#config: config.#Config
	_config: #config

	objects: {
		"cert-controller-clusterrole": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: _config}
			rules: [
				{
					apiGroups: ["apiextensions.k8s.io"]
					resources: ["customresourcedefinitions"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: ["apiextensions.k8s.io"]
					resources: ["customresourcedefinitions"]
					resourceNames: [
						"externalsecrets.external-secrets.io",
						"secretstores.external-secrets.io",
						"clustersecretstores.external-secrets.io",
					]
					verbs: ["update", "patch"]
				},
				{
					apiGroups: ["admissionregistration.k8s.io"]
					resources: ["validatingwebhookconfigurations"]
					verbs: ["list", "watch", "get"]
				},
				{
					apiGroups: ["admissionregistration.k8s.io"]
					resources: ["validatingwebhookconfigurations"]
					resourceNames: ["secretstore-validate", "externalsecret-validate"]
					verbs: ["update", "patch"]
				},
				{
					apiGroups: [""]
					resources: ["endpoints"]
					verbs: ["list", "get", "watch"]
				},
				{
					apiGroups: ["discovery.k8s.io"]
					resources: ["endpointslices"]
					verbs: ["list", "get", "watch"]
				},
				{
					apiGroups: [""]
					resources: ["events"]
					verbs: ["create", "patch"]
				},
				{
					apiGroups: [""]
					resources: ["secrets"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: [""]
					resources: ["secrets"]
					resourceNames: [_config.webhook.tls.secretName]
					verbs: ["update", "patch"]
				},
				{
					apiGroups: ["coordination.k8s.io"]
					resources: ["leases"]
					verbs: ["get", "create", "update", "patch"]
				},
				if _config.certController.metrics.auth.enabled for r in config.#MetricsAuthRules {r},
			]
		}
		"cert-controller-clusterrolebinding": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: _config}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_config.metadata.name)-\(_component)"
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      _config.certController.serviceAccount.name
				namespace: _config.metadata.namespace
			}]
		}
	}
}
