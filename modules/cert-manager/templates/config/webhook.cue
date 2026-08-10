package config

// WebhookConfiguration is the cert-manager webhook configuration file
// schema (webhook.config.cert-manager.io/v1alpha1), rendered into a
// ConfigMap and passed to the webhook via `--config`.
#WebhookConfiguration: {
	apiVersion: "webhook.config.cert-manager.io/v1alpha1"
	kind:       "WebhookConfiguration"

	// The port for secure TLS connections from the Kubernetes API
	// server. The default avoids conflicts with kubelet components and
	// is open in GKE private cluster firewalls.
	securePort: *10250 | int & >0 & <=65535

	// The plaintext port for healthz connections.
	healthzPort: *6080 | int & >0 & <=65535

	// TLS settings of the secure listener. By default the webhook
	// serves dynamically generated leaf certificates signed by a
	// self-signed CA stored in the `<instance>-webhook-ca` Secret;
	// overriding this value replaces the dynamic serving entirely.
	tlsConfig: #TLSConfig

	// A kubeconfig file used to connect to the Kubernetes API server;
	// when unset the in-cluster config is used.
	kubeConfig?: string & =~".+"

	// Go profiling endpoint (served at /debug/pprof).
	enablePprof?:  bool
	pprofAddress?: string & =~".+"

	// The logging behaviour of the webhook.
	logging: #Logging

	// Feature gates enabling or disabling experimental features.
	featureGates?: #FeatureGates

	// The metrics endpoint listen address; `0` disables the metrics
	// server. The default follows `prometheus.enabled`.
	metricsListenAddress: string & =~".+"

	// TLS settings of the metrics endpoint.
	metricsTLSConfig?: #TLSConfig

	// Verify the client certificates of requests made to the webhook
	// server against the CA at `clientCAPath`, accepting the subject
	// names in `clientCertificateSubjects`.
	enableClientVerification?: bool
	clientCAPath?:             string & =~".+"
	clientCertificateSubjects?: [...string & =~".+"]
}
