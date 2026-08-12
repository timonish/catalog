@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable every optional object so that all templates are
// validated against their Kubernetes and CRD schemas. The default vet
// covers the cluster-wide write scope; this covers the per-namespace
// RBAC branch through `targetNamespaces`.
values: {
	// The default vet covers the hardened profile; flip to platform so
	// both identity branches validate.
	securityContextPreset: "platform"
	replicas:              2
	revisionHistoryLimit:  5

	commonLabels: "app.kubernetes.io/part-of": "pki"

	podLabels: "team":                                         "platform"
	podAnnotations: "kubectl.kubernetes.io/default-container": "trust-manager"

	imagePullSecrets: [{name: "registry-token"}]

	defaultPackage: {
		resources: {
			requests: {
				cpu:    "10m"
				memory: "32Mi"
			}
			limits: memory: "64Mi"
		}
	}

	trust: namespace: "cert-manager"
	targetNamespaces: ["default", "cert-manager"]

	secretTargets: {
		enabled: true
		authorizedSecrets: ["ca-bundle", "istio-ca"]
	}

	filterExpiredCertificates: true
	filterNonCACerts:          true

	minTLSVersion: "VersionTLS12"
	cipherSuites:  "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"

	logLevel:  5
	logFormat: "json"

	leaderElection: {
		leaseDuration: "1m30s"
		renewDeadline: "20s"
	}

	readinessProbe: httpGet: {
		port: 6061
		path: "/health/readyz"
	}

	strategy: type: "Recreate"

	deploymentAnnotations: "team": "platform"

	env: [{name: "GODEBUG", value: "x509sha1=0"}]

	dnsConfig: options: [{name: "ndots", value: "2"}]
	schedulerName:                 "default-scheduler"
	terminationGracePeriodSeconds: 30

	webhook: {
		host:           "::"
		port:           8443
		timeoutSeconds: 10
		hostNetwork:    true
		service: {
			type:           "NodePort"
			nodePort:       30443
			ipFamilyPolicy: "SingleStack"
			ipFamilies: ["IPv4"]
		}
		tls: {
			certificate: {
				duration: "8766h"
				secretTemplate: {
					annotations: "team":                 "platform"
					labels: "app.kubernetes.io/part-of": "pki"
				}
			}
			approverPolicy: {
				enabled:                   true
				certManagerNamespace:      "pki"
				certManagerServiceAccount: "cert-manager-sa"
			}
		}
	}

	metrics: {
		port: 9403
		service: {
			type:           "NodePort"
			ipFamilyPolicy: "SingleStack"
			ipFamilies: ["IPv4"]
		}
	}

	serviceMonitor: {
		enabled: true
		additionalLabels: "team":        "platform"
		annotations: "example.com/team": "platform"
		interval:      "1m30s"
		scrapeTimeout: "10s"
		honorLabels:   true
		scheme:        "http"
		sampleLimit:   1000
		targetLabels: ["app.kubernetes.io/part-of"]
		metricRelabelings: [{
			action: "drop"
			sourceLabels: ["__name__"]
			regex: "go_gc_.*"
		}]
		relabelings: [{
			action: "replace"
			sourceLabels: ["__meta_kubernetes_pod_node_name"]
			targetLabel: "instance"
		}]
	}

	podDisruptionBudget: {
		enabled:                    true
		maxUnavailable:             "50%"
		unhealthyPodEvictionPolicy: "AlwaysAllow"
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
		labelSelector: matchLabels: "app.kubernetes.io/name": "trust-manager"
	}]

	priorityClassName: "system-cluster-critical"

	serviceAccount: annotations: "eks.amazonaws.com/role-arn": "arn:aws:iam::111122223333:role/trust-manager"

	extraVolumes: [{
		name: "extra"
		emptyDir: {}
	}]
	extraVolumeMounts: [{
		name:      "extra"
		mountPath: "/extra"
	}]

	extraArgs: ["--kubeconfig="]

	crds: keep: true
}
