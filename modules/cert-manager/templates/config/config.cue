package config

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	netv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// The ACME HTTP01 solver image reference tracked from the upstream
// releases, the default for `controller.config.acmeHTTP01Config.solverImage`.
_defaultSolverImage: (timoniv1.#Image & {
	repository: #defaultImages.acmesolver.repository
	tag:        #defaultImages.acmesolver.tag
	digest:     #defaultImages.acmesolver.digest
}).reference

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Runtime version info automatically set at apply-time.
	moduleVersion!: string
	kubeVersion!:   string

	// cert-manager requires Kubernetes 1.22 or newer.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.22.0"}

	// Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// Extra labels added to all resources, including the dynamically
	// created ACME HTTP01 solver resources.
	commonLabels?: timoniv1.#Labels
	if commonLabels != _|_ {
		metadata: labels: commonLabels
		controller: config: acmeHTTP01Config: solverExtraLabels: commonLabels
	}

	// CRD lifecycle settings. `install: false` skips the CRDs for
	// secondary instances; `keep: true` marks them with
	// `timoni.sh/prune: disabled` so an uninstall preserves the CRDs
	// and every cert-manager custom resource in the cluster.
	crds: {
		install: *true | bool
		keep:    *false | bool
	}

	// References to secrets used for pulling images from private
	// registries, added to all service accounts.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// Set `rbac.create: false` when the roles and bindings are managed
	// outside of this module. `aggregateClusterRoles` aggregates the
	// cert-manager view/edit ClusterRoles into the Kubernetes
	// user-facing roles.
	rbac: {
		create:                *true | bool
		aggregateClusterRoles: *true | bool
	}

	// The signer names the certificaterequests-approver controller may
	// approve for; `*` grants approval for all signers.
	approveSignerNames: *["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"] | [...string & =~".+"]

	// Disable the automatic approval of CertificateRequests created by
	// this cert-manager instance (e.g. when running a custom approver);
	// the approval RBAC is skipped and the approver controller disabled.
	disableAutoApproval: *false | bool
	if disableAutoApproval {
		controller: config: controllers: *["-certificaterequests-approver"] | [...string & =~".+"]
	}

	// Prometheus metrics settings. Disabling `prometheus.enabled` turns
	// off the metrics listeners and services of all components. The
	// ServiceMonitor and PodMonitor are mutually exclusive.
	prometheus: {
		enabled: *true | bool

		serviceMonitor: {
			enabled:            *false | bool
			namespace?:         string & =~".+"
			prometheusInstance: *"default" | string & =~".+"
			interval:           *"60s" | string & =~".+"
			scrapeTimeout:      *"30s" | string & =~".+"
			honorLabels:        *false | bool
			labels?:            timoniv1.#Labels
			annotations?:       timoniv1.#Annotations
			endpointAdditionalProperties?: {...}
		}

		podMonitor: {
			enabled:            *false | bool
			namespace?:         string & =~".+"
			prometheusInstance: *"default" | string & =~".+"
			interval:           *"60s" | string & =~".+"
			scrapeTimeout:      *"30s" | string & =~".+"
			honorLabels:        *false | bool
			labels?:            timoniv1.#Labels
			annotations?:       timoniv1.#Annotations
			endpointAdditionalProperties?: {...}
		}

		_guard: "valid"
		_guard: [
			if serviceMonitor.enabled && podMonitor.enabled {
				"serviceMonitor and podMonitor are mutually exclusive"
			},
			"valid",
		][0]
	}

	_metricsListenDefault: [
		if prometheus.enabled {"0.0.0.0:9402"},
		"0",
	][0]

	// The cert-manager controller settings.
	controller: #ControllerValues & {
		image: {
			repository: *#defaultImages.controller.repository | string
			tag:        *#defaultImages.controller.tag | string
			digest:     *#defaultImages.controller.digest | string
		}
		serviceAccount: name: *metadata.name | string & =~".+"
		config: {
			clusterResourceNamespace: *metadata.namespace | string & =~".+"
			metricsListenAddress:     *_metricsListenDefault | string & =~".+"
		}
		networkPolicy: ingress: *[{
			ports: [
				{port: "http-metrics", protocol: "TCP"},
				{port: "http-healthz", protocol: "TCP"},
			]
		}] | [...netv1.#NetworkPolicyIngressRule]
	}

	// The cert-manager webhook settings.
	webhook: #WebhookValues & {
		image: {
			repository: *#defaultImages.webhook.repository | string
			tag:        *#defaultImages.webhook.tag | string
			digest:     *#defaultImages.webhook.digest | string
		}
		serviceAccount: name: *"\(metadata.name)-webhook" | string & =~".+"
		config: {
			metricsListenAddress: *_metricsListenDefault | string & =~".+"
			tlsConfig: *{
				dynamic: {
					secretNamespace: metadata.namespace
					secretName:      "\(metadata.name)-webhook-ca"
					dnsNames: [
						"\(metadata.name)-webhook",
						"\(metadata.name)-webhook.\(metadata.namespace)",
						"\(metadata.name)-webhook.\(metadata.namespace).svc",
						if webhook.url.host != _|_ {
							webhook.url.host
						},
					]
				}
			} | #TLSConfig
		}
		networkPolicy: ingress: *[{
			ports: [
				{port: "https", protocol: "TCP"},
				{port: "healthcheck", protocol: "TCP"},
				{port: "http-metrics", protocol: "TCP"},
			]
		}] | [...netv1.#NetworkPolicyIngressRule]
	}
	if webhook.hostNetwork {
		webhook: dnsPolicy: *"ClusterFirstWithHostNet" | "ClusterFirst" | "Default" | "None"
	}

	// The cert-manager cainjector settings. The cainjector is required
	// by the webhook: it injects the serving CA into the webhook
	// configurations. Only disable it when another cainjector instance
	// runs in the cluster.
	cainjector: #CAInjectorValues & {
		image: {
			repository: *#defaultImages.cainjector.repository | string
			tag:        *#defaultImages.cainjector.tag | string
			digest:     *#defaultImages.cainjector.digest | string
		}
		serviceAccount: name:         *"\(metadata.name)-cainjector" | string & =~".+"
		config: metricsListenAddress: *_metricsListenDefault | string & =~".+"
		networkPolicy: ingress: *[{
			ports: [{port: "http-metrics", protocol: "TCP"}]
		}] | [...netv1.#NetworkPolicyIngressRule]
	}
}

