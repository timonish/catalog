// E2E test bundle applied by `bun upengine/src/main.ts e2e`.
// The module url and version are injected at apply-time from the
// E2E_MODULE_URL and E2E_MODULE_VERSION environment variables.
bundle: {
	apiVersion: "v1alpha1"
	name:       "dex"
	instances: {
		"dex": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "dex"
			values: {
				// The upstream smoke configuration: in-memory state with a
				// local password database. Without the kubernetes storage
				// backend no RBAC is rendered, keeping the uninstall sweep
				// free of runtime-created CRDs.
				config: {
					storage: type: "memory"
					enablePasswordDB: true
				}
			}
		}
	}
}
