package config

// Duration is a Go duration string, e.g. `60s`, `5m` or `1h`.
#Duration: string & =~"^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"

// Logging configures the logging behaviour of a cert-manager component
// (the Kubernetes component-base LoggingConfiguration).
#Logging: {
	// The log format.
	format: *"text" | "json"

	// The log verbosity level (0-6).
	verbosity: *2 | int & >=0 & <=6

	// Per-file-pattern verbosity overrides (text format only).
	vmodule?: [...{
		filePattern: string & =~".+"
		verbosity:   int & >=0 & <=6
	}]

	// The maximum time between log flushes, as a duration string or
	// nanoseconds.
	flushFrequency?: #Duration | int & >=0

	// Format-specific output routing options.
	options?: {
		text?: {
			splitStream?:    bool
			infoBufferSize?: string | int
		}
		json?: {
			splitStream?:    bool
			infoBufferSize?: string | int
		}
	}
}

// LeaderElection configures the leader election of a cert-manager
// component. The namespace holds the leader election leases; the
// module's RBAC grants access to leases in it.
#LeaderElection: {
	// Whether leader election is enabled.
	enabled?: bool

	// The namespace of the leader election leases.
	namespace: *"kube-system" | string & =~".+"

	// The duration non-leader candidates wait to acquire leadership.
	leaseDuration?: #Duration

	// The interval between acting leader renewal attempts.
	renewDeadline?: #Duration

	// The wait between lease acquisition attempts.
	retryPeriod?: #Duration
}

// TLSConfig configures the TLS settings of a component's secure
// listener, served either from certificate files on disk or from a
// dynamically generated self-signed CA (mutually exclusive).
#TLSConfig: {
	// The allowed cipher suites; defaults to the Go cipher suites.
	cipherSuites?: [...string & =~".+"]

	// The minimum TLS version, e.g. `VersionTLS12`.
	minTLSVersion?: string & =~".+"

	// Serve the TLS certificate from files on disk (e.g. mounted from
	// a cert-manager Certificate secret via `volumes`).
	filesystem?: {
		certFile: string & =~".+"
		keyFile:  string & =~".+"
	}

	// Serve dynamically generated leaf certificates signed by a
	// self-signed CA stored in a Kubernetes Secret; at least one DNS
	// name is required.
	dynamic?: {
		secretNamespace: string & =~".+"
		secretName:      string & =~".+"
		dnsNames: [string & =~".+", ...string & =~".+"]
		leafDuration?: #Duration
	}

	_guard: "valid"
	_guard: [
		if filesystem != _|_ && dynamic != _|_ {
			"filesystem and dynamic serving are mutually exclusive"
		},
		"valid",
	][0]
}

// FeatureGates is a map of feature names to booleans enabling or
// disabling experimental features.
#FeatureGates: {[string & =~".+"]: bool}
