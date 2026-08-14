bundle: {
	apiVersion: "v1alpha1"
	name:       "node-exporter"
	instances: {
		"node-exporter": {
			module: {
				url:     string @timoni(runtime:string:E2E_MODULE_URL)
				version: string @timoni(runtime:string:E2E_MODULE_VERSION)
			}
			namespace: "node-exporter"
			values: {
				// The optional objects a first install can carry: the
				// ServiceMonitor and PodMonitor need the Prometheus
				// Operator CRDs and the VerticalPodAutoscaler the
				// autoscaling.k8s.io CRDs of a previous apply (all are
				// exercised manually).
				networkPolicy: enabled: true
			}
		}
	}
}
