@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable every optional object so that all templates are
// validated against their Kubernetes and CRD schemas. The default
// (non-debug) vet covers the Deployment and ClusterRole branches, so
// these values flip to the autosharding StatefulSet and the
// namespaced Roles.
values: {
	// The default vet covers the hardened profile; flip to platform so
	// both identity branches validate.
	securityProfile: "platform"
	commonLabels: "app.kubernetes.io/part-of": "monitoring"

	replicas: 2
	autosharding: enabled: true

	collectors: [
		"certificatesigningrequests",
		"clusterrolebindings",
		"clusterroles",
		"configmaps",
		"cronjobs",
		"daemonsets",
		"deployments",
		"endpoints",
		"endpointslices",
		"horizontalpodautoscalers",
		"ingressclasses",
		"ingresses",
		"jobs",
		"leases",
		"limitranges",
		"mutatingwebhookconfigurations",
		"namespaces",
		"networkpolicies",
		"nodes",
		"persistentvolumeclaims",
		"persistentvolumes",
		"poddisruptionbudgets",
		"pods",
		"replicasets",
		"replicationcontrollers",
		"resourcequotas",
		"rolebindings",
		"roles",
		"secrets",
		"serviceaccounts",
		"services",
		"statefulsets",
		"storageclasses",
		"validatingwebhookconfigurations",
		"volumeattachments",
	]

	metricAllowlist: ["kube_node_info", "kube_pod_.*"]
	metricLabelsAllowlist: ["pods=[app.kubernetes.io/name]", "namespaces=[*]"]
	metricAnnotationsAllowList: ["pods=[example.com/team]"]

	namespaces: ["monitoring", "kube-system"]
	namespacesDenylist: ["kube-system"]

	authFilter: enabled: true

	customResourceState: {
		enabled: true
		config: spec: resources: [{
			groupVersionKind: {
				group:   "cert-manager.io"
				version: "v1"
				kind:    "Certificate"
			}
			labelsFromPath: {
				name: ["metadata", "name"]
				namespace: ["metadata", "namespace"]
			}
			metrics: [{
				name: "certificate_status"
				help: "Certificate Ready condition"
				each: {
					type: "Gauge"
					gauge: {
						path: ["status", "conditions"]
						labelsFromPath: condition: ["type"]
						valueFrom: ["status"]
					}
				}
			}]
		}]
	}

	kubeconfigSecret: name: "remote-cluster-kubeconfig"

	selfMonitor: {
		enabled:       true
		telemetryHost: "0.0.0.0"
		telemetryPort: 8082
	}

	extraArgs: ["--enable-gzip-encoding"]

	env: [{name: "GOMAXPROCS", value: "1"}]

	imagePullSecrets: [{name: "regcred"}]

	startupProbe: failureThreshold: 5

	extraVolumes: [{
		name: "tmp"
		emptyDir: {}
	}]
	extraVolumeMounts: [{
		name:      "tmp"
		mountPath: "/tmp"
	}]
	extraContainers: [{
		name:  "sidecar"
		image: "registry.k8s.io/pause:3.10"
	}]
	initContainers: [{
		name:  "init"
		image: "registry.k8s.io/pause:3.10"
	}]

	podLabels: "team":                "platform"
	podAnnotations: "team":           "platform"
	workloadLabels: "tier":           "monitoring"
	workloadAnnotations: "team":      "platform"
	nodeSelector: "kubernetes.io/os": "linux"
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
		labelSelector: matchLabels: "app.kubernetes.io/name": "kube-state-metrics"
	}]
	schedulerName: "default-scheduler"
	dnsConfig: options: [{name: "ndots", value: "2"}]
	priorityClassName:             "system-cluster-critical"
	terminationGracePeriodSeconds: 30
	hostUsers:                     true

	revisionHistoryLimit: 5

	serviceAccount: {
		annotations: "team": "platform"
		imagePullSecrets: [{name: "regcred"}]
	}

	rbac: {
		useClusterRole: false
		extraRules: [{
			apiGroups: ["cert-manager.io"]
			resources: ["certificates"]
			verbs: ["list", "watch"]
		}]
	}

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
		additionalLabels: "release":                "e2e"
		annotations: "team":                        "platform"
		selectorOverride: "app.kubernetes.io/name": "kube-state-metrics"
		jobLabel: "app.kubernetes.io/instance"
		targetLabels: ["cluster"]
		podTargetLabels: ["pod"]
		namespaceSelector: ["monitoring"]
		sampleLimit:           1000
		targetLimit:           10
		labelLimit:            64
		labelNameLengthLimit:  256
		labelValueLengthLimit: 1024
		http: {
			interval:      "30s"
			scrapeTimeout: "10s"
			proxyUrl:      "http://proxy.example.com:8080"
			enableHttp2:   true
			honorLabels:   true
			scheme:        "http"
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
		metrics: {
			interval:      "1m"
			scrapeTimeout: "30s"
			honorLabels:   true
		}
	}

	networkPolicy: enabled: true
}
