@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable every optional object so that all templates are
// validated against their Kubernetes and CRD schemas. The default
// (non-debug) vet covers the hardened preset, the host network and
// the all-interfaces listener, so these values flip to the platform
// preset, the pod network and the node-address listener.
values: {
	securityContextPreset: "platform"
	commonLabels: "app.kubernetes.io/part-of": "monitoring"

	hostNetwork: false
	hostIPC:     true
	hostUsers:   true
	hostRootFsMount: mountPropagation: "None"
	hostProcFsMount: mountPropagation: "HostToContainer"
	hostSysFsMount: mountPropagation:  "HostToContainer"
	listenOnAllInterfaces: false

	extraArgs: ["--collector.textfile.directory=/run/prometheus"]
	env: [{name: "GOMAXPROCS", value: "1"}]
	extraVolumes: [{
		name: "textfile"
		emptyDir: medium: "Memory"
	}]
	extraVolumeMounts: [{
		name:      "textfile"
		mountPath: "/run/prometheus"
		readOnly:  true
	}]
	extraContainers: [{
		name:  "textfile-writer"
		image: "registry.k8s.io/pause:3.10"
	}]
	initContainers: [{
		name:  "init"
		image: "registry.k8s.io/pause:3.10"
	}]
	resources: {
		requests: {cpu: "10m", memory: "32Mi"}
		limits: {cpu: "100m", memory: "64Mi"}
	}
	terminationMessagePath:   "/dev/termination-log"
	terminationMessagePolicy: "FallbackToLogsOnError"

	imagePullSecrets: [{name: "regcred"}]

	podLabels: "team": "platform"
	podAnnotations: {
		"cluster-autoscaler.kubernetes.io/safe-to-evict": "true"
		"team":                                           "platform"
	}
	nodeSelector: {
		"kubernetes.io/os":   "linux"
		"kubernetes.io/arch": "amd64"
	}
	tolerations: [{operator: "Exists"}]
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
		labelSelector: matchLabels: "app.kubernetes.io/name": "node-exporter"
	}]
	dnsConfig: options: [{name: "ndots", value: "2"}]
	priorityClassName:             "system-node-critical"
	schedulerName:                 "default-scheduler"
	terminationGracePeriodSeconds: 30

	strategy: {
		type: "RollingUpdate"
		rollingUpdate: maxUnavailable: "10%"
	}
	revisionHistoryLimit: 5
	daemonsetLabels: "tier":      "monitoring"
	daemonsetAnnotations: "team": "platform"

	automountServiceAccountToken: true
	serviceAccount: {
		labels: "team":      "platform"
		annotations: "team": "platform"
		imagePullSecrets: [{name: "regcred"}]
	}

	service: {
		type:       "NodePort"
		nodePort:   30910
		port:       9101
		targetPort: 9102
		annotations: "team": "platform"
		labels: "team":      "platform"
		ipFamilies: ["IPv4"]
		ipFamilyPolicy:        "SingleStack"
		externalTrafficPolicy: "Local"
		internalTrafficPolicy: "Cluster"
	}
	endpoints: ["192.168.1.10", "192.168.1.11"]

	serviceMonitor: {
		enabled: true
		additionalLabels: "release": "e2e"
		annotations: "team":         "platform"
		jobLabel: "app.kubernetes.io/instance"
		targetLabels: ["cluster"]
		podTargetLabels: ["pod"]
		sampleLimit:           1000
		targetLimit:           10
		labelLimit:            64
		labelNameLengthLimit:  256
		labelValueLengthLimit: 1024
		interval:              "30s"
		scrapeTimeout:         "10s"
		honorLabels:           true
		enableHttp2:           true
		scheme:                "http"
		proxyUrl:              "http://proxy.example.com:8080"
		basicAuth: {
			username: {name: "scrape-creds", key: "username"}
			password: {name: "scrape-creds", key: "password"}
		}
		attachMetadata: node: true
		metricRelabelings: [{
			action: "labeldrop"
			regex:  "pod_template_hash"
		}]
		relabelings: [{
			action: "replace"
			sourceLabels: ["__meta_kubernetes_pod_node_name"]
			targetLabel: "instance"
		}]
	}

	podMonitor: {
		enabled: true
		additionalLabels: "release": "e2e"
		annotations: "team":         "platform"
		jobLabel: "app.kubernetes.io/instance"
		podTargetLabels: ["pod"]
		sampleLimit: 1000
		path:        "/metrics"
		params: collect: ["cpu"]
		honorTimestamps: false
		filterRunning:   false
		followRedirects: true
		enableHttp2:     true
		interval:        "30s"
		scrapeTimeout:   "10s"
		basicAuth: {
			username: {name: "scrape-creds", key: "username"}
			password: {name: "scrape-creds", key: "password"}
		}
		authorization: credentials: {name: "scrape-token", key: "token"}
		attachMetadata: node: true
	}

	networkPolicy: {
		enabled: true
		ingress: [{
			from: [{namespaceSelector: matchLabels: "kubernetes.io/metadata.name": "monitoring"}]
			ports: [{port: 9102, protocol: "TCP"}]
		}]
		egress: [{
			ports: [{port: 53, protocol: "UDP"}]
		}]
	}

	verticalPodAutoscaler: {
		enabled: true
		recommenders: [{name: "custom-recommender"}]
		controlledResources: ["cpu", "memory"]
		controlledValues: "RequestsAndLimits"
		maxAllowed: {cpu: "200m", memory: "100Mi"}
		minAllowed: {cpu: "20m", memory: "30Mi"}
		updatePolicy: {
			minReplicas: 1
			updateMode:  "Auto"
		}
	}
}
