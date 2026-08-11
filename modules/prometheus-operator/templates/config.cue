package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Runtime version info automatically set at apply-time.
	moduleVersion!: string
	kubeVersion!:   string

	// The module requires Kubernetes 1.25 or newer.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.25.0"}

	// Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// Extra labels added to all resources.
	commonLabels?: timoniv1.#Labels
	if commonLabels != _|_ {
		metadata: labels: commonLabels
	}

	// Label selector common to all resources.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// The container image repository, tag, digest and pull policy.
	// The default repository and tag track the upstream release
	// and are set in `versions.cue` by upengine.
	image: timoniv1.#Image & {
		repository: *#defaultImages."prometheus-operator".repository | string
		tag:        *#defaultImages."prometheus-operator".tag | string
		digest:     *#defaultImages."prometheus-operator".digest | string
	}

	// References to secrets used for pulling images from private registries.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// Custom resource definition settings. Set `install: false` when the
	// CRDs are managed outside of this module. `keep: true` preserves the
	// CRDs on uninstall; without it, deleting the instance deletes the
	// CRDs and thereby every monitoring.coreos.com custom resource in
	// the cluster.
	crds: {
		install: *true | bool
		keep:    *false | bool
	}

	// The config-reloader sidecar the operator injects into the
	// Prometheus, Alertmanager and ThanosRuler pods it manages. The
	// image is tracked in `versions.cue`; the resource requirements
	// are applied to every injected sidecar.
	configReloader: {
		image: timoniv1.#Image & {
			repository: *#defaultImages."prometheus-config-reloader".repository | string
			tag:        *#defaultImages."prometheus-config-reloader".tag | string
			digest:     *#defaultImages."prometheus-config-reloader".digest | string
		}
		resources?: timoniv1.#ResourceRequirements
		// Enable the config-reloader sidecar probes.
		enableProbe: *false | bool
	}

	// The namespaces watched for ServiceMonitor, PodMonitor, Probe,
	// PrometheusRule and configuration resources; empty means all
	// namespaces. Mutually exclusive with `denyNamespaces`.
	namespaces: *[] | [...string & =~".+"]

	// The namespaces excluded from watching; empty means none.
	denyNamespaces: *[] | [...string & =~".+"]
	_namespacesGuard: "valid"
	_namespacesGuard: [
		if len(namespaces) > 0 && len(denyNamespaces) > 0 {
			"namespaces and denyNamespaces are mutually exclusive"
		},
		"valid",
	][0]

	// The namespaces watched for the instance custom resources
	// (Prometheus, Alertmanager, AlertmanagerConfig, ThanosRuler);
	// empty means the `namespaces` scope.
	prometheusInstanceNamespaces: *[] | [...string & =~".+"]
	alertmanagerInstanceNamespaces: *[] | [...string & =~".+"]
	alertmanagerConfigNamespaces: *[] | [...string & =~".+"]
	thanosRulerInstanceNamespaces: *[] | [...string & =~".+"]

	// Label selectors filtering the instance custom resources this
	// operator manages, for running multiple operators side by side.
	prometheusInstanceSelector?:   string & =~".+"
	alertmanagerInstanceSelector?: string & =~".+"
	thanosRulerInstanceSelector?:  string & =~".+"

	// Field selector filtering the Secrets the operator watches and
	// caches. The default excludes the kubelet-rotated, service account
	// token, Helm release and Timoni instance-storage Secret types.
	secretFieldSelector: *"type!=kubernetes.io/dockercfg,type!=kubernetes.io/service-account-token,type!=helm.sh/release.v1,type!=timoni.sh/instance" | string

	// Watch objects referenced from the instance custom resources
	// (Secrets, ConfigMaps) in all namespaces.
	watchReferencedObjectsInAllNamespaces: *true | bool

	// Reject Prometheus instances with unmanaged configuration
	// (neither serviceMonitorSelector nor podMonitorSelector nor
	// probeSelector nor scrapeConfigSelector set).
	disableUnmanagedPrometheusConfiguration: *true | bool

	// Operator feature gates, e.g. `PrometheusAgentDaemonSet: true`.
	featureGates: {[string]: bool}

	// Whether the operator reconciles PrometheusAgent DaemonSets, which
	// requires additional RBAC verified by the operator at startup.
	_prometheusAgentDaemonSet: *featureGates["PrometheusAgentDaemonSet"] | false

	// The kubelet Endpoints objects the operator maintains for
	// scraping the kubelets through a headless Service.
	kubeletService: {
		enabled:   *true | bool
		namespace: *"kube-system" | string & =~".+"
		name:      *"kubelet" | string & =~".+"
		selector:  *"" | string
	}

	// Maintain kubelet Endpoints and/or EndpointSlice objects.
	kubeletEndpoints:     *true | bool
	kubeletEndpointSlice: *false | bool

	// The cluster domain used for the generated addresses; empty falls
	// back to the operator default.
	clusterDomain: *"" | string

	// The log verbosity and format.
	logLevel:  *"info" | "all" | "debug" | "warn" | "error" | "none"
	logFormat: *"logfmt" | "json"

	// Override the default base images used for the Prometheus,
	// Alertmanager and Thanos instances when their custom resources
	// do not specify an image.
	prometheusDefaultBaseImage?:   string & =~".+"
	alertmanagerDefaultBaseImage?: string & =~".+"
	thanosDefaultBaseImage?:       string & =~".+"

	// The address on which the operator reaches its managed instances,
	// e.g. `127.0.0.1` when the Prometheus pods bind to localhost.
	localhostAddress?: string & =~".+"

	// Extra command line arguments appended after the generated ones.
	extraArgs: *[] | [...string]

	// Environment variables for the operator container. GOGC tuned
	// down from the Go default trades CPU for a lower memory floor on
	// the operator's large informer caches.
	env: *[{name: "GOGC", value: "30"}] | [...corev1.#EnvVar]

	// The container resource requirements.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"100Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"200m" | timoniv1.#CPUQuantity
			memory: *"200Mi" | timoniv1.#MemoryQuantity
		}
	}

	// The security profile applied to the pod identity defaults: the
	// default "hardened" profile pins the image's non-root UID, while
	// "platform" leaves the identity to an admission controller
	// (e.g. an OpenShift SecurityContextConstraint).
	securityProfile: timoniv1.#SecurityProfile

	// The container security context, hardened by default.
	securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext

	// The pod security context generated for the security profile.
	podSecurityContext: corev1.#PodSecurityContext & timoniv1.#PodSecurityContext & {
		#Profile: securityProfile
		#User:    65534
	}

	// The liveness probe of the operator container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *_servingPortName | string | int
			if webhook.enabled {
				scheme: *"HTTPS" | string
			}
		}
		initialDelaySeconds: *0 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *1 | int
		failureThreshold:    *3 | int
		successThreshold:    *1 | int
	}

	// The readiness probe of the operator container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *_servingPortName | string | int
			if webhook.enabled {
				scheme: *"HTTPS" | string
			}
		}
		initialDelaySeconds: *0 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *1 | int
		failureThreshold:    *3 | int
		successThreshold:    *1 | int
	}

	// Extra volumes and volume mounts for the operator container.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Pod optional settings.
	podLabels?:      timoniv1.#Labels
	podAnnotations?: timoniv1.#Annotations
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	tolerations?: [...corev1.#Toleration]
	affinity?: corev1.#Affinity
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	dnsConfig?:                     corev1.#PodDNSConfig
	priorityClassName?:             string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

	// Run the pods in the host network namespace.
	hostNetwork: *false | bool
	if hostNetwork {
		dnsPolicy: *"ClusterFirstWithHostNet" | "ClusterFirst" | "Default" | "None"
	}
	if !hostNetwork {
		dnsPolicy?: "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	}

	// The strategy to replace old pods with new ones.
	strategy?: appsv1.#DeploymentStrategy

	// The number of old ReplicaSets to retain.
	revisionHistoryLimit?: int & >=0

	// Annotations added to the Deployment.
	deploymentAnnotations?: timoniv1.#Annotations

	// Mount the service account token into the pod.
	automountServiceAccountToken: *true | bool

	// ServiceAccount settings. Set `create: false` to use an existing
	// service account referenced by `name`.
	serviceAccount: {
		create: *true | bool
		if create {
			name: *metadata.name | string
		}
		if !create {
			name: *"default" | string
		}
		annotations?: timoniv1.#Annotations
		// The token is mounted through the pod setting instead.
		automountServiceAccountToken: *false | bool
	}

	// Set `rbac.create: false` when the cluster roles and bindings are
	// managed outside of this module. `aggregateClusterRoles` adds
	// view/edit ClusterRoles for the monitoring.coreos.com custom
	// resources, aggregated into the Kubernetes user-facing roles.
	rbac: {
		create:                *true | bool
		aggregateClusterRoles: *false | bool
	}

	// Service settings for the operator web server (metrics and, when
	// the admission webhook is enabled, the webhook endpoints).
	service: {
		type:         *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:         *8080 | int & >0 & <=65535
		httpsPort:    *443 | int & >0 & <=65535
		clusterIP?:   string & =~".+"
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
		externalIPs?: [...string]
		if type == "NodePort" {
			nodePort:    *30080 | int & >0 & <=65535
			nodePortTls: *30443 | int & >0 & <=65535
		}
		if type == "LoadBalancer" {
			loadBalancerIP?: string & =~".+"
			loadBalancerSourceRanges?: [...string]
		}
		if type != "ClusterIP" {
			externalTrafficPolicy?: "Cluster" | "Local"
		}
	}

	// PodDisruptionBudget (optional). The mutually exclusive
	// `minAvailable` and `maxUnavailable` accept an absolute number
	// or a percentage.
	podDisruptionBudget: {
		enabled:                     *false | bool
		unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
		*{} | {minAvailable: int & >=0 | string & =~"^[0-9]+%$"} | {maxUnavailable: int & >=0 | string & =~"^[0-9]+%$"}
	}

	// Prometheus Operator ServiceMonitor for the operator's own
	// metrics endpoint (optional).
	serviceMonitor: {
		enabled:           *false | bool
		additionalLabels?: timoniv1.#Labels
		// Scrape settings; set to an empty string to omit the field and
		// fall back to the Prometheus Operator defaults.
		interval:               *"1m" | "" | =~"^[0-9]+(ms|s|m|h)$"
		scrapeTimeout:          *"10s" | "" | =~"^[0-9]+(ms|s|m|h)$"
		sampleLimit?:           int & >=0
		targetLimit?:           int & >=0
		labelLimit?:            int & >=0
		labelNameLengthLimit?:  int & >=0
		labelValueLengthLimit?: int & >=0
		metricRelabelings?: [...]
		relabelings?: [...]
	}

	// NetworkPolicy settings; the default rules allow the operator's
	// serving port in and DNS and the Kubernetes API out.
	networkPolicy: {
		enabled: *false | bool
		ingress: *[{
			ports: [{port: _servingPortName, protocol: "TCP"}]
		}] | [...netv1.#NetworkPolicyIngressRule]
		egress: *[{
			ports: [
				{port: 53, protocol: "TCP"},
				{port: 53, protocol: "UDP"},
				{port: 443, protocol: "TCP"},
				{port: 6443, protocol: "TCP"},
			]
		}] | [...netv1.#NetworkPolicyEgressRule]
	}

	// The admission webhook served by the operator (optional): it
	// validates PrometheusRule and AlertmanagerConfig resources and
	// normalizes PrometheusRule annotations. Enabling it switches the
	// operator web server to TLS with the certificate provisioned
	// according to `webhook.tls`.
	webhook: {
		enabled: *false | bool

		// The port on which the operator serves TLS when the webhook
		// is enabled.
		port: *10250 | int & >0 & <=65535

		// Fail closed by default; `Ignore` admits objects when the
		// webhook is unreachable.
		failurePolicy:  *"Fail" | "Ignore"
		timeoutSeconds: *10 | int & >=1 & <=30
		namespaceSelector?: {...}
		objectSelector?: {...}
		matchConditions?: [...]

		// TLS settings for the operator web server:
		// - `cert-manager`: cert-manager.io issues and maintains the
		//   certificate, and injects the CA into the webhook configs;
		// - `existingSecret`: reuse an existing TLS secret, with the
		//   PEM-encoded CA supplied in `caBundle`.
		tls: {
			type:       *"cert-manager" | "existingSecret"
			minVersion: *"VersionTLS13" | "VersionTLS12" | "VersionTLS11" | "VersionTLS10"
			cipherSuites?: [...string & =~".+"]

			certManager: {
				existingIssuer: {
					enabled: *false | bool
					kind:    *"Issuer" | "ClusterIssuer"
					if enabled {
						name: string & =~".+"
					}
					if !enabled {
						name: *"" | string
					}
				}
				duration?:    string & =~".+"
				renewBefore?: string & =~".+"
				annotations?: timoniv1.#Annotations
				labels?:      timoniv1.#Labels
			}

			if type == "existingSecret" {
				existingSecret: name: string & =~".+"
				// PEM encoded CA bundle of the webhook certificate,
				// base64 encoded into the webhook configs at render time.
				caBundle: string & =~".+"
			}
			if type != "existingSecret" {
				existingSecret: name: *"" | string
			}
		}
	}

	// The name of the TLS secret mounted into the operator when the
	// webhook is enabled.
	_tlsSecretName: [
		if webhook.tls.existingSecret.name != "" {webhook.tls.existingSecret.name},
		"\(metadata.name)-webhook-tls",
	][0]

	// The serving port name of the operator container and Service.
	_servingPortName: [
		if webhook.enabled {"https"},
		"http",
	][0]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.crds.install {
			for name, crd in customresourcedefinition {
				"crd-\(name)": crd
				"crd-\(name)": metadata: labels: config.metadata.labels
				if config.crds.keep {
					"crd-\(name)": metadata: annotations: "timoni.sh/prune": "disabled"
				}
				if config.metadata.annotations != _|_ {
					"crd-\(name)": metadata: annotations: config.metadata.annotations
				}
			}
		}

		if config.serviceAccount.create {
			"\(config.metadata.name)-sa": #ServiceAccount & {_config: config}
		}

		if config.rbac.create {
			"\(config.metadata.name)-cr": #ClusterRole & {_config: config}
			"\(config.metadata.name)-crb": #ClusterRoleBinding & {_config: config}
			if config.rbac.aggregateClusterRoles {
				"\(config.metadata.name)-cr-view": #AggregatedViewClusterRole & {_config: config}
				"\(config.metadata.name)-cr-edit": #AggregatedEditClusterRole & {_config: config}
			}
		}

		"\(config.metadata.name)-svc": #Service & {_config: config}
		"\(config.metadata.name)-deploy": #Deployment & {_config: config}

		if config.podDisruptionBudget.enabled {
			"\(config.metadata.name)-pdb": #PodDisruptionBudget & {_config: config}
		}

		if config.serviceMonitor.enabled {
			"\(config.metadata.name)-monitor": #ServiceMonitor & {_config: config}
		}

		if config.networkPolicy.enabled {
			"\(config.metadata.name)-netpol-ingress": #NetworkPolicyIngress & {_config: config}
			"\(config.metadata.name)-netpol-egress": #NetworkPolicyEgress & {_config: config}
		}

		if config.webhook.enabled {
			"\(config.metadata.name)-vwc": #ValidatingWebhookConfiguration & {_config: config}
			"\(config.metadata.name)-mwc": #MutatingWebhookConfiguration & {_config: config}

			if config.webhook.tls.type == "cert-manager" {
				if !config.webhook.tls.certManager.existingIssuer.enabled {
					"\(config.metadata.name)-issuer": #Issuer & {_config: config}
				}
				"\(config.metadata.name)-cert": #Certificate & {_config: config}
			}
		}
	}
}
