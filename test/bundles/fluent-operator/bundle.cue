bundle: {
	apiVersion: "v1alpha1"
	name:       "fluent-operator"
	instances: {
		"fluent-operator": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "fluent-system"
			values: {
				// Two replicas exercise leader election and its
				// Role/RoleBinding plus the disruption budget. The
				// ServiceMonitor stays off: the monitoring.coreos.com
				// CRDs are not installed in the e2e cluster.
				replicas: 2
			}
		}
	}
}
