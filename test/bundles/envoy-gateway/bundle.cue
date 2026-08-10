bundle: {
	apiVersion: "v1alpha1"
	name:       "envoy-gateway"
	instances: {
		// The Gateway API CRDs are a hard dependency of envoy-gateway;
		// the published gateway-api module is installed first, and the
		// engine's bundle delete removes it together with the module
		// under test.
		"gateway-api": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/gateway-api"
				version: "latest"
			}
			namespace: "envoy-gateway"
		}
		"envoy-gateway": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "envoy-gateway"
			values: {
				// The cert-manager TLS mode, the watched-namespaces RBAC
				// and the GatewayNamespace deploy mode are exercised in
				// the manual matrix; the defaults cover the certgen Job
				// and the topology injector webhook.
				podDisruptionBudget: {
					enabled:      true
					minAvailable: 1
				}
			}
		}
	}
}
