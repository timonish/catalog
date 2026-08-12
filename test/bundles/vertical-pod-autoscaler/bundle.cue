bundle: {
	apiVersion: "v1alpha1"
	name:       "vertical-pod-autoscaler"
	instances: {
		// cert-manager is a hard dependency of the module's default
		// webhook TLS mode: it issues the serving certificate and
		// injects its CA into the webhook configuration. The published
		// module is installed first, and the engine's bundle delete
		// removes it together with the module under test.
		"cert-manager": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/cert-manager"
				version: "latest"
			}
			namespace: "cert-manager"
		}
		// The recommender consumes the resource Metrics API; the
		// published metrics-server module provides it on the kind
		// cluster.
		"metrics-server": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/metrics-server"
				version: "latest"
			}
			namespace: "kube-system"
			values: {
				// Kind's kubelet serving certificates are self-signed.
				extraArgs: ["--kubelet-insecure-tls"]
			}
		}
		"vertical-pod-autoscaler": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "vertical-pod-autoscaler"
			values: {
				// Fail closed so a broken webhook certificate chain
				// fails the fixture apply instead of being silently
				// bypassed.
				admissionController: mutatingWebhookConfiguration: failurePolicy: "Fail"
			}
		}
	}
}
