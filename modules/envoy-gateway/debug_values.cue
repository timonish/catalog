@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable every optional object so that all templates are
// validated against their Kubernetes and CRD schemas. The default
// (non-debug) vet covers the certgen TLS mode (including the webhook
// CA-patching ClusterRole); these values flip to the cert-manager TLS
// mode, the watched-namespaces RBAC and the GatewayNamespace deploy
// mode extras. The cluster-wide infra-manager variant (GatewayNamespace
// without enumerated namespaces) is exercised with a separate build.
values: {
	// The default vet covers the hardened profile; flip to platform so
	// both identity branches validate.
	securityContextPreset: "platform"
	commonLabels: "app.kubernetes.io/part-of": "ingress"

	crds: keep: true

	config: {
		logging: level: {
			default:       "info"
			"gateway-api": "debug"
		}
		provider: kubernetes: {
			deploy: type: "GatewayNamespace"
			watch: {
				type: "Namespaces"
				namespaces: ["apps", "prod"]
			}
			envoyDeployment: replicas: 2
		}
		telemetry: metrics: prometheus: disable: false
	}

	tls: {
		mode: "cert-manager"
		certManager: {
			caDuration:  "87600h"
			duration:    "8760h"
			renewBefore: "720h"
			annotations: "example.com/cert": "control-plane"
		}
	}

	certgen: {
		annotations: "example.com/job": "certgen"
		podLabels: team:                "platform"
		args: ["--overwrite"]
		resources: requests: {
			cpu:    "10m"
			memory: "32Mi"
		}
		tolerations: [{
			key:      "node-role.kubernetes.io/control-plane"
			operator: "Exists"
			effect:   "NoSchedule"
		}]
		ttlSecondsAfterFinished: 60
	}

	hpa: {
		enabled:     true
		minReplicas: 2
		maxReplicas: 5
		metrics: [{
			type: "Resource"
			resource: {
				name: "cpu"
				target: {
					type:               "Utilization"
					averageUtilization: 80
				}
			}
		}]
		behavior: scaleDown: stabilizationWindowSeconds: 300
	}

	service: {
		type:                "LoadBalancer"
		loadBalancerIP:      "10.0.0.10"
		trafficDistribution: "PreferClose"
		annotations: "example.com/svc": "envoy-gateway"
		labels: "example.com/scope":    "ingress"
		loadBalancerSourceRanges: ["10.0.0.0/8"]
		externalTrafficPolicy: "Local"
	}

	serviceMonitor: {
		enabled: true
		additionalLabels: release:       "prometheus"
		annotations: "example.com/team": "platform"
		interval:      "1m30s"
		scrapeTimeout: "10s"
		honorLabels:   true
		scheme:        "http"
		sampleLimit:   1000
		targetLabels: ["app.kubernetes.io/part-of"]
		metricRelabelings: [{
			action: "labeldrop"
			regex:  "instance"
		}]
	}

	podDisruptionBudget: {
		enabled:                    true
		minAvailable:               1
		unhealthyPodEvictionPolicy: "IfHealthyBudget"
	}

	topologyInjector: annotations: "example.com/webhook": "topology"

	dnsPolicy: "ClusterFirst"
	dnsConfig: options: [{name: "ndots", value: "2"}]
	schedulerName: "default-scheduler"

	wasmCacheVolume: persistentVolumeClaim: claimName: "envoy-gateway-wasm-cache"

	env: [{
		name:  "GOMAXPROCS"
		value: "2"
	}]
	extraVolumes: [{
		name: "tmp"
		emptyDir: {}
	}]
	extraVolumeMounts: [{
		name:      "tmp"
		mountPath: "/tmp"
	}]

	podLabels: team:                      "platform"
	podAnnotations: "example.com/scrape": "true"
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
		labelSelector: matchLabels: "app.kubernetes.io/name": "envoy-gateway"
	}]
	priorityClassName:             "system-cluster-critical"
	terminationGracePeriodSeconds: 30

	strategy: {
		type: "RollingUpdate"
		rollingUpdate: maxUnavailable: 1
	}
	revisionHistoryLimit: 5
	deploymentAnnotations: "example.com/deploy": "envoy-gateway"

	serviceAccount: annotations: "example.com/sa": "envoy-gateway"
}
