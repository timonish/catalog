@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable every optional object so that all templates are
// validated against their Kubernetes and CRD schemas.
values: {
	// The default vet covers the hardened profile; flip to platform so
	// both identity branches validate.
	securityProfile: "platform"
	commonLabels: "app.kubernetes.io/part-of": "monitoring"

	crds: keep: true

	configReloader: {
		resources: {
			requests: {
				cpu:    "10m"
				memory: "32Mi"
			}
			limits: {
				cpu:    "20m"
				memory: "64Mi"
			}
		}
		enableProbe: true
	}

	denyNamespaces: ["kube-node-lease"]
	prometheusInstanceNamespaces: ["monitoring"]
	alertmanagerInstanceNamespaces: ["monitoring"]
	alertmanagerConfigNamespaces: ["monitoring"]
	thanosRulerInstanceNamespaces: ["monitoring"]
	prometheusInstanceSelector:   "operator=e2e"
	alertmanagerInstanceSelector: "operator=e2e"
	thanosRulerInstanceSelector:  "operator=e2e"

	featureGates: PrometheusAgentDaemonSet: true

	kubeletService: selector: "kubernetes.io/os=linux"
	kubeletEndpointSlice: true

	clusterDomain: "cluster.local"
	logLevel:      "debug"
	logFormat:     "json"

	prometheusDefaultBaseImage:   "quay.io/prometheus/prometheus"
	alertmanagerDefaultBaseImage: "quay.io/prometheus/alertmanager"
	thanosDefaultBaseImage:       "quay.io/thanos/thanos"
	localhostAddress:             "127.0.0.1"

	extraArgs: ["--repair-policy-for-statefulsets=evict"]

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
		labelSelector: matchLabels: "app.kubernetes.io/name": "prometheus-operator"
	}]
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

	serviceAccount: annotations: "team": "platform"

	rbac: aggregateClusterRoles: true

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
		tlsConfig: {
			insecureSkipVerify: false
			ca: secret: {
				name: "prometheus-operator-tls"
				key:  "ca.crt"
			}
		}
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

	networkPolicy: enabled: true

	webhook: {
		enabled:        true
		failurePolicy:  "Ignore"
		timeoutSeconds: 5
		objectSelector: matchLabels: "validated": "true"
		matchConditions: [{
			name:       "exclude-namespaces"
			expression: "object.metadata.namespace != 'kube-system'"
		}]
		// The existingSecret mode renders the caBundle bytes into the
		// webhook configs, which the cert-manager mode (validated by
		// the e2e webhook test) never exercises.
		tls: {
			type: "existingSecret"
			existingSecret: name: "prometheus-operator-tls"
			caBundle: """
				-----BEGIN CERTIFICATE-----
				MIIBhTCCASugAwIBAgIQIRi6zePL6mKjOipn+dNuaTAKBggqhkjOPQQDAjASMRAw
				-----END CERTIFICATE-----
				"""
		}
	}
}
