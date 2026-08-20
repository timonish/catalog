package config

import (
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Runtime version info automatically set at apply-time.
	moduleVersion!: string
	kubeVersion!:   string

	// External Secrets requires Kubernetes 1.25 or newer.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.25.0"}

	// Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// Extra labels added to all resources.
	commonLabels?: timoniv1.#Labels
	if commonLabels != _|_ {
		metadata: labels: commonLabels
	}

	// CRD lifecycle settings. `install: false` skips the CRDs for
	// secondary instances; `keep: true` marks them with
	// `timoni.sh/prune: disabled` so an uninstall preserves the CRDs
	// and every External Secrets custom resource in the cluster.
	crds: {
		install: *true | bool
		keep:    *false | bool
	}

	// References to secrets used for pulling images from private
	// registries, added to all service accounts.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// RBAC settings. Set `create: false` when the roles and bindings
	// are managed outside of this module.
	rbac: {
		create: *true | bool

		// Aggregate the External Secrets view/edit ClusterRoles into
		// the Kubernetes user-facing view, edit and admin roles.
		aggregateClusterRoles: *true | bool

		// Grant the controller the `serviceaccounts/token` create
		// permission used by stores authenticating with service
		// account tokens. When disabled, grant it per service account
		// with a Role constrained by `resourceNames` instead.
		serviceAccountTokenCreate: *true | bool

		// Create the ClusterRole granting the Service Binding
		// controllers read access to ExternalSecrets and PushSecrets.
		serviceBindings: *true | bool

		// Add the `finalizers` subresources to the controller
		// permissions, required by OpenShift.
		openshiftFinalizers: *true | bool

		// Bind the controller to the `system:auth-delegator`
		// ClusterRole.
		systemAuthDelegator: *false | bool

		// Extra rules added to the controller ClusterRole (or Role
		// when `scopedRBAC` is set).
		extraRules?: [...rbacv1.#PolicyRule]
	}

	// Restrict the controller to the custom resources of a single
	// namespace.
	scopedNamespace?: string & =~".+"

	// Grant the controller namespaced RBAC (Role and RoleBinding in
	// `scopedNamespace`, or the instance namespace) instead of
	// cluster-wide permissions. The cluster-scoped reconcilers
	// (ClusterSecretStore, ClusterExternalSecret, ClusterPushSecret)
	// are disabled.
	scopedRBAC: *false | bool
	if scopedRBAC {
		controller: reconcilers: {
			clusterStore:          false
			clusterExternalSecret: false
			clusterPushSecret:     false
		}
	}

	// Enable HTTP/2 on the metrics and webhook listeners of all
	// components; disabled by default to mitigate HTTP/2 stream
	// cancellation and rapid reset attacks.
	enableHTTP2: *false | bool

	// The container image repository, tag, digest and pull policy
	// shared by all components (the webhook and cert-controller are
	// subcommands of the same binary). The default repository and tag
	// track the upstream release and are set in `images.cue` by
	// upengine.
	image: timoniv1.#Image

	// The security preset applied to the pod identity defaults of all
	// components: the default "hardened" preset pins the image's
	// non-root UID, while "platform" leaves the identity to an
	// admission controller (e.g. an OpenShift
	// SecurityContextConstraint).
	securityContextPreset: timoniv1.#SecurityContextPreset

	// Prometheus Operator ServiceMonitor (optional) scraping the
	// metrics of all deployed components, created in the instance
	// namespace. Enabling it creates the metrics Services.
	serviceMonitor: timoniv1.#MonitorValues

	// The External Secrets controller settings.
	controller: #ControllerValues & {
		#Preset: securityContextPreset
		serviceAccount: {
			if controller.serviceAccount.create {name: *metadata.name | string & =~".+"}
			if !controller.serviceAccount.create {name: *"default" | string & =~".+"}
		}
		networkPolicy: ingress: *[{
			ports: [
				{port: "metrics", protocol: "TCP"},
				{port: "healthz", protocol: "TCP"},
			]
		}] | [...netv1.#NetworkPolicyIngressRule]
	}

	// The validating webhook settings. Disabling the webhook skips the
	// admission configurations and the cert-controller; SecretStore
	// and ExternalSecret resources are then admitted unvalidated.
	webhook: #WebhookValues & {
		#Preset: securityContextPreset
		serviceAccount: {
			if webhook.serviceAccount.create {name: *"\(metadata.name)-webhook" | string & =~".+"}
			if !webhook.serviceAccount.create {name: *"default" | string & =~".+"}
		}
		tls: secretName: *"\(metadata.name)-webhook" | string & =~".+"
		networkPolicy: ingress: *[{
			ports: [
				{port: "webhook", protocol: "TCP"},
				{port: "metrics", protocol: "TCP"},
				{port: "healthz", protocol: "TCP"},
			]
		}] | [...netv1.#NetworkPolicyIngressRule]
	}

	// The cert-controller settings. The cert-controller generates the
	// webhook serving certificate into the webhook Secret and injects
	// its CA into the webhook configurations; it is deployed only with
	// the default `webhook.tls.type: "cert-controller"`.
	certController: #CertControllerValues & {
		#Preset: securityContextPreset
		serviceAccount: {
			if certController.serviceAccount.create {name: *"\(metadata.name)-cert-controller" | string & =~".+"}
			if !certController.serviceAccount.create {name: *"default" | string & =~".+"}
		}
		networkPolicy: ingress: *[{
			ports: [
				{port: "metrics", protocol: "TCP"},
				{port: "healthz", protocol: "TCP"},
			]
		}] | [...netv1.#NetworkPolicyIngressRule]
	}

	_guard: "valid"
	_guard: [
		if !controller.reconcilers.pushSecret && controller.reconcilers.clusterPushSecret {
			"controller.reconcilers.clusterPushSecret requires controller.reconcilers.pushSecret"
		},
		if webhook.tls.type == "existingSecret" && webhook.tls.caBundle == "" {
			"webhook.tls.caBundle is required with webhook.tls.type existingSecret"
		},
		if webhook.tls.type == "cert-manager" && !webhook.tls.certManager.existingIssuer.enabled && webhook.tls.certManager.existingIssuer.name != "" {
			"webhook.tls.certManager.existingIssuer.name requires existingIssuer.enabled"
		},
		"valid",
	][0]
}

// ControllerValues defines the controller component settings.
#ControllerValues: C={
	#Workload

	// Leader election between the controller replicas, enabled by
	// default when running more than one.
	leaderElection: #LeaderElectionValues & {
		enabled: *(C.replicas > 1) | bool

		// The name of the lease object; set a unique value when
		// running several independent instances in one namespace.
		id: *"external-secrets-controller" | string & =~".+"
	}

	// Reconcile only the stores labeled with this controller class
	// (`spec.controller` of the SecretStore), e.g. when running
	// several instances.
	controllerClass?: string & =~".+"

	// The number of concurrent ExternalSecret reconciles.
	concurrent: *1 | int & >0

	// The default interval between (Cluster)SecretStore reconciles.
	storeRequeueInterval?: #Duration

	// Add the recommended Kubernetes annotations of the reconciled
	// resources as metric labels.
	extendedMetricLabels: *false | bool

	// The reconcilers to run; disabling one also drops the matching
	// RBAC permissions. ClusterPushSecret requires PushSecret.
	reconcilers: {
		clusterStore:          *true | bool
		clusterExternalSecret: *true | bool
		clusterPushSecret:     *true | bool
		secretStore:           *true | bool
		pushSecret:            *true | bool
		clusterGenerator:      *true | bool
	}

	// Support for generic targets (ConfigMaps and custom resources)
	// instead of Secrets. Enabling it grants the controller write
	// access to ConfigMaps plus the listed resource types; make sure
	// access policies and encryption are configured accordingly.
	genericTargets: {
		enabled: *false | bool
		resources?: [...{
			apiGroup: string
			resources: [string & =~".+", ...string & =~".+"]
			verbs: [string & =~".+", ...string & =~".+"]
		}]
	}

	// Cache the HashiCorp Vault tokens across reconciles instead of
	// creating a new one on each request.
	vault: {
		enableTokenCache: *false | bool
		tokenCacheSize:   *262144 | int & >0
	}

	// The health endpoint port.
	healthPort: *8082 | int & >0 & <=65535

	// The liveness probe of the controller container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *"healthz" | string | int
		}
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *5 | int
	}

	// The readiness probe of the controller container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/readyz" | string
			port: *"healthz" | string | int
		}
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *3 | int
	}
}

