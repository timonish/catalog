package config

import (
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Duration is a Go duration string, e.g. `60s`, `5m` or `1h`.
#Duration: string & =~"^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"

// LogLevel is the zap log level of a component.
#LogLevel: *"info" | "debug" | "warn" | "error" | "dpanic" | "panic" | "fatal"

// LogTimeEncoding is the zap timestamp encoding of a component.
#LogTimeEncoding: *"epoch" | "millis" | "nano" | "iso8601" | "rfc3339" | "rfc3339nano"

// MetricsValues configures the Prometheus metrics endpoint of a
// component and its optional metrics Service.
#MetricsValues: {
	// The metrics listener port.
	port: *8080 | int & >0 & <=65535

	// Serve the metrics endpoint over HTTPS from a certificate and key
	// mounted at `certDir` (e.g. through `extraVolumes`).
	secure: {
		enabled:  *false | bool
		certDir:  *"/etc/tls" | string & =~".+"
		certName: *"tls.crt" | string & =~".+"
		keyName:  *"tls.key" | string & =~".+"
	}

	// Protect the metrics endpoint with Kubernetes RBAC authentication
	// and authorization (TokenReview and SubjectAccessReview); requires
	// `secure.enabled`. The module grants the component the required
	// cluster permissions.
	auth: enabled: *false | bool

	// The metrics Service settings. The Service is created when
	// `enabled` is set or when the ServiceMonitor is enabled.
	service: {
		enabled:    *false | bool
		port:       *8080 | int & >0 & <=65535
		clusterIP?: string & =~".+"
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
		annotations?:    timoniv1.#Annotations
		labels?:         timoniv1.#Labels
	}

	_guard: "valid"
	_guard: [
		if auth.enabled && !secure.enabled {
			"metrics.auth.enabled requires metrics.secure.enabled"
		},
		"valid",
	][0]
}

// LeaderElectionValues configures the leader election of a component.
#LeaderElectionValues: {
	// Whether leader election is enabled; defaults to on when the
	// component runs more than one replica.
	enabled: bool

	// The name of the lease object.
	id: string & =~".+"

	// The duration non-leader candidates wait to acquire leadership.
	leaseDuration?: #Duration

	// The duration the acting leader retries refreshing leadership
	// before giving up; must be less than `leaseDuration`.
	renewDeadline?: #Duration

	// The wait between lease acquisition attempts.
	retryPeriod?: #Duration
}

// MetricsSecureArgs renders the HTTPS metrics listener flags shared by
// all components.
#MetricsSecureArgs: {
	#metrics: #MetricsValues
	args: [
		if #metrics.secure.enabled {"--metrics-secure=true"},
		if #metrics.secure.enabled {"--metrics-cert-dir=\(#metrics.secure.certDir)"},
		if #metrics.secure.enabled {"--metrics-cert-name=\(#metrics.secure.certName)"},
		if #metrics.secure.enabled {"--metrics-key-name=\(#metrics.secure.keyName)"},
	]
}

// MetricsAuthRules are the RBAC rules the metrics endpoint
// authentication and authorization requires.
#MetricsAuthRules: [
	{
		apiGroups: ["authentication.k8s.io"]
		resources: ["tokenreviews"]
		verbs: ["create"]
	},
	{
		apiGroups: ["authorization.k8s.io"]
		resources: ["subjectaccessreviews"]
		verbs: ["create"]
	},
]
