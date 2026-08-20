bundle: {
	apiVersion: "v1alpha1"
	name:       "external-secrets"
	instances: {
		"external-secrets": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "external-secrets"
			values: {
				// The uninstall sweep requires the CRDs to be pruned
				// with the instance.
				crds: keep: false
				// Admission must be load-bearing: the fixture resources
				// are rejected unless the webhook serves with the
				// cert-controller issued certificate.
				webhook: failurePolicy: "Fail"
			}
		}
	}
}
