bundle: {
	apiVersion: "v1alpha1"
	name:       "cert-manager"
	instances: {
		"cert-manager": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "cert-manager"
			values: {
				// The uninstall sweep requires the CRDs to be pruned
				// with the instance.
				crds: keep: false
			}
		}
	}
}
