bundle: {
	apiVersion: "v1alpha1"
	name:       "prometheus-operator"
	instances: {
		"prometheus-operator": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "monitoring"
			values: {
				// The optional objects without external dependencies; the
				// admission webhook needs cert-manager and is exercised
				// manually. The feature gate proves the conditional
				// DaemonSet RBAC passes the operator startup check.
				featureGates: PrometheusAgentDaemonSet: true
				serviceMonitor: enabled:                true
				networkPolicy: enabled:                 true
				podDisruptionBudget: {
					enabled:      true
					minAvailable: 1
				}
			}
		}
	}
}
