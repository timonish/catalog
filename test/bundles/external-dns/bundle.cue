bundle: {
	apiVersion: "v1alpha1"
	name:       "external-dns"
	instances: {
		"external-dns": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "external-dns"
			values: {
				// The credential-free provider used by the upstream test
				// suite; --dry-run additionally keeps it untouched.
				provider: name: "inmemory"
				sources: ["crd"]
				policy:     "sync"
				txtOwnerId: "e2e"
				// React to the DNSEndpoint fixture without waiting a
				// full interval.
				triggerLoopOnEvent: true
				extraArgs: ["--dry-run"]
			}
		}
	}
}
