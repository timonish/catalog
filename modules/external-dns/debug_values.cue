@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable every optional object so that all templates are
// validated against their Kubernetes and CRD schemas. The namespaced
// scope is used here because the cluster-scoped RBAC branch is already
// validated by the default `timoni build` guard; the rules themselves
// are shared between both branches.
values: {
	replicas:             1
	revisionHistoryLimit: 5

	strategy: type: "RollingUpdate"

	commonLabels: "app.kubernetes.io/part-of": "dns"

	podLabels: "team":                      "platform"
	podAnnotations: "prometheus.io/scrape": "false"
	deploymentAnnotations: "team":          "platform"

	provider: {
		name: "webhook"
		webhook: {
			image: {
				repository: "ghcr.io/example/external-dns-webhook"
				tag:        "v1.0.0"
			}
			env: [{
				name:  "LOG_LEVEL"
				value: "debug"
			}]
			args: ["--read-timeout=5s"]
			extraVolumeMounts: [{
				name:      "webhook-tmp"
				mountPath: "/tmp"
			}]
			resources: {
				requests: {
					cpu:    "10m"
					memory: "32Mi"
				}
			}
			securityContext: readOnlyRootFilesystem: true
			service: port:                           8888
			serviceMonitor: {
				interval:      "30s"
				scrapeTimeout: "5s"
			}
		}
	}

	logLevel:           "debug"
	logFormat:          "json"
	interval:           "2m"
	triggerLoopOnEvent: true

	sources: ["service", "ingress", "crd", "node", "pod",
		"gateway-httproute", "gateway-grpcroute",
		"istio-gateway", "traefik-proxy", "openshift-route"]
	policy:     "sync"
	registry:   "txt"
	txtOwnerId: "debug"
	txtPrefix:  "xdns-"

	// Namespaced with gateway sources and no gatewayNamespace: renders
	// the Role/RoleBinding pair plus the namespaces ClusterRole/Binding.
	namespaced:                true
	sourceNamespace:           "apps"
	enableGatewayListenerSets: true

	domainFilters: ["example.com"]
	excludeDomains: ["internal.example.com"]
	labelFilter:      "team=platform"
	annotationFilter: "external-dns.alpha.kubernetes.io/include=true"
	annotationPrefix: "external-dns.alpha.kubernetes.io/"
	managedRecordTypes: ["A", "AAAA", "CNAME", "TXT"]

	extraArgs: ["--dry-run"]

	env: [{
		name: "CF_API_TOKEN"
		valueFrom: secretKeyRef: {
			name: "cloudflare-api-token"
			key:  "token"
		}
	}]

	_mcpu: 100
	_mem:  128
	resources: {
		requests: {
			cpu:    "\(_mcpu)m"
			memory: "\(_mem)Mi"
		}
		limits: memory: "\(_mem*2)Mi"
	}

	extraVolumes: [{
		name: "extra"
		emptyDir: {}
	}]
	extraVolumeMounts: [{
		name:      "extra"
		mountPath: "/extra"
	}]

	initContainers: [{
		name:  "init"
		image: "ghcr.io/example/init:v1.0.0"
	}]
	extraContainers: [{
		name:  "sidecar"
		image: "ghcr.io/example/sidecar:v1.0.0"
	}]

	imagePullSecrets: [{name: "registry-token"}]

	nodeSelector: "kubernetes.io/os": "linux"
	tolerations: [{
		key:      "node-role.kubernetes.io/control-plane"
		operator: "Exists"
		effect:   "NoSchedule"
	}]
	affinity: {
		nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
			matchExpressions: [{
				key:      "kubernetes.io/os"
				operator: "In"
				values: ["linux"]
			}]
		}]
		// No label selectors: validates the default selector injection.
		podAntiAffinity: {
			requiredDuringSchedulingIgnoredDuringExecution: [{
				topologyKey: "kubernetes.io/hostname"
			}]
			preferredDuringSchedulingIgnoredDuringExecution: [{
				weight: 100
				podAffinityTerm: topologyKey: "topology.kubernetes.io/zone"
			}]
		}
	}
	topologySpreadConstraints: [{
		maxSkew:           1
		topologyKey:       "topology.kubernetes.io/zone"
		whenUnsatisfiable: "ScheduleAnyway"
	}]

	dnsPolicy: "ClusterFirst"
	dnsConfig: options: [{
		name:  "ndots"
		value: "2"
	}]
	priorityClassName:             "system-cluster-critical"
	terminationGracePeriodSeconds: 30
	shareProcessNamespace:         true

	podSecurityContext: fsGroup: 65534

	serviceAccount: {
		labels: "team":                            "platform"
		annotations: "eks.amazonaws.com/role-arn": "arn:aws:iam::111122223333:role/external-dns"
		automountServiceAccountToken: true
	}

	rbac: additionalPermissions: [{
		apiGroups: [""]
		resources: ["endpoints"]
		verbs: ["get", "watch", "list"]
	}]

	service: {
		port: 8080
		annotations: "team": "platform"
		ipFamilies: ["IPv4"]
		ipFamilyPolicy: "SingleStack"
	}

	serviceMonitor: {
		enabled:   true
		namespace: "monitoring"
		additionalLabels: prometheus: "platform"
		annotations: "team":          "platform"
		interval:      "30s"
		scrapeTimeout: "5s"
		scheme:        "http"
		metricRelabelings: [{
			action: "drop"
			sourceLabels: ["__name__"]
			regex: "go_gc_.*"
		}]
		relabelings: [{
			action: "labeldrop"
			regex:  "pod"
		}]
		targetLabels: ["team"]
	}
}
