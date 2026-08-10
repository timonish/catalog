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
				// The optional objects a first install can carry: the
				// admission webhook needs cert-manager and the
				// ServiceMonitor needs the CRDs of a previous apply
				// (both are exercised manually). The feature gate proves
				// the conditional DaemonSet RBAC passes the operator
				// startup check.
				featureGates: PrometheusAgentDaemonSet: true
				networkPolicy: enabled:                 true
				podDisruptionBudget: {
					enabled:      true
					minAvailable: 1
				}
			}
		}
	}
}
