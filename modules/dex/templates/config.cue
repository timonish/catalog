package templates

import (
	"encoding/yaml"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Duration is a string in the Go duration format, e.g. `24h` or `1h30m`.
#Duration: string & =~"^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"

// DexConfig defines the schema for the Dex configuration file, rendered
// into an immutable Secret mounted at /etc/dex/config.yaml. The listen
// addresses are managed by the module and map to the fixed container
// ports: 5556 (http), 5554 (https), 5557 (grpc) and 5558 (telemetry).
// Docs: https://dexidp.io/docs/configuration/
#DexConfig: {
	// The base path of Dex and the external name of the OpenID Connect
	// service, used as the `iss` claim of the issued ID tokens.
	issuer: string & =~".+"

	// The backend storing the Dex state. The default `kubernetes` type
	// keeps the state in namespaced custom resources of the
	// `dex.coreos.com` API group; Dex creates the custom resource
	// definitions on startup (see the `rbac` values).
	storage: {
		type: *"kubernetes" | "memory" | "sqlite3" | "postgres" | "mysql" | "etcd"
		if type == "kubernetes" {
			config: {
				// Use the in-cluster service account credentials, or a
				// kubeconfig file mounted into the pod.
				inCluster:       *true | bool
				kubeConfigFile?: string & =~".+"
				if kubeConfigFile != _|_ {
					inCluster: false
				}

				// `ensure` creates the missing custom resource
				// definitions on startup, `check` fails the startup
				// when they are not pre-installed.
				crdHandling?: "ensure" | "check"
			}
		}
		if type != "kubernetes" {
			// The connection settings of the selected backend, e.g.
			// the DSN fields for the SQL types.
			config?: {...}
		}
	}

	// The HTTP server settings.
	web: {
		http: "0.0.0.0:5556"
		// Setting the certificate and key file paths (mounted with
		// `extraVolumes`) enables the HTTPS listener.
		tlsCert?: string & =~".+"
		tlsKey?:  string & =~".+"
		if tlsCert != _|_ {
			tlsKey: string & =~".+"
			https:  "0.0.0.0:5554"
		}
		if tlsKey != _|_ {
			tlsCert: string & =~".+"
		}
		tlsMinVersion?:   "1.2" | "1.3"
		tlsMaxVersion?:   "1.2" | "1.3"
		_tlsVersionGuard: "valid"
		_tlsVersionGuard: [
			if tlsMinVersion != _|_ && tlsMaxVersion != _|_ && tlsMinVersion == "1.3" && tlsMaxVersion == "1.2" {
				"web.tlsMinVersion greater than web.tlsMaxVersion"
			},
			"valid",
		][0]
		// Security headers added to the HTTP responses.
		headers?: {
			"Content-Security-Policy"?:   string
			"X-Frame-Options"?:           string
			"X-Content-Type-Options"?:    string
			"X-XSS-Protection"?:          string
			"Strict-Transport-Security"?: string
		}
		allowedOrigins?: [...string]
		allowedHeaders?: [...string]
		// Derive the client IP from a forwarding header (e.g.
		// `X-Forwarded-For`) when set by one of the trusted proxies.
		clientRemoteIP?: {
			header: string & =~".+"
			trustedProxies: [...string]
		}
	}

	// The metrics and health endpoints server settings.
	telemetry: {
		http:             "0.0.0.0:5558"
		enableProfiling?: bool
	}

	// Enabling the gRPC API also adds the port to the container and
	// the Service.
	grpc?: {
		addr:     "0.0.0.0:5557"
		tlsCert?: string & =~".+"
		tlsKey?:  string & =~".+"
		if tlsCert != _|_ {
			tlsKey: string & =~".+"
		}
		if tlsKey != _|_ {
			tlsCert: string & =~".+"
		}

		// Mutual TLS client CA; requires the server certificate.
		tlsClientCA?: string & =~".+"
		if tlsClientCA != _|_ {
			tlsCert: string & =~".+"
		}
		tlsMinVersion?:   "1.2" | "1.3"
		tlsMaxVersion?:   "1.2" | "1.3"
		_tlsVersionGuard: "valid"
		_tlsVersionGuard: [
			if tlsMinVersion != _|_ && tlsMaxVersion != _|_ && tlsMinVersion == "1.3" && tlsMaxVersion == "1.2" {
				"grpc.tlsMinVersion greater than grpc.tlsMaxVersion"
			},
			"valid",
		][0]
		reflection?: bool
	}

	// OAuth2 flow customization.
	oauth2?: {
		grantTypes?: [...string]
		responseTypes?: [...string]
		skipApprovalScreen?:    bool
		alwaysShowLoginScreen?: bool
		passwordConnector?:     string & =~".+"
	}

	// The lifetime of the issued tokens and generated keys.
	expiry?: {
		signingKeys?:    #Duration
		idTokens?:       #Duration
		authRequests?:   #Duration
		deviceRequests?: #Duration
		refreshTokens?: {
			disableRotation?:   bool
			reuseInterval?:     #Duration
			absoluteLifetime?:  #Duration
			validIfNotUsedFor?: #Duration
		}
	}

	// Logging settings.
	logger?: {
		level?:  "debug" | "info" | "warn" | "error"
		format?: "text" | "json"
	}

	// The web frontend customization.
	frontend?: {
		dir?:     string & =~".+"
		logoURL?: string & =~".+"
		issuer?:  string & =~".+"
		theme?:   string & =~".+"
		extra?: {[string]: string}
	}

	// The signer of the issued JWT tokens; defaults to signing keys
	// managed by Dex in its storage.
	signer?: {
		type: "local" | "vault"
		config?: {...}
	}

	// The identity providers Dex federates to.
	connectors?: [...#DexConnector]

	// The OAuth2 clients registered statically; write operations
	// through the gRPC API fail for them.
	staticClients?: [...#DexStaticClient]

	// Maintain a list of local email/password identities.
	enablePasswordDB?: bool
	staticPasswords?: [...#DexStaticPassword]
	if staticPasswords != _|_ {
		enablePasswordDB: true
	}
}

// DexConnector defines the schema for an upstream identity provider.
// The config schema is connector-specific, see
// https://dexidp.io/docs/connectors/
#DexConnector: {
	type: string & =~".+"
	id:   string & =~".+"
	name: string & =~".+"
	config?: {...}
}

// DexStaticClient defines the schema for a statically registered
// OAuth2 client. The client ID and the non-public client secret are
// set literally or read from an environment variable of the Dex
// container, one of each pair.
#DexStaticClient: {
	id?:        string & =~".+"
	idEnv?:     string & =~".+"
	name:       string & =~".+"
	secret?:    string & =~".+"
	secretEnv?: string & =~".+"
	public:     *false | bool
	redirectURIs?: [...string]
	trustedPeers?: [...string]
	logoURL?: string & =~".+"

	if idEnv == _|_ {
		id: string & =~".+"
	}
	if !public && secret == _|_ {
		secretEnv: string & =~".+"
	}
	_guard: "valid"
	_guard: [
		if id != _|_ && idEnv != _|_ {"id and idEnv are mutually exclusive"},
		if secret != _|_ && secretEnv != _|_ {"secret and secretEnv are mutually exclusive"},
		"valid",
	][0]
}

// DexStaticPassword defines the schema for a local identity of the
// password database. The bcrypt hash is set literally or read from an
// environment variable of the Dex container, one of the two.
#DexStaticPassword: {
	email:        string & =~".+"
	hash?:        string & =~".+"
	hashFromEnv?: string & =~".+"
	if hash == _|_ {
		hashFromEnv: string & =~".+"
	}
	username?:          string
	userID?:            string
	name?:              string
	preferredUsername?: string
	emailVerified?:     bool
	groups?: [...string]
}

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Runtime version info automatically set at apply-time.
	moduleVersion!: string
	kubeVersion!:   string

	// Dex requires Kubernetes 1.25 or newer.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.25.0"}

	// Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// Extra labels added to all resources.
	commonLabels?: timoniv1.#Labels
	if commonLabels != _|_ {
		metadata: labels: commonLabels
	}

	// Label selector common to all resources.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// The Dex configuration, rendered into a hash-named immutable
	// Secret so configuration changes roll the pods. The issuer
	// defaults to the in-cluster Service URL.
	config: #DexConfig
	config: issuer: *"http://\(metadata.name).\(metadata.namespace).svc.cluster.local:5556" | string

	// Mount an existing Secret carrying the Dex configuration under
	// the `config.yaml` key instead of rendering one from `config`.
	// Configuration changes then no longer roll the pods; pair the
	// Secret with a reloader or restart the pods manually.
	configSecretName?: string & =~".+"

	// Whether the HTTPS and gRPC listeners are enabled in the Dex
	// configuration; they add the ports to the container, the Service
	// and the NetworkPolicy.
	_httpsEnabled: config.web.tlsCert != _|_
	_grpcEnabled:  config.grpc != _|_

	// Whether the Dex state lives in dex.coreos.com custom resources.
	_k8sStorage: config.storage.type == "kubernetes"

	// The Dex configuration file rendered into a hash-named immutable
	// Secret; the object name embeds the hash of the data so
	// configuration changes roll the pods.
	_configSecret: timoniv1.#ImmutableConfig & {
		#Kind:   timoniv1.#SecretKind
		#Suffix: "-config"
		#Meta:   metadata
		#Data: "config.yaml": yaml.Marshal(config)
	}
	_configSecretName: [
		if configSecretName != _|_ {configSecretName},
		_configSecret.metadata.name,
	][0]

	// The number of pod replicas; ignored when the autoscaler is
	// enabled.
	replicas: *1 | int & >=0

	// The number of old ReplicaSets to retain.
	revisionHistoryLimit?: int & >=0

	// The strategy to replace old pods with new ones.
	strategy?: appsv1.#DeploymentStrategy

	// The container image repository, tag, digest and pull policy.
	// The default repository and tag track the upstream release
	// and are set in `images.cue` by upengine.
	image: timoniv1.#Image

	// References to secrets used for pulling images from private registries.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// Extra command line arguments appended to `dex serve`.
	extraArgs: *[] | [...string]

	// Environment variables for the Dex container: feature flags
	// (e.g. `DEX_EXPAND_ENV`) and the variables expanded in the
	// configuration (`secretEnv`, `hashFromEnv`, `$VAR` references in
	// the storage, connector and signer settings).
	env?: [...corev1.#EnvVar]

	// Environment variables sourced from ConfigMaps or Secrets.
	envFrom?: [...corev1.#EnvFromSource]

	// The container resource requirements.
	resources?: timoniv1.#ResourceRequirements

	// The container security context, hardened by default. The pod
	// identity (UID/GID) is a pod-level concern, see podSecurityContext.
	securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext

	// The liveness probe of the Dex container, served by the
	// telemetry endpoint.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz/live" | string
			port: *"telemetry" | string | int
		}
	}

	// The readiness probe of the Dex container, served by the
	// telemetry endpoint; it covers the storage backend health.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz/ready" | string
			port: *"telemetry" | string | int
		}
	}

	// The startup probe of the Dex container (optional).
	startupProbe?: corev1.#Probe

	// The volume backing /tmp: the image entrypoint preprocesses the
	// configuration file into it (the root filesystem is read-only).
	tmpVolume: *{emptyDir: {}} | corev1.#VolumeSource

	// Extra volumes and volume mounts, e.g. the TLS certificates
	// referenced in the Dex configuration.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Extra containers and init containers added to the pods.
	extraContainers?: [...corev1.#Container]
	initContainers?: [...corev1.#Container]

	// The security preset applied to the pod identity defaults: the
	// default "hardened" preset pins the image's non-root UID, while
	// "platform" leaves the identity to an admission controller
	// (e.g. an OpenShift SecurityContextConstraint).
	securityContextPreset: timoniv1.#SecurityContextPreset

	// The pod security context generated for the security preset.
	podSecurityContext: corev1.#PodSecurityContext & timoniv1.#PodSecurityContext & {
		#Preset: securityContextPreset
		#User:   1001
	}

	// Pod optional settings.
	podLabels?:      timoniv1.#Labels
	podAnnotations?: timoniv1.#Annotations
	// Pods are scheduled on Linux nodes by default.
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	hostAliases?: [...corev1.#HostAlias]
	dnsConfig?:                     corev1.#PodDNSConfig
	dnsPolicy?:                     "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	priorityClassName?:             string & =~".+"
	schedulerName?:                 string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

	// Mount the service account token into the pod; Dex requires it
	// for the kubernetes storage backend.
	automountServiceAccountToken: *_k8sStorage | bool

	// The affinity rules; Linux placement comes from the nodeSelector
	// default. `podAntiAffinity` accepts the `soft` (default), `hard`
	// and `none` presets for spreading the replicas across nodes, or
	// raw pod anti-affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}

	// Labels and annotations added to the Deployment.
	deploymentLabels?:      timoniv1.#Labels
	deploymentAnnotations?: timoniv1.#Annotations

	// ServiceAccount settings. Set `create: false` to use an existing
	// service account referenced by `name`.
	serviceAccount: {
		create: *true | bool
		if create {
			name: *metadata.name | string
		}
		if !create {
			// Matches the chart: without a name, the pods run under the
			// namespace default service account.
			name: *"default" | string
		}
		labels?:      timoniv1.#Labels
		annotations?: timoniv1.#Annotations
		// The token is mounted through the pod setting instead.
		automountServiceAccountToken: *false | bool
	}

	// RBAC settings for the kubernetes storage backend: a namespaced
	// Role over the dex.coreos.com custom resources, and a ClusterRole
	// allowing Dex to create their definitions on startup. The roles
	// are rendered only with `config.storage.type: kubernetes`; disable
	// `createClusterScoped` when the definitions are pre-installed and
	// `crdHandling: check` is set.
	rbac: {
		create:              *true | bool
		createClusterScoped: *true | bool
		extraRules?: [...rbacv1.#PolicyRule]
	}

	// Service settings. The http port is always exposed, the https and
	// grpc ports follow the listeners enabled in the Dex configuration,
	// and the telemetry port (5558) is always exposed for scraping.
	service: {
		type:       *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:       *5556 | int & >0 & <=65535
		httpsPort:  *5554 | int & >0 & <=65535
		grpcPort:   *5557 | int & >0 & <=65535
		clusterIP?: string & =~".+"
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
		externalIPs?: [...string]
		if type != "ClusterIP" {
			// Zero lets the cluster assign the node ports.
			nodePort:      *0 | int & >=0 & <=32767
			httpsNodePort: *0 | int & >=0 & <=32767
			grpcNodePort:  *0 | int & >=0 & <=32767
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

	// Ingress for the Dex http Service port (optional). Terminate TLS
	// at the ingress controller, or pass HTTPS through to a Dex HTTPS
	// listener configured in `config.web`.
	ingress: {
		enabled:    *false | bool
		className?: string & =~".+"
		if enabled {
			hosts: [#IngressHost, ...#IngressHost]
		}
		tls?: [...networkingv1.#IngressTLS]
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
	}

	// Gateway API HTTPRoute for the Dex http Service port (optional),
	// an alternative to the Ingress. The route backend is generated by
	// the module; each rule takes matches and filters.
	httpRoute: {
		enabled: *false | bool
		if enabled {
			parentRefs: [{...}, ...{...}]
		}
		hostnames?: [...string & =~".+"]
		rules: *[{matches: [{path: {type: "PathPrefix", value: "/"}}]}] | [...{
			matches?: [...{...}]
			filters?: [...{...}]
		}]
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
	}

	// NetworkPolicy (optional): allows ingress to the exposed ports
	// from any peer, and restricts egress to the given rules when set.
	networkPolicy: {
		enabled: *false | bool
		egress?: [...networkingv1.#NetworkPolicyEgressRule]
	}

	// PodDisruptionBudget (optional). The mutually exclusive
	// `minAvailable` and `maxUnavailable` accept an absolute number
	// or a percentage; `minAvailable: 1` is the default.
	// `unhealthyPodEvictionPolicy` requires Kubernetes 1.27 or newer
	// and is omitted on older clusters.
	podDisruptionBudget: {
		enabled:                     *false | bool
		unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
		*{minAvailable: *1 | int & >=0 | string & =~"^[0-9]+%$"} | {maxUnavailable: int & >=0 | string & =~"^[0-9]+%$"}
	}

	// HorizontalPodAutoscaler (optional). When enabled, the Deployment
	// leaves the replica count to the autoscaler.
	hpa: {
		enabled:     *false | bool
		minReplicas: *1 | int & >0
		maxReplicas: *minReplicas | int & >=minReplicas
		metrics: *[] | [...]
		behavior?: {...}
	}

	// Prometheus Operator ServiceMonitor (optional), created in the
	// instance namespace and scraping the telemetry port.
	serviceMonitor: timoniv1.#MonitorValues
}

// IngressHost defines the schema for an Ingress rule of one host.
#IngressHost: {
	host: string & =~".+"
	paths: *[{path: "/", pathType: "Prefix"}] | [...{
		path:     string & =~".+"
		pathType: *"Prefix" | "Exact" | "ImplementationSpecific"
	}]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			"\(config.metadata.name)-sa": #ServiceAccount & {_config: config}
		}

		if config.rbac.create && (config._k8sStorage || config.rbac.extraRules != _|_) {
			"\(config.metadata.name)-role": #Role & {_config: config}
			"\(config.metadata.name)-rb": #RoleBinding & {_config: config}
		}

		if config.rbac.create && config._k8sStorage && config.rbac.createClusterScoped {
			"\(config.metadata.name)-cr": #ClusterRole & {_config: config}
			"\(config.metadata.name)-crb": #ClusterRoleBinding & {_config: config}
		}

		if config.configSecretName == _|_ {
			"\(config.metadata.name)-secret": config._configSecret
		}

		"\(config.metadata.name)-svc": #Service & {_config: config}
		"\(config.metadata.name)-deploy": #Deployment & {_config: config}

		if config.ingress.enabled {
			"\(config.metadata.name)-ingress": #Ingress & {_config: config}
		}

		if config.httpRoute.enabled {
			"\(config.metadata.name)-httproute": #HTTPRoute & {_config: config}
		}

		if config.networkPolicy.enabled {
			"\(config.metadata.name)-netpol": #NetworkPolicy & {_config: config}
		}

		if config.podDisruptionBudget.enabled {
			"\(config.metadata.name)-pdb": #PodDisruptionBudget & {_config: config}
		}

		if config.hpa.enabled {
			"\(config.metadata.name)-hpa": #HorizontalPodAutoscaler & {_config: config}
		}

		if config.serviceMonitor.enabled {
			"\(config.metadata.name)-monitor": #ServiceMonitor & {_config: config}
		}
	}
}
