// Debug values for `timoni mod vet --debug`: every optional object is
// enabled and every optional field is exercised so all templates are
// validated against their schemas. The PodMonitor is mutually
// exclusive with the ServiceMonitor and is validated with
// `timoni build` in the e2e workflow instead.

@if(debug)

package main

values: {
	commonLabels: "app.kubernetes.io/part-of": "cert-manager"

	crds: {
		install: true
		keep:    true
	}

	imagePullSecrets: [{name: "regcred"}]

	rbac: {
		create:                true
		aggregateClusterRoles: true
	}

	approveSignerNames: ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"]

	prometheus: {
		enabled: true
		serviceMonitor: {
			enabled:       true
			interval:      "30s"
			scrapeTimeout: "10s"
			honorLabels:   true
			labels: release:                      "kube-prometheus-stack"
			annotations: "example.com/team":      "platform"
			endpointAdditionalProperties: scheme: "http"
		}
	}

	controller: {
		replicas:             2
		revisionHistoryLimit: 5
		strategy: type: "RollingUpdate"
		config: {
			logging: {
				format:    "json"
				verbosity: 4
			}
			leaderElectionConfig: {
				namespace:     "kube-system"
				leaseDuration: "60s"
				renewDeadline: "40s"
				retryPeriod:   "15s"
			}
			kubernetesAPIQPS:          20
			kubernetesAPIBurst:        50
			clusterResourceNamespace:  "cert-manager"
			enableCertificateOwnerRef: true
			copiedAnnotationPrefixes: ["*", "-kubectl.kubernetes.io/"]
			numberOfConcurrentWorkers: 10
			maxConcurrentChallenges:   30
			enablePprof:               false
			featureGates: ExperimentalGatewayAPISupport: true
			ingressShimConfig: {
				defaultIssuerName:  "letsencrypt"
				defaultIssuerKind:  "ClusterIssuer"
				defaultIssuerGroup: "cert-manager.io"
			}
			acmeHTTP01Config: {
				solverResourceRequestCPU:    "10m"
				solverResourceRequestMemory: "64Mi"
				solverResourceLimitsCPU:     "100m"
				solverResourceLimitsMemory:  "64Mi"
				solverRunAsNonRoot:          true
				solverNameservers: ["8.8.8.8:53"]
				solverExtraLabels: "example.com/solver": "acme"
			}
			acmeDNS01Config: {
				recursiveNameservers: ["8.8.8.8:53", "https://1.1.1.1/dns-query"]
				recursiveNameserversOnly: true
				checkRetryPeriod:         "10s"
			}
			pemSizeLimitsConfig: maxCertificateSize: 36500
			gatewayAPI: {
				enabled:           true
				enableListenerSet: true
			}
			certificateRequestMinimumBackoffDuration: "1h"
			certificateRequestMaximumBackoffDuration: "32h"
		}
		resources: {
			requests: {
				cpu:    "10m"
				memory: "64Mi"
			}
			limits: memory: "256Mi"
		}
		env: [{name: "HTTPS_PROXY", value: "http://proxy.example.com:3128"}]
		extraArgs: ["--v=4"]
		volumes: [{name: "extra", emptyDir: {}}]
		volumeMounts: [{name: "extra", mountPath: "/extra"}]
		podLabels: "example.com/scope":             "pki"
		podAnnotations: "example.com/scrape":       "true"
		deploymentAnnotations: "example.com/owner": "platform"
		priorityClassName:            "system-cluster-critical"
		automountServiceAccountToken: true
		hostAliases: [{ip: "127.0.0.1", hostnames: ["acme.local"]}]
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
			labels: "example.com/scope":               "pki"
			annotations: "eks.amazonaws.com/role-arn": "arn:aws:iam::111122223333:role/cert-manager"
		}
		service: {
			annotations: "example.com/metrics": "true"
			labels: "example.com/scope":        "pki"
			ipFamilyPolicy: "SingleStack"
			ipFamilies: ["IPv4"]
		}
		podDisruptionBudget: {
			enabled:      true
			minAvailable: 1
		}
		networkPolicy: enabled: true
	}

	webhook: {
		replicas:       2
		timeoutSeconds: 10
		config: {
			securePort:  10250
			healthzPort: 6080
			logging: verbosity:                               3
			featureGates: AdditionalCertificateOutputFormats: true
		}
		resources: requests: {
			cpu:    "10m"
			memory: "32Mi"
		}
		service: {
			type: "ClusterIP"
			annotations: "example.com/webhook": "true"
		}
		validatingWebhookConfiguration: annotations: "example.com/audit": "true"
		mutatingWebhookConfiguration: {
			namespaceSelector: matchExpressions: [{
				key:      "kubernetes.io/metadata.name"
				operator: "NotIn"
				values: ["kube-system"]
			}]
			annotations: "example.com/audit": "true"
		}
		podDisruptionBudget: {
			enabled:        true
			maxUnavailable: 1
		}
		networkPolicy: enabled: true
	}

	cainjector: {
		enabled:  true
		replicas: 2
		config: {
			logging: verbosity:              3
			leaderElectionConfig: namespace: "kube-system"
			ignoreNamespaces: ["kube-public"]
			enableDataSourceConfig: certificates: true
			enableInjectableConfig: {
				validatingWebhookConfigurations: true
				mutatingWebhookConfigurations:   true
				customResourceDefinitions:       true
				apiServices:                     true
			}
		}
		service: annotations: "example.com/metrics": "true"
		podDisruptionBudget: enabled: true
		networkPolicy: enabled:       true
	}
}
