// Debug values for `timoni mod vet --debug`: every optional object and
// field is enabled so all templates are validated against their
// schemas. The registerWebhook and tls.create branches conflict with
// the certManager mode enabled here (the schema guards enforce the
// mutual exclusion) and cannot be covered by a single debug value set;
// their objects were verified with `timoni build` against dedicated
// value files during onboarding.

@if(debug)

package main

values: {
	commonLabels: "app.kubernetes.io/part-of": "debug"
	crds: {
		install: true
		keep:    true
	}
	imagePullSecrets: [{name: "regcred"}]
	rbac: {
		create: true
		extraRules: [{
			apiGroups: ["custom.metrics.k8s.io"]
			resources: ["*"]
			verbs: ["get", "list"]
		}]
	}
	serviceMonitor: {
		enabled:       true
		interval:      "1m30s"
		scrapeTimeout: "10s"
		honorLabels:   true
		scheme:        "http"
		additionalLabels: prometheus:     "default"
		annotations: "example.com/debug": "true"
		sampleLimit: 1000
		targetLabels: ["app.kubernetes.io/part-of"]
		metricRelabelings: [{
			action: "labeldrop"
			regex:  "pod_template_hash"
		}]
	}
	securityProfile: "platform"
	recommender: {
		replicas: 2
		strategy: type: "Recreate"
		resources: requests: cpu: "50m"
		extraArgs: ["--recommendation-margin-fraction=0.2"]
		env: [{name: "GOMAXPROCS", value: "2"}]
		tolerations: [{key: "node-role.kubernetes.io/control-plane", operator: "Exists", effect: "NoSchedule"}]
		topologySpreadConstraints: [{
			maxSkew:           1
			topologyKey:       "kubernetes.io/hostname"
			whenUnsatisfiable: "ScheduleAnyway"
			labelSelector: matchLabels: "app.kubernetes.io/component": "recommender"
		}]
		podLabels: "example.com/debug":      "true"
		podAnnotations: "example.com/debug": "true"
		dnsPolicy: "ClusterFirst"
		dnsConfig: options: [{name: "ndots", value: "2"}]
		priorityClassName:             "system-cluster-critical"
		schedulerName:                 "default-scheduler"
		terminationGracePeriodSeconds: 30
		deploymentAnnotations: "example.com/debug": "true"
		serviceAccount: {
			labels: "example.com/debug":      "true"
			annotations: "example.com/debug": "true"
		}
		podDisruptionBudget: {
			maxUnavailable:             1
			unhealthyPodEvictionPolicy: "AlwaysAllow"
		}
		metricsService: {
			annotations: "example.com/debug": "true"
			labels: "example.com/debug":      "true"
			ipFamilyPolicy: "SingleStack"
			ipFamilies: ["IPv4"]
		}
		extraVolumes: [{name: "extra", emptyDir: {}}]
		extraVolumeMounts: [{name: "extra", mountPath: "/extra"}]
		leaderElection: {
			resourceNamespace: "kube-system"
			leaseDuration:     "30s"
			renewDeadline:     "20s"
			retryPeriod:       "5s"
		}
	}
	updater: {
		replicas:                    2
		inPlaceSkipDisruptionBudget: false
		resources: requests: cpu: "50m"
		extraArgs: ["--min-replicas=1"]
		podDisruptionBudget: minAvailable: "50%"
	}
	admissionController: {
		replicas: 2
		service: {
			name: "vpa-webhook-debug"
			annotations: "example.com/debug": "true"
			labels: "example.com/debug":      "true"
			port:           8443
			targetPort:     8000
			ipFamilyPolicy: "SingleStack"
			ipFamilies: ["IPv4"]
		}
		hostNetwork: true
		dnsPolicy:   "ClusterFirstWithHostNet"
		mutatingWebhookConfiguration: {
			failurePolicy: "Fail"
			namespaceSelector: matchExpressions: [{
				key:      "vpa-webhook"
				operator: "NotIn"
				values: ["disabled"]
			}]
			objectSelector: matchLabels: "vpa-enabled": "true"
			timeoutSeconds: 10
			annotations: "example.com/debug": "true"
		}
		certManager: {
			enabled: true
			createSelfSignedIssuer: {
				enabled:     true
				duration:    "4380h"
				renewBefore: "360h"
			}
			duration:    "72h"
			renewBefore: "12h"
			privateKey: {
				algorithm: "ECDSA"
				size:      256
			}
			annotations: "example.com/debug": "true"
		}
		tls: secretName: "vpa-debug-tls"
	}
}
