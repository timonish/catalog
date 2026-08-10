package config

// ControllerConfiguration is the cert-manager controller configuration
// file schema (controller.config.cert-manager.io/v1alpha1), rendered
// into a ConfigMap and passed to the controller via `--config`.
#ControllerConfiguration: {
	apiVersion: "controller.config.cert-manager.io/v1alpha1"
	kind:       "ControllerConfiguration"

	// A kubeconfig file used to connect to the Kubernetes API server;
	// when unset the in-cluster config is used.
	kubeConfig?: string & =~".+"

	// The maximum queries-per-second and burst of requests sent to the
	// Kubernetes API server.
	kubernetesAPIQPS?:   number & >0 & <=1000000
	kubernetesAPIBurst?: int & >0 & <=1000000

	// Limit the scope of cert-manager to a single namespace; when set,
	// ClusterIssuers are disabled.
	namespace?: string & =~".+"

	// The namespace storing resources owned by cluster-scoped resources
	// such as ClusterIssuer; defaults to the instance namespace.
	clusterResourceNamespace?: string & =~".+"

	// The leader election behaviour. The module's RBAC grants access to
	// leases in the configured namespace.
	leaderElectionConfig: #LeaderElection & {
		// Leader election healthz checks within this timeout period
		// after the lease expires still return healthy.
		healthzTimeout?: #Duration
	}

	// The controllers to enable: `["*"]` enables all,
	// `["foo"]` only foo, `["*", "-foo"]` all but foo.
	controllers?: [...string & =~".+"]

	// Whether issuers or cluster-issuers may draw credentials from the
	// environment, metadata services or local files that are not
	// explicitly configured in the Issuer API object (e.g. EC2 IAM
	// roles via instance metadata).
	issuerAmbientCredentials?:        bool
	clusterIssuerAmbientCredentials?: bool

	// Set the Certificate resource as an owner of its TLS Secret, so
	// the Secret is removed when the Certificate is deleted.
	enableCertificateOwnerRef?: bool

	// Annotation key prefixes copied from Certificate to
	// CertificateRequest and Order; a `-` prefix excludes keys.
	copiedAnnotationPrefixes?: [...string & =~".+"]

	// The number of concurrent workers for each controller.
	numberOfConcurrentWorkers?: int & >0 & <=1000000

	// The maximum number of challenges scheduled as `processing` at once.
	maxConcurrentChallenges: *60 | int & >0 & <=1000000

	// The metrics endpoint listen address; `0` disables the metrics
	// server. The default follows `prometheus.enabled`.
	metricsListenAddress: string & =~".+"

	// TLS settings of the metrics endpoint.
	metricsTLSConfig?: #TLSConfig

	// The healthz endpoint listen address.
	healthzListenAddress: *"0.0.0.0:9403" | string & =~".+"

	// Go profiling endpoint (served at /debug/pprof).
	enablePprof?:  bool
	pprofAddress?: string & =~".+"

	// The logging behaviour of the controller.
	logging: #Logging

	// Feature gates enabling or disabling experimental features.
	featureGates?: #FeatureGates

	// The behaviour of the ingress-shim controller.
	ingressShimConfig?: {
		// Issuer defaults used when an ingress-like resource requests
		// TLS without specifying them.
		defaultIssuerName?:  string & =~".+"
		defaultIssuerKind?:  string & =~".+"
		defaultIssuerGroup?: string & =~".+"

		// The annotations marking an ingress as requesting a
		// certificate.
		defaultAutoCertificateAnnotations?: [...string & =~".+"]

		// Annotations copied from an ingress-like resource to the
		// Certificate it requests.
		extraCertificateAnnotations?: [...string & =~".+"]
	}

	// The behaviour of the ACME HTTP01 challenge solver. The default
	// solver image tracks the upstream release and is set in
	// `versions.cue` by upengine.
	acmeHTTP01Config: {
		solverImage:                  *_defaultSolverImage | string & =~".+"
		solverResourceRequestCPU?:    string & =~".+"
		solverResourceRequestMemory?: string & =~".+"
		solverResourceLimitsCPU?:     string & =~".+"
		solverResourceLimitsMemory?:  string & =~".+"
		solverRunAsNonRoot?:          bool
		solverRuntimeClassName?:      string & =~".+"

		// Custom nameservers for HTTP01 check requests,
		// e.g. `["8.8.8.8:53"]`.
		solverNameservers?: [...string & =~".+"]

		// Extra labels applied to the dynamically created solver
		// resources.
		solverExtraLabels?: {[string]: string}
	}

	// The behaviour of the ACME DNS01 challenge solver.
	acmeDNS01Config?: {
		// Recursive DNS servers as `host:port` or DNS-over-HTTPS
		// endpoints, e.g. `["8.8.8.8:53", "https://1.1.1.1/dns-query"]`.
		recursiveNameservers?: [...string & =~".+"]

		// Only ever query the configured DNS resolvers for the ACME
		// DNS01 self check (for DNS-constrained environments).
		recursiveNameserversOnly?: bool

		// The wait between challenge propagation checks.
		checkRetryPeriod?: #Duration
	}

	// The maximum sizes for PEM-encoded data, in bytes.
	pemSizeLimitsConfig?: {
		maxCertificateSize?: int & >0 & <=2147483647
		maxPrivateKeySize?:  int & >0 & <=2147483647
		maxChainLength?:     int & >0 & <=2147483647
		maxBundleSize?:      int & >0 & <=2147483647
	}

	// The Gateway API integration.
	gatewayAPI?: {
		// Enable the Gateway API integration (the
		// ExperimentalGatewayAPISupport feature gate is enabled by
		// default since v1.15).
		enabled?: bool

		// Enable the ListenerSet controller (requires the ListenerSet
		// feature gate).
		enableListenerSet?: bool

		// Additional Gateway Listener protocol types treated as
		// TLS-capable, e.g. `["DTLS"]`.
		extraProtocols?: [...string & =~".+"]
	}

	// The exponential backoff window applied to failing certificate
	// requests (defaults: 1h minimum, 32h maximum).
	certificateRequestMinimumBackoffDuration?: #Duration
	certificateRequestMaximumBackoffDuration?: #Duration
}
