bundle: {
	apiVersion: "v1alpha1"
	name:       "trust-manager"
	instances: {
		// cert-manager is a hard dependency of trust-manager: it issues
		// the webhook certificate and injects its CA. The published
		// cert-manager module is installed first, and the engine's
		// bundle delete removes it together with the module under test.
		"cert-manager": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/cert-manager"
				version: "latest"
			}
			namespace: "cert-manager"
		}
		"trust-manager": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "trust-manager"
			values: {
				// The Bundle fixture writes the default CAs package to a
				// Secret target as well as a ConfigMap, covering the
				// authorized-secrets RBAC branch.
				secretTargets: {
					enabled: true
					authorizedSecrets: ["e2e"]
				}
			}
		}
	}
}
