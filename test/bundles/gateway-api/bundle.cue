bundle: {
	apiVersion: "v1alpha1"
	name:       "gateway-api"
	instances: {
		"gateway-api": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "gateway-system"
			values: {
				// The experimental channel is the superset: the shared
				// CRDs with their experimental fields, the x-k8s.io
				// group, and the safe-upgrades policy fresh-install path.
				channel: "experimental"
			}
		}
	}
}
