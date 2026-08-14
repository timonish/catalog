bundle: {
	apiVersion: "v1alpha1"
	name:       "flux-operator"
	instances: {
		"flux-operator": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "flux-system"
			values: {
				// The typed web configuration exercises the immutable
				// Secret rendering and the operator loading it: an
				// invalid document would fail the deployment rollout.
				web: config: authentication: {
					type: "Anonymous"
					anonymous: groups: ["flux-web-viewers"]
				}
			}
		}
	}
}
