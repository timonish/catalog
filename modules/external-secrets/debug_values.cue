// Debug values for `timoni mod vet --debug`: every optional object is
// enabled and every optional field is exercised so all templates are
// validated against their schemas. The cert-manager and existingSecret
// TLS modes replace the cert-controller and are validated with
// `timoni build` in the e2e workflow instead.

@if(debug)

package main

values: {
	// The default vet covers the hardened profile; flip to platform so
	// both identity branches validate.
	securityContextPreset: "platform"
	commonLabels: "app.kubernetes.io/part-of": "external-secrets"

	crds: {
		install: true
		keep:    true
	}

	imagePullSecrets: [{name: "regcred"}]

	rbac: {
		create:                    true
		aggregateClusterRoles:     true
		serviceAccountTokenCreate: true
		serviceBindings:           true
		openshiftFinalizers:       true
		systemAuthDelegator:       true
		extraRules: [{
			apiGroups: [""]
			resources: ["pods"]
			verbs: ["get", "list"]
		}]
	}

	enableHTTP2: true

	serviceMonitor: {
		enabled:       true
		interval:      "1m30s"
		scrapeTimeout: "10s"
		honorLabels:   true
		additionalLabels: release:       "kube-prometheus-stack"
		annotations: "example.com/team": "platform"
		sampleLimit: 1000
		targetLabels: ["app.kubernetes.io/part-of"]
		metricRelabelings: [{
			action: "labeldrop"
			regex:  "pod_template_hash"
		}]
	}

	controller: {
		replicas:             2
		revisionHistoryLimit: 5
		strategy: type: "RollingUpdate"
		leaderElection: {
			enabled:       true
			id:            "external-secrets-controller"
			leaseDuration: "60s"
			renewDeadline: "40s"
			retryPeriod:   "15s"
		}
		controllerClass:      "default"
		concurrent:           4
		storeRequeueInterval: "10m"
		extendedMetricLabels: true
		reconcilers: clusterGenerator: true
		genericTargets: {
			enabled: true
			resources: [{
				apiGroup: "argoproj.io"
				resources: ["applications"]
				verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
			}]
		}
		vault: {
			enableTokenCache: true
			tokenCacheSize:   1024
		}
		logLevel:        "debug"
		logTimeEncoding: "iso8601"
		metrics: {
			port: 8080
			secure: {
				enabled: true
				certDir: "/etc/metrics-tls"
			}
			auth: enabled: true
			service: {
				enabled: true
				port:    8080
				annotations: "example.com/metrics": "true"
				labels: "example.com/scope":        "secrets"
				ipFamilyPolicy: "SingleStack"
				ipFamilies: ["IPv4"]
			}
		}
		healthPort: 8082
		resources: {
			requests: {
				cpu:    "10m"
				memory: "64Mi"
			}
			limits: memory: "256Mi"
		}
		env: [{name: "HTTPS_PROXY", value: "http://proxy.example.com:3128"}]
		extraArgs: ["--client-qps=50"]
		extraVolumes: [{name: "metrics-tls", secret: secretName: "metrics-tls"}]
		extraVolumeMounts: [{name: "metrics-tls", mountPath: "/etc/metrics-tls", readOnly: true}]
		initContainers: [{name: "init", image: "busybox", command: ["true"]}]
		extraContainers: [{name: "sidecar", image: "busybox", command: ["sleep", "infinity"]}]
		podLabels: "example.com/scope":             "secrets"
		podAnnotations: "example.com/scrape":       "true"
		deploymentAnnotations: "example.com/owner": "platform"
		priorityClassName:             "system-cluster-critical"
		schedulerName:                 "default-scheduler"
		terminationGracePeriodSeconds: 30
		automountServiceAccountToken:  true
		hostAliases: [{ip: "127.0.0.1", hostnames: ["vault.local"]}]
		dnsPolicy: "ClusterFirst"
		dnsConfig: options: [{name: "ndots", value: "1"}]
		tolerations: [{key: "node-role.kubernetes.io/control-plane", operator: "Exists", effect: "NoSchedule"}]
		affinity: nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
			matchExpressions: [{
				key:      "kubernetes.io/os"
				operator: "In"
				values: ["linux"]
			}]
		}]
		topologySpreadConstraints: [{
			maxSkew:           1
			topologyKey:       "kubernetes.io/hostname"
			whenUnsatisfiable: "ScheduleAnyway"
			labelSelector: matchLabels: "app.kubernetes.io/component": "controller"
		}]
		serviceAccount: {
			create: true
			labels: "example.com/scope":               "secrets"
			annotations: "eks.amazonaws.com/role-arn": "arn:aws:iam::111122223333:role/external-secrets"
		}
		podDisruptionBudget: {
			enabled:                    true
			minAvailable:               1
			unhealthyPodEvictionPolicy: "AlwaysAllow"
		}
		networkPolicy: enabled: true
	}

	webhook: {
		replicas:          2
		port:              10250
		healthPort:        8081
		certCheckInterval: "10m"
		lookaheadInterval: "24h"
		failurePolicy:     "Fail"
		timeoutSeconds:    10
		annotations: "example.com/audit": "true"
		tls: {
			type:       "cert-controller"
			secretName: "external-secrets-webhook"
		}
		metrics: {
			secure: enabled: true
			auth: enabled:   true
			service: {
				enabled: true
				port:    8080
			}
		}
		extraVolumes: [{name: "metrics-tls", secret: secretName: "metrics-tls"}]
		extraVolumeMounts: [{name: "metrics-tls", mountPath: "/etc/tls", readOnly: true}]
		resources: requests: {
			cpu:    "10m"
			memory: "32Mi"
		}
		service: {
			type: "ClusterIP"
			port: 443
			annotations: "example.com/webhook": "true"
			ipFamilyPolicy: "SingleStack"
			ipFamilies: ["IPv4"]
		}
		startupProbe: {
			httpGet: {
				path: "/readyz"
				port: "healthz"
			}
			failureThreshold: 30
			periodSeconds:    10
		}
		podDisruptionBudget: {
			enabled:        true
			maxUnavailable: 1
		}
		networkPolicy: enabled: true
	}

	certController: {
		replicas: 2
		leaderElection: enabled: true
		requeueInterval:    "10m"
		enablePartialCache: true
		metrics: {
			secure: enabled: true
			auth: enabled:   true
			service: {
				enabled: true
				annotations: "example.com/metrics": "true"
			}
		}
		extraVolumes: [{name: "metrics-tls", secret: secretName: "metrics-tls"}]
		extraVolumeMounts: [{name: "metrics-tls", mountPath: "/etc/tls", readOnly: true}]
		startupProbe: {
			httpGet: {
				path: "/readyz"
				port: "healthz"
			}
			failureThreshold: 30
			periodSeconds:    10
		}
		podDisruptionBudget: enabled: true
		networkPolicy: enabled:       true
	}
}
