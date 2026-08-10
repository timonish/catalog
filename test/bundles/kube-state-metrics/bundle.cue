bundle: {
	apiVersion: "v1alpha1"
	name:       "kube-state-metrics"
	instances: {
		"kube-state-metrics": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "kube-state-metrics"
			values: {
				// The optional objects a first install can carry: the
				// ServiceMonitor needs the Prometheus Operator CRDs of a
				// previous apply, the auth filter would reject the
				// unauthenticated probe Job and customResourceState needs
				// a CRD to point at (all are exercised manually).
				selfMonitor: enabled:   true
				networkPolicy: enabled: true
				podDisruptionBudget: {
					enabled:      true
					minAvailable: 1
				}
			}
		}
	}
}
