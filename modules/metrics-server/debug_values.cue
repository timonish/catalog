@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable every optional object so that all templates are
// validated against their Kubernetes and CRD schemas.
values: {
	// The default vet covers the hardened profile; flip to platform so
	// both identity branches validate.
	securityProfile:      "platform"
	replicas:             2
	revisionHistoryLimit: 5

	updateStrategy: {
		type: "RollingUpdate"
		rollingUpdate: maxUnavailable: 1
	}

	commonLabels: "app.kubernetes.io/part-of": "monitoring"

	podLabels: "team":                      "platform"
	podAnnotations: "prometheus.io/scrape": "false"

	args: ["--kubelet-insecure-tls"]

	hostNetwork: true

	metrics: enabled: true

	serviceMonitor: {
		enabled: true
		additionalLabels: prometheus: "platform"
		interval:      "30s"
		scrapeTimeout: "5s"
		metricRelabelings: [{
			action: "drop"
			sourceLabels: ["__name__"]
			regex: "go_gc_.*"
		}]
	}

	podDisruptionBudget: {
		enabled:                    true
		minAvailable:               1
		unhealthyPodEvictionPolicy: "AlwaysAllow"
	}

	addonResizer: {
		enabled: true
		nanny: minClusterSize: 50
	}

	tls: {
		type: "cert-manager"
		certManager: {
			duration:    "8760h"
			renewBefore: "720h"
			annotations: "team": "platform"
		}
	}

	apiService: annotations: "team": "platform"

	serviceAccount: {
		annotations: "eks.amazonaws.com/role-arn": "arn:aws:iam::111122223333:role/metrics-server"
		secrets: [{name: "registry-token"}]
	}

	service: {
		type: "NodePort"
		port: 4443
		labels: "kubernetes.io/cluster-service": "true"
	}

	extraVolumes: [{
		name: "extra"
		emptyDir: {}
	}]
	extraVolumeMounts: [{
		name:      "extra"
		mountPath: "/extra"
	}]

	nodeSelector: "kubernetes.io/os": "linux"
	tolerations: [{
		key:      "node-role.kubernetes.io/control-plane"
		operator: "Exists"
		effect:   "NoSchedule"
	}]
	topologySpreadConstraints: [{
		maxSkew:           1
		topologyKey:       "topology.kubernetes.io/zone"
		whenUnsatisfiable: "ScheduleAnyway"
		labelSelector: matchLabels: "app.kubernetes.io/name": "metrics-server"
	}]

	dnsConfig: options: [{
		name:  "ndots"
		value: "2"
	}]

	schedulerName: "default-scheduler"

	deploymentAnnotations: "team": "platform"

	podSecurityContext: fsGroup: 1000

	_mcpu: 200
	_mem:  256
	resources: {
		requests: {
			cpu:    "\(_mcpu)m"
			memory: "\(_mem)Mi"
		}
		limits: memory: "\(_mem*2)Mi"
	}
}
