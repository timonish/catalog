// E2E test bundle applied by `bun upengine/src/main.ts e2e`.
// The module url and version are injected at apply-time from the
// E2E_MODULE_URL and E2E_MODULE_VERSION environment variables.
bundle: {
	apiVersion: "v1alpha1"
	name:       "metrics-server"
	instances: {
		"metrics-server": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "kube-system"
			values: {
				// Kind's kubelet serving certificates are self-signed.
				extraArgs: ["--kubelet-insecure-tls"]
			}
		}
	}
}
