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
				// The admission webhook needs cert-manager and is
				// exercised manually. The ServiceMonitor proves a CR can
				// be applied in the same run as the CRDs that define it
				// (Timoni v0.31 refreshes the API discovery mid-apply).
				// The feature gate proves the conditional DaemonSet RBAC
				// passes the operator startup check.
				featureGates: PrometheusAgentDaemonSet: true
				networkPolicy: enabled:                 true
				serviceMonitor: enabled:                true
				podDisruptionBudget: {
					enabled:      true
					minAvailable: 1
				}
			}
		}
	}
}
