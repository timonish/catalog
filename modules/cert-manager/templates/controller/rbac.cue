package controller

import (
	rbacv1 "k8s.io/api/rbac/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/cert-manager/templates/config"
)

// Metadata of the controller cluster-scoped objects (and the RBAC
// roles created in other namespaces).
#ClusterObjectMeta: {
	#config:      config.#Config
	name!:        string
	namespace?:   string & =~".+"
	annotations?: timoniv1.#Annotations
	labels:       #config.metadata.labels
	labels: (timoniv1.#StdLabelComponent): _component
	if #config.metadata.annotations != _|_ {
		annotations: #config.metadata.annotations
	}
}

// The per-controller-area RBAC rules, mirroring the upstream chart.
_clusterRoleRules: {
	issuers: [
		{
			apiGroups: ["cert-manager.io"]
			resources: ["issuers", "issuers/status"]
			verbs: ["update", "patch"]
		},
		{
			apiGroups: ["cert-manager.io"]
			resources: ["issuers"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["secrets"]
			verbs: ["get", "list", "watch", "create", "update", "delete"]
		},
		{
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		},
	]
	clusterissuers: [
		{
			apiGroups: ["cert-manager.io"]
			resources: ["clusterissuers", "clusterissuers/status"]
			verbs: ["update", "patch"]
		},
		{
			apiGroups: ["cert-manager.io"]
			resources: ["clusterissuers"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["secrets"]
			verbs: ["get", "list", "watch", "create", "update", "delete"]
		},
		{
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		},
	]
	certificates: [
		{
			apiGroups: ["cert-manager.io"]
			resources: ["certificates", "certificates/status", "certificaterequests", "certificaterequests/status"]
			verbs: ["update", "patch"]
		},
		{
			apiGroups: ["cert-manager.io"]
			resources: ["certificates", "certificaterequests", "clusterissuers", "issuers"]
			verbs: ["get", "list", "watch"]
		},
		// Finalizer updates support clusters running the
		// OwnerReferencesPermissionEnforcement admission controller.
		{
			apiGroups: ["cert-manager.io"]
			resources: ["certificates/finalizers", "certificaterequests/finalizers"]
			verbs: ["update"]
		},
		{
			apiGroups: ["acme.cert-manager.io"]
			resources: ["orders"]
			verbs: ["create", "delete", "get", "list", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["secrets"]
			verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]
		},
		{
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		},
	]
	orders: [
		{
			apiGroups: ["acme.cert-manager.io"]
			resources: ["orders", "orders/status"]
			verbs: ["update", "patch"]
		},
		{
			apiGroups: ["acme.cert-manager.io"]
			resources: ["orders", "challenges"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["cert-manager.io"]
			resources: ["clusterissuers", "issuers"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["acme.cert-manager.io"]
			resources: ["challenges"]
			verbs: ["create", "delete"]
		},
		{
			apiGroups: ["acme.cert-manager.io"]
			resources: ["orders/finalizers"]
			verbs: ["update"]
		},
		{
			apiGroups: ["cert-manager.io"]
			resources: ["clusterissuers/finalizers", "issuers/finalizers"]
			verbs: ["update"]
		},
		{
			apiGroups: [""]
			resources: ["secrets"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		},
	]
	challenges: [
		{
			apiGroups: ["acme.cert-manager.io"]
			resources: ["challenges", "challenges/status"]
			verbs: ["update", "patch"]
		},
		{
			apiGroups: ["acme.cert-manager.io"]
			resources: ["challenges"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["cert-manager.io"]
			resources: ["issuers", "clusterissuers"]
			verbs: ["get", "list", "watch"]
		},
		// The ACME account private key is needed to complete challenges.
		{
			apiGroups: [""]
			resources: ["secrets"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		},
		// HTTP01 solver resources.
		{
			apiGroups: [""]
			resources: ["pods", "services"]
			verbs: ["get", "list", "watch", "create", "delete"]
		},
		{
			apiGroups: ["networking.k8s.io"]
			resources: ["ingresses"]
			verbs: ["get", "list", "watch", "create", "delete", "update"]
		},
		{
			apiGroups: ["gateway.networking.k8s.io"]
			resources: ["httproutes"]
			verbs: ["get", "list", "watch", "create", "delete", "update"]
		},
		// OpenShift requires this to create ingresses with a custom host.
		{
			apiGroups: ["route.openshift.io"]
			resources: ["routes/custom-host"]
			verbs: ["create"]
		},
		{
			apiGroups: ["acme.cert-manager.io"]
			resources: ["challenges/finalizers"]
			verbs: ["update"]
		},
		// DNS01 rules (duplicated above, kept verbatim from upstream).
		{
			apiGroups: [""]
			resources: ["secrets"]
			verbs: ["get", "list", "watch"]
		},
	]
	"ingress-shim": [
		{
			apiGroups: ["cert-manager.io"]
			resources: ["certificates", "certificaterequests"]
			verbs: ["create", "update", "delete"]
		},
		{
			apiGroups: ["cert-manager.io"]
			resources: ["certificates", "certificaterequests", "issuers", "clusterissuers"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["networking.k8s.io"]
			resources: ["ingresses"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["networking.k8s.io"]
			resources: ["ingresses/finalizers"]
			verbs: ["update"]
		},
		{
			apiGroups: ["gateway.networking.k8s.io"]
			resources: ["gateways", "httproutes", "listenersets"]
			verbs: ["get", "list", "watch"]
		},
		{
			apiGroups: ["gateway.networking.k8s.io"]
			resources: ["gateways/finalizers", "httproutes/finalizers", "listenersets/finalizers"]
			verbs: ["update"]
		},
		{
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		},
	]
}

#RBACObjects: {
	#config: config.#Config
	_config: #config
	let cfg = _config
	_name: _config.metadata.name

	objects: {
		// Leader election in the configured lease namespace; the lease
		// name is fixed by the controller binary.
		"\(_name)-le-role": rbacv1.#Role & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "Role"
			metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name):leaderelection"}
			metadata: namespace: cfg.controller.config.leaderElectionConfig.namespace
			rules: [
				{
					apiGroups: ["coordination.k8s.io"]
					resources: ["leases"]
					resourceNames: ["cert-manager-controller"]
					verbs: ["get", "update", "patch"]
				},
				{
					apiGroups: ["coordination.k8s.io"]
					resources: ["leases"]
					verbs: ["create"]
				},
			]
		}
		"\(_name)-le-rb": rbacv1.#RoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "RoleBinding"
			metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name):leaderelection"}
			metadata: namespace: cfg.controller.config.leaderElectionConfig.namespace
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "Role"
				name:     "\(_name):leaderelection"
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      cfg.controller.serviceAccount.name
				namespace: cfg.metadata.namespace
			}]
		}

		// One ClusterRole and binding per controller area.
		for area, areaRules in _clusterRoleRules {
			"\(_name)-cr-\(area)": rbacv1.#ClusterRole & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name)-controller-\(area)"}
				rules: areaRules
			}
			"\(_name)-crb-\(area)": rbacv1.#ClusterRoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name)-controller-\(area)"}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "ClusterRole"
					name:     "\(_name)-controller-\(area)"
				}
				subjects: [{
					kind:      "ServiceAccount"
					name:      cfg.controller.serviceAccount.name
					namespace: cfg.metadata.namespace
				}]
			}
		}

		// User-facing roles for cert-manager resources, aggregated into
		// the Kubernetes view/edit/admin roles when
		// `rbac.aggregateClusterRoles` is enabled.
		"\(_name)-cr-view": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name)-view"}
			if cfg.rbac.aggregateClusterRoles {
				metadata: labels: {
					"rbac.authorization.k8s.io/aggregate-to-view":           "true"
					"rbac.authorization.k8s.io/aggregate-to-edit":           "true"
					"rbac.authorization.k8s.io/aggregate-to-admin":          "true"
					"rbac.authorization.k8s.io/aggregate-to-cluster-reader": "true"
				}
			}
			rules: [
				{
					apiGroups: ["cert-manager.io"]
					resources: ["certificates", "certificaterequests", "issuers"]
					verbs: ["get", "list", "watch"]
				},
				{
					apiGroups: ["acme.cert-manager.io"]
					resources: ["challenges", "orders"]
					verbs: ["get", "list", "watch"]
				},
			]
		}
		// Challenge create and Order create/patch/update are withheld
		// from users (GHSA-8rvj-mm4h-c258): user-controlled solver or
		// issuerRef changes could exfiltrate ClusterIssuer credentials.
		"\(_name)-cr-edit": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name)-edit"}
			if cfg.rbac.aggregateClusterRoles {
				metadata: labels: {
					"rbac.authorization.k8s.io/aggregate-to-edit":  "true"
					"rbac.authorization.k8s.io/aggregate-to-admin": "true"
				}
			}
			rules: [
				{
					apiGroups: ["cert-manager.io"]
					resources: ["certificates", "certificaterequests", "issuers"]
					verbs: ["create", "delete", "deletecollection", "patch", "update"]
				},
				{
					apiGroups: ["cert-manager.io"]
					resources: ["certificates/status"]
					verbs: ["update"]
				},
				{
					apiGroups: ["acme.cert-manager.io"]
					resources: ["challenges"]
					verbs: ["delete", "deletecollection", "patch", "update"]
				},
				{
					apiGroups: ["acme.cert-manager.io"]
					resources: ["orders"]
					verbs: ["delete", "deletecollection"]
				},
			]
		}
		if cfg.rbac.aggregateClusterRoles {
			"\(_name)-cr-cluster-view": rbacv1.#ClusterRole & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name)-cluster-view"}
				metadata: labels: "rbac.authorization.k8s.io/aggregate-to-cluster-reader": "true"
				rules: [{
					apiGroups: ["cert-manager.io"]
					resources: ["clusterissuers"]
					verbs: ["get", "list", "watch"]
				}]
			}
		}

		// Approval of CertificateRequests referencing the configured
		// signer names.
		if !cfg.disableAutoApproval {
			"\(_name)-cr-approve": rbacv1.#ClusterRole & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name)-controller-approve:cert-manager-io"}
				rules: [{
					apiGroups: ["cert-manager.io"]
					resources: ["signers"]
					verbs: ["approve"]
					resourceNames: cfg.approveSignerNames
				}]
			}
			"\(_name)-crb-approve": rbacv1.#ClusterRoleBinding & {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name)-controller-approve:cert-manager-io"}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "ClusterRole"
					name:     "\(_name)-controller-approve:cert-manager-io"
				}
				subjects: [{
					kind:      "ServiceAccount"
					name:      cfg.controller.serviceAccount.name
					namespace: cfg.metadata.namespace
				}]
			}
		}

		// Signing of Kubernetes CertificateSigningRequests referencing
		// cert-manager issuers.
		"\(_name)-cr-csr": rbacv1.#ClusterRole & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name)-controller-certificatesigningrequests"}
			rules: [
				{
					apiGroups: ["certificates.k8s.io"]
					resources: ["certificatesigningrequests"]
					verbs: ["get", "list", "watch", "update"]
				},
				{
					apiGroups: ["certificates.k8s.io"]
					resources: ["certificatesigningrequests/status"]
					verbs: ["update", "patch"]
				},
				{
					apiGroups: ["certificates.k8s.io"]
					resources: ["signers"]
					resourceNames: ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"]
					verbs: ["sign"]
				},
				{
					apiGroups: ["authorization.k8s.io"]
					resources: ["subjectaccessreviews"]
					verbs: ["create"]
				},
			]
		}
		"\(_name)-crb-csr": rbacv1.#ClusterRoleBinding & {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: #ClusterObjectMeta & {#config: cfg, name: "\(_name)-controller-certificatesigningrequests"}
			roleRef: {
				apiGroup: "rbac.authorization.k8s.io"
				kind:     "ClusterRole"
				name:     "\(_name)-controller-certificatesigningrequests"
			}
			subjects: [{
				kind:      "ServiceAccount"
				name:      cfg.controller.serviceAccount.name
				namespace: cfg.metadata.namespace
			}]
		}
	}
}
