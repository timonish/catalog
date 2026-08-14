@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable every optional object so that all templates are
// validated against their Kubernetes and CRD schemas.
values: {
	// The default vet covers the hardened profile; flip to platform so
	// both identity branches validate.
	securityContextPreset: "platform"
	commonLabels: "app.kubernetes.io/part-of": "logging"

	crds: keep: true

	// The docker runtime flips the container log path; the containerd
	// default is covered by the plain vet.
	containerRuntime: "docker"

	// Two replicas enable leader election and the disruption budget.
	replicas: 2

	disableComponentControllers: "fluentd"
	watchNamespaces: ["fluent-system", "kube-system"]

	extraArgs: ["--zap-log-level=debug"]
	env: [{name: "GOGC", value: "50"}]

	imagePullSecrets: [{name: "regcred"}]

	podLabels: "team":                      "platform"
	podAnnotations: "prometheus.io/scrape": "false"
	deploymentAnnotations: "team":          "platform"
	nodeSelector: "kubernetes.io/os":       "linux"
	tolerations: [{
		key:      "node-role.kubernetes.io/control-plane"
		operator: "Exists"
		effect:   "NoSchedule"
	}]
	affinity: nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
		matchExpressions: [{
			key:      "kubernetes.io/os"
			operator: "In"
			values: ["linux"]
		}]
	}]
	topologySpreadConstraints: [{
		maxSkew:           1
		topologyKey:       "topology.kubernetes.io/zone"
		whenUnsatisfiable: "ScheduleAnyway"
		labelSelector: matchLabels: "app.kubernetes.io/name": "fluent-operator"
	}]
	dnsPolicy: "ClusterFirst"
	dnsConfig: options: [{name: "ndots", value: "2"}]
	priorityClassName:             "system-cluster-critical"
	schedulerName:                 "default-scheduler"
	terminationGracePeriodSeconds: 30

	strategy: {
		type: "RollingUpdate"
		rollingUpdate: maxUnavailable: 1
	}
	revisionHistoryLimit: 5

	extraVolumes: [{
		name: "tmp"
		emptyDir: {}
	}]
	extraVolumeMounts: [{
		name:      "tmp"
		mountPath: "/tmp"
	}]

	serviceAccount: {
		labels: "team":      "platform"
		annotations: "team": "platform"
	}

	rbac: extraRules: [{
		apiGroups: [""]
		resources: ["nodes"]
		verbs: ["get", "list", "watch"]
	}]

	service: {
		annotations: "team": "platform"
		labels: "team":      "platform"
		ipFamilies: ["IPv4"]
		ipFamilyPolicy: "SingleStack"
	}

	podDisruptionBudget: {
		enabled:                    true
		minAvailable:               1
		unhealthyPodEvictionPolicy: "AlwaysAllow"
	}

	serviceMonitor: {
		enabled: true
		additionalLabels: "release": "e2e"
		annotations: "team":         "platform"
		interval:      "1m30s"
		scrapeTimeout: "30s"
		honorLabels:   true
		tlsConfig: insecureSkipVerify: true
		targetLabels: ["app.kubernetes.io/part-of"]
		sampleLimit:           1000
		targetLimit:           10
		labelLimit:            64
		labelNameLengthLimit:  256
		labelValueLengthLimit: 1024
		metricRelabelings: [{
			action: "labeldrop"
			regex:  "pod_template_hash"
		}]
		relabelings: [{
			action: "replace"
			sourceLabels: ["__meta_kubernetes_pod_node_name"]
			targetLabel: "node"
		}]
	}
}
