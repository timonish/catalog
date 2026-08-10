package config

// CAInjectorConfiguration is the cert-manager cainjector configuration
// file schema (cainjector.config.cert-manager.io/v1alpha1), rendered
// into a ConfigMap and passed to the cainjector via `--config`.
#CAInjectorConfiguration: {
	apiVersion: "cainjector.config.cert-manager.io/v1alpha1"
	kind:       "CAInjectorConfiguration"

	// A kubeconfig file used to connect to the Kubernetes API server;
	// when unset the in-cluster config is used.
	kubeConfig?: string & =~".+"

	// Limit the scope of the cainjector to a single namespace.
	namespace?: string & =~".+"

	// Namespaces ignored by the cainjector.
	ignoreNamespaces?: [...string & =~".+"]

	// The leader election behaviour. The module's RBAC grants access to
	// leases in the configured namespace.
	leaderElectionConfig: #LeaderElection

	// The enabled CA data sources.
	enableDataSourceConfig?: {
		// Watch Certificate resources as a CA source (annotation
		// `cert-manager.io/inject-ca-from`).
		certificates?: bool
	}

	// The resource kinds the cainjector injects CA data into.
	enableInjectableConfig?: {
		validatingWebhookConfigurations?: bool
		mutatingWebhookConfigurations?:   bool
		customResourceDefinitions?:       bool
		apiServices?:                     bool
	}

	// Go profiling endpoint (served at /debug/pprof).
	enablePprof?:  bool
	pprofAddress?: string & =~".+"

	// The logging behaviour of the cainjector.
	logging: #Logging

	// Feature gates enabling or disabling experimental features.
	featureGates?: #FeatureGates

	// The metrics endpoint listen address; `0` disables the metrics
	// server. The default follows `prometheus.enabled`.
	metricsListenAddress: string & =~".+"

	// TLS settings of the metrics endpoint.
	metricsTLSConfig?: #TLSConfig
}
