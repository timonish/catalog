@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable every optional object so that all templates are
// validated against their Kubernetes and CRD schemas.
values: {
	// The default vet covers the hardened profile; flip to platform so
	// both identity branches validate.
	securityContextPreset: "platform"
	replicas:              2
	revisionHistoryLimit:  5

	strategy: {
		type: "RollingUpdate"
		rollingUpdate: maxUnavailable: 1
	}

	commonLabels: "app.kubernetes.io/part-of": "sso"

	podLabels: "team":                      "platform"
	podAnnotations: "prometheus.io/scrape": "false"

	config: {
		issuer: "https://dex.example.com"
		storage: {
			type: "kubernetes"
			config: crdHandling: "ensure"
		}
		web: {
			tlsCert: "/etc/dex/tls/tls.crt"
			tlsKey:  "/etc/dex/tls/tls.key"
			headers: "X-Frame-Options": "DENY"
			allowedOrigins: ["https://app.example.com"]
			clientRemoteIP: {
				header: "X-Forwarded-For"
				trustedProxies: ["10.0.0.0/8"]
			}
		}
		telemetry: enableProfiling: false
		grpc: reflection:           true
		oauth2: {
			skipApprovalScreen: true
			responseTypes: ["code"]
		}
		expiry: {
			idTokens: "24h"
			refreshTokens: validIfNotUsedFor: "2160h"
		}
		logger: {
			level:  "debug"
			format: "json"
		}
		frontend: {
			logoURL: "https://example.com/logo.png"
			theme:   "dark"
		}
		connectors: [{
			type: "github"
			id:   "github"
			name: "GitHub"
			config: {
				clientID:     "$GITHUB_CLIENT_ID"
				clientSecret: "$GITHUB_CLIENT_SECRET"
				redirectURI:  "https://dex.example.com/callback"
			}
		}]
		staticClients: [{
			id:        "example-app"
			name:      "Example App"
			secretEnv: "EXAMPLE_APP_SECRET"
			redirectURIs: ["https://app.example.com/callback"]
		}]
		staticPasswords: [{
			email:    "admin@example.com"
			hash:     "$2a$10$2b2cU8CPhOTaGrs1HRQuAueS7JTT5ZHsHSzYiFPm1leZck7Mc8T4W"
			username: "admin"
			userID:   "08a8684b-db88-4b73-90a9-3cd1661f5466"
		}]
	}

	extraArgs: ["--grpc-reflection"]

	env: [{name: "DEX_EXPAND_ENV", value: "true"}]
	envFrom: [{
		secretRef: name: "dex-oidc-secrets"
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

	terminationGracePeriodSeconds: 30

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

	podDisruptionBudget: {
		enabled:                    true
		minAvailable:               1
		unhealthyPodEvictionPolicy: "AlwaysAllow"
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
	}

	ingress: {
		enabled:   true
		className: "nginx"
		annotations: "cert-manager.io/cluster-issuer": "letsencrypt"
		hosts: [{
			host: "dex.example.com"
			paths: [{path: "/", pathType: "Prefix"}]
		}]
		tls: [{
			secretName: "dex-ingress-tls"
			hosts: ["dex.example.com"]
		}]
	}

	httpRoute: {
		enabled: true
		parentRefs: [{
			name:      "gateway"
			namespace: "gateway-system"
		}]
		hostnames: ["dex.example.com"]
		rules: [{
			matches: [{path: {type: "PathPrefix", value: "/"}}]
			filters: [{
				type: "RequestHeaderModifier"
				requestHeaderModifier: set: [{
					name:  "X-Forwarded-Proto"
					value: "https"
				}]
			}]
		}]
	}

	networkPolicy: {
		enabled: true
		egress: [{
			to: [{
				namespaceSelector: matchLabels: "kubernetes.io/metadata.name": "kube-system"
			}]
			ports: [{port: 53, protocol: "UDP"}]
		}]
	}

	rbac: extraRules: [{
		apiGroups: [""]
		resources: ["secrets"]
		verbs: ["get"]
	}]

	serviceAccount: {
		annotations: "eks.amazonaws.com/role-arn": "arn:aws:iam::111122223333:role/dex"
	}

	service: {
		type: "NodePort"
		port: 80
		labels: "kubernetes.io/cluster-service": "true"
		nodePort:      30556
		httpsNodePort: 30554
		grpcNodePort:  30557
		ipFamilies: ["IPv4", "IPv6"]
		ipFamilyPolicy:        "PreferDualStack"
		externalTrafficPolicy: "Local"
	}

	extraVolumes: [{
		name: "tls"
		secret: secretName: "dex-web-tls"
	}]
	extraVolumeMounts: [{
		name:      "tls"
		mountPath: "/etc/dex/tls"
		readOnly:  true
	}]

	hostAliases: [{
		ip: "10.0.0.10"
		hostnames: ["idp.internal"]
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
		labelSelector: matchLabels: "app.kubernetes.io/name": "dex"
	}]

	dnsConfig: options: [{
		name:  "ndots"
		value: "2"
	}]

	priorityClassName: "system-cluster-critical"
	schedulerName:     "default-scheduler"

	deploymentAnnotations: "team": "platform"

	podSecurityContext: fsGroup: 1001

	startupProbe: {
		httpGet: {
			path: "/healthz/live"
			port: "telemetry"
		}
		failureThreshold: 30
		periodSeconds:    2
	}

	_mcpu: 100
	_mem:  128
	resources: {
		requests: {
			cpu:    "\(_mcpu)m"
			memory: "\(_mem)Mi"
		}
		limits: memory: "\(_mem*2)Mi"
	}
}
