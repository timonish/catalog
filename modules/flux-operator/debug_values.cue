@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable every optional object so that all templates are
// validated against their Kubernetes and CRD schemas. The default vet
// covers the operator mode (cluster-admin binding, aggregation roles,
// hardened profile); the debug values flip to the standalone web
// server mode so the web ClusterRole with the fine-grained rules, the
// web configuration Secret and the platform identity branch validate.
values: {
	securityContextPreset: "platform"

	commonLabels: "app.kubernetes.io/part-of": "flux"
	commonAnnotations: "environment":          "test"

	crds: keep: true

	multitenancy: {
		enabled:                    true
		enabledForWorkloadIdentity: true
		defaultServiceAccount:      "flux-tenant"
	}

	reporting: interval: "10m"

	logLevel: "debug"

	web: {
		serverOnly:     true
		serverReplicas: 2
		config: {
			baseURL:  "https://flux.example.com"
			insecure: false
			search: cached: true
			metrics: {
				disabled:       false
				scrapeInterval: "30s"
			}
			userActions: {
				audit: ["*"]
				access: "FineGrained"
			}
			authentication: {
				type: "OAuth2"
				oauth2: {
					provider:     "OIDC"
					clientID:     "flux-web"
					clientSecret: "test-secret"
					scopes: ["openid", "profile", "email", "groups"]
					authURLParams: "prompt": "consent"
					autoLogin: false
					issuerURL: "https://dex.example.com"
					variables: [{
						name:       "username"
						expression: "claims.email"
					}]
					validations: [{
						expression: "variables.username.endsWith(\"@example.com\")"
						message:    "user not part of the organization"
					}]
					profile: name: "claims.name"
					impersonation: {
						username: "variables.username"
						groups:   "claims.groups"
					}
				}
				sessionDuration: "12h"
				userCacheSize:   200
			}
		}
		rbac: {
			createRoles:       true
			createAggregation: true
		}
		ingress: {
			enabled:   true
			className: "nginx"
			hosts: [{
				host: "flux.example.com"
				paths: [{path: "/", pathType: "Prefix"}]
			}]
			tls: [{
				secretName: "flux-web-tls"
				hosts: ["flux.example.com"]
			}]
			annotations: "cert-manager.io/cluster-issuer": "letsencrypt"
			labels: "team":                                "platform"
		}
		httpRoute: {
			enabled: true
			parentRefs: [{
				name:      "gateway"
				namespace: "gateway-system"
			}]
			hostnames: ["flux.example.com"]
			annotations: "team": "platform"
			labels: "team":      "platform"
		}
	}

	marketplace: {
		type:    "aws"
		account: "111122223333"
		license: "license-key"
	}

	apiPriority: {
		enabled: true
		level:   "workload-high"
		extraServiceAccounts: [{
			name:      "kustomize-controller"
			namespace: "flux-system"
		}]
	}

	extraArgs: ["--concurrent=20"]

	env: [{name: "GOMAXPROCS", value: "2"}]

	_mcpu: 500
	_mem:  512
	resources: {
		requests: {
			cpu:    "\(_mcpu)m"
			memory: "\(_mem)Mi"
		}
		limits: memory: "\(_mem*2)Mi"
	}

	startupProbe: {
		httpGet: {
			path: "/healthz"
			port: 8081
		}
		failureThreshold: 30
		periodSeconds:    5
	}

	tmpVolume: emptyDir: medium: "Memory"

	extraVolumes: [{
		name: "extra"
		emptyDir: {}
	}]
	extraVolumeMounts: [{
		name:      "extra"
		mountPath: "/extra"
	}]

	extraContainers: [{
		name:  "sidecar"
		image: "docker.io/library/busybox:latest"
		command: ["sleep", "infinity"]
	}]
	initContainers: [{
		name:  "init"
		image: "docker.io/library/busybox:latest"
		command: ["true"]
	}]

	podLabels: "team":                      "platform"
	podAnnotations: "prometheus.io/scrape": "false"

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
		labelSelector: matchLabels: "app.kubernetes.io/name": "flux-operator"
	}]
	hostAliases: [{
		ip: "127.0.0.1"
		hostnames: ["git.internal"]
	}]
	dnsConfig: options: [{
		name:  "ndots"
		value: "2"
	}]
	dnsPolicy: "ClusterFirstWithHostNet"

	hostNetwork: true

	priorityClassName:             "system-cluster-critical"
	schedulerName:                 "default-scheduler"
	terminationGracePeriodSeconds: 30

	automountServiceAccountToken: true

	strategy: {
		type: "RollingUpdate"
		rollingUpdate: maxUnavailable: 1
	}

	revisionHistoryLimit: 5

	deploymentLabels: "tier":      "control-plane"
	deploymentAnnotations: "team": "platform"

	imagePullSecrets: [{name: "registry-token"}]

	serviceAccount: {
		annotations: "eks.amazonaws.com/role-arn": "arn:aws:iam::111122223333:role/flux-operator"
	}

	service: {
		type:        "NodePort"
		port:        9090
		webPort:     9091
		nodePort:    30090
		webNodePort: 30091
		ipFamilies: ["IPv4", "IPv6"]
		ipFamilyPolicy:        "PreferDualStack"
		externalTrafficPolicy: "Local"
		labels: "kubernetes.io/cluster-service": "true"
		annotations: "team":                     "platform"
	}

	podDisruptionBudget: {
		enabled:                    true
		minAvailable:               1
		unhealthyPodEvictionPolicy: "AlwaysAllow"
	}

	serviceMonitor: {
		enabled: true
		additionalLabels: prometheus: "platform"
		annotations: "team":          "platform"
		interval:      "1m30s"
		scrapeTimeout: "5s"
		honorLabels:   true
		sampleLimit:   1000
		targetLabels: ["app.kubernetes.io/part-of"]
		metricRelabelings: [{
			action: "drop"
			sourceLabels: ["__name__"]
			regex: "go_gc_.*"
		}]
	}
}