// WebhookValues defines the webhook component settings.
#WebhookValues: WV={
	#Workload

	// Whether to deploy the validating webhook.
	enabled: *true | bool

	// The webhook listener port; the default avoids conflicts with
	// kubelet components and is open in GKE private cluster firewalls.
	port: *10250 | int & >0 & <=65535

	// The health endpoint port.
	healthPort: *8081 | int & >0 & <=65535

	// The interval at which the webhook checks its serving certificate
	// for renewal, and how far ahead of the expiry it reloads.
	certCheckInterval:  *"5m" | #Duration
	lookaheadInterval?: #Duration

	// The serving certificate of the webhook. With the default
	// `cert-controller` type the cert-controller generates a
	// self-signed certificate into the `secretName` Secret and injects
	// its CA into the webhook configurations. With `cert-manager` the
	// certificate is requested from a cert-manager issuer — a
	// self-signed Issuer created by the module, or an existing one —
	// and the CA is injected by cert-manager. With `existingSecret`
	// the `secretName` Secret holds a user-provided certificate and
	// `caBundle` its PEM-encoded CA.
	tls: {
		type:       *"cert-controller" | "cert-manager" | "existingSecret"
		secretName: string & =~".+"

		certManager: {
			// Annotate the webhook configurations for CA injection by
			// the cert-manager cainjector.
			addInjectorAnnotations: *true | bool
			// Create the Certificate; disable it when a separately
			// managed Certificate writes the `secretName` Secret.
			createCertificate: *true | bool
			existingIssuer: {
				enabled: *false | bool
				kind:    *"Issuer" | "ClusterIssuer" | string & =~".+"
				group:   *"cert-manager.io" | string & =~".+"
				if enabled {
					name: string & =~".+"
				}
				if !enabled {
					name: *"" | string
				}
			}
			duration:              *"8760h" | #Duration
			renewBefore?:          #Duration
			revisionHistoryLimit?: int & >=0
			privateKey?: {
				algorithm?:      "RSA" | "ECDSA" | "Ed25519"
				size?:           int & >0
				encoding?:       "PKCS1" | "PKCS8"
				rotationPolicy?: "Never" | "Always"
			}
			signatureAlgorithm?: string & =~".+"
			annotations?:        timoniv1.#Annotations
			labels?:             timoniv1.#Labels
		}

		// The PEM-encoded CA bundle of the existing serving
		// certificate, set as the webhook configurations' CA.
		caBundle: *"" | string
	}

	// The failure policy of the validating webhooks: `Fail` rejects
	// SecretStore and ExternalSecret changes while the webhook is
	// unavailable, `Ignore` admits them unvalidated.
	failurePolicy: *"Fail" | "Ignore"

	// The number of seconds the API server waits for the webhook to
	// respond before failing the request.
	timeoutSeconds: *5 | int & >=1 & <=30

	// Annotations added to the ValidatingWebhookConfigurations.
	annotations?: timoniv1.#Annotations

	// The webhook Service settings. The metrics port is added to this
	// Service when `metrics.service.enabled` or the ServiceMonitor is
	// set, with the `metrics.service` annotations and labels merged
	// in; its network settings come from this block.
	service: {
		type:       *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:       *443 | int & >0 & <=65535
		clusterIP?: string & =~".+"
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
		if type == "NodePort" {
			nodePort: *0 | int & >=0 & <=32767
		}
		if type == "LoadBalancer" {
			loadBalancerIP?:    string & =~".+"
			loadBalancerClass?: string & =~".+"
			loadBalancerSourceRanges?: [...string]
		}
		if type != "ClusterIP" {
			externalTrafficPolicy?: "Cluster" | "Local"
		}
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
	}

	// The liveness probe of the webhook container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *"healthz" | string | int
		}
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *5 | int
	}

	// The readiness probe of the webhook container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/readyz" | string
			port: *"healthz" | string | int
		}
		initialDelaySeconds: *20 | int
		periodSeconds:       *5 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *3 | int
	}

	// The startup probe of the webhook container (optional).
	startupProbe?: corev1.#Probe

	_metricsServiceGuard: "valid"
	_metricsServiceGuard: [
		if WV.metrics.service.clusterIP != _|_ || WV.metrics.service.ipFamilies != _|_ || WV.metrics.service.ipFamilyPolicy != _|_ {
			"webhook.metrics.service network settings are configured through webhook.service"
		},
		"valid",
	][0]
}

// CertControllerValues defines the cert-controller component settings.
#CertControllerValues: CC={
	#Workload

	// Leader election between the cert-controller replicas, enabled
	// by default when running more than one.
	leaderElection: enabled: *(CC.replicas > 1) | bool

	// The interval between reconciles of the webhook certificate.
	requeueInterval: *"5m" | #Duration

	// Cache only the Secrets labeled `external-secrets.io/component`
	// instead of all Secrets in the cluster.
	enablePartialCache: *true | bool

	// The health endpoint port.
	healthPort: *8081 | int & >0 & <=65535

	// The liveness probe of the cert-controller container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *"healthz" | string | int
		}
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *5 | int
	}

	// The readiness probe of the cert-controller container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/readyz" | string
			port: *"healthz" | string | int
		}
		initialDelaySeconds: *20 | int
		periodSeconds:       *5 | int
		timeoutSeconds:      *5 | int
		successThreshold:    *1 | int
		failureThreshold:    *3 | int
	}

	// The startup probe of the cert-controller container (optional).
	startupProbe?: corev1.#Probe
}