// ControllerValues defines the controller component settings.
#ControllerValues: {
	#Workload

	// The controller configuration file, rendered into an immutable
	// ConfigMap; changes trigger a rolling update.
	config: #ControllerConfiguration

	// The liveness probe of the controller container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/livez" | string
			port: *"http-healthz" | string | int
		}
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *15 | int
		successThreshold:    *1 | int
		failureThreshold:    *8 | int
	}

	// The metrics Service settings; the Service is created when
	// `prometheus.enabled` is set and the PodMonitor is not used.
	service: {
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
	}
}

// WebhookValues defines the webhook component settings.
#WebhookValues: {
	#Workload

	// The webhook configuration file, rendered into an immutable
	// ConfigMap; changes trigger a rolling update.
	config: #WebhookConfiguration

	// Run the webhook on the host network, e.g. on clusters where the
	// control plane cannot reach the pod network; the default
	// `securePort` 10250 avoids conflicts with the kubelet.
	hostNetwork: *false | bool

	// The number of seconds the API server waits for the webhook to
	// respond before failing the request.
	timeoutSeconds: *30 | int & >=1 & <=30

	// Reach the webhook at an external host instead of the in-cluster
	// Service, e.g. on private GKE clusters where the control plane
	// cannot reach pods directly; the host is added to the serving
	// certificate DNS names.
	url: host?: string & =~".+"

	// The webhook Service settings.
	service: {
		type:            *"ClusterIP" | "NodePort" | "LoadBalancer"
		loadBalancerIP?: string & =~".+"
		annotations?:    timoniv1.#Annotations
		labels?:         timoniv1.#Labels
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
	}

	// The ValidatingWebhookConfiguration settings; validation is
	// skipped for namespaces labeled
	// `cert-manager.io/disable-validation: "true"`.
	validatingWebhookConfiguration: {
		namespaceSelector: *{
			matchExpressions: [{
				key:      "cert-manager.io/disable-validation"
				operator: "NotIn"
				values: ["true"]
			}]
		} | metav1.#LabelSelector
		annotations?: timoniv1.#Annotations
	}

	// The MutatingWebhookConfiguration settings.
	mutatingWebhookConfiguration: {
		namespaceSelector?: metav1.#LabelSelector
		annotations?:       timoniv1.#Annotations
	}

	// The liveness probe of the webhook container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/livez" | string
			port: *"healthcheck" | string | int
		}
		initialDelaySeconds: *60 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *1 | int
		successThreshold:    *1 | int
		failureThreshold:    *3 | int
	}

	// The readiness probe of the webhook container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *"healthcheck" | string | int
		}
		initialDelaySeconds: *5 | int
		periodSeconds:       *5 | int
		timeoutSeconds:      *1 | int
		successThreshold:    *1 | int
		failureThreshold:    *3 | int
	}
}

// CAInjectorValues defines the cainjector component settings.
#CAInjectorValues: {
	#Workload

	// Whether to deploy the cainjector.
	enabled: *true | bool

	// The cainjector configuration file, rendered into an immutable
	// ConfigMap; changes trigger a rolling update.
	config: #CAInjectorConfiguration

	// The metrics Service settings; the Service is created when
	// `prometheus.enabled` is set and the PodMonitor is not used.
	service: {
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
	}
}
