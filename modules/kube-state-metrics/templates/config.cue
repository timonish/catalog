package templates

import (
	"encoding/yaml"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// The metric collectors (resource kinds) kube-state-metrics can expose.
#CollectorName: "certificatesigningrequests" |
	"clusterrolebindings" |
	"clusterroles" |
	"configmaps" |
	"cronjobs" |
	"daemonsets" |
	"deployments" |
	"endpoints" |
	"endpointslices" |
	"horizontalpodautoscalers" |
	"ingressclasses" |
	"ingresses" |
	"jobs" |
	"leases" |
	"limitranges" |
	"mutatingwebhookconfigurations" |
	"namespaces" |
	"networkpolicies" |
	"nodes" |
	"persistentvolumeclaims" |
	"persistentvolumes" |
	"poddisruptionbudgets" |
	"pods" |
	"replicasets" |
	"replicationcontrollers" |
	"resourcequotas" |
	"rolebindings" |
	"roles" |
	"secrets" |
	"serviceaccounts" |
	"services" |
	"statefulsets" |
	"storageclasses" |
	"validatingwebhookconfigurations" |
	"volumeattachments"

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
		repository: *#defaultImages."kube-state-metrics".repository | string
		tag:        *#defaultImages."kube-state-metrics".tag | string
		digest:     *#defaultImages."kube-state-metrics".digest | string
	}

	// References to secrets used for pulling images from private registries.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// The number of pods. With `autosharding` enabled each pod exposes
	// only its shard of the metrics; without it every replica exposes
	// the full set. Scaling to zero suspends the metrics collection.
	replicas: *1 | int & >=0

	// Deploy a StatefulSet instead of a Deployment and let the pods
	// discover their shard number from their ordinal, distributing the
	// metrics across `replicas` shards. Requires the default headless
	// ClusterIP Service.
	autosharding: enabled: *false | bool
	_autoshardingGuard: "valid"
	_autoshardingGuard: [
		if autosharding.enabled && service.type != "ClusterIP" {
			"autosharding requires the default headless ClusterIP Service"
		},
		if autosharding.enabled if service.type == "ClusterIP" if service.clusterIP != "None" {
			"autosharding requires the default headless ClusterIP Service"
		},
		"valid",
	][0]

	// The resource kinds to collect metrics for, rendered into the
	// `--resources` argument; an empty list falls back to the
	// kube-state-metrics built-in default set. Note that the list is
	// set wholesale: to add or remove a collector, supply the full
	// desired list.
	collectors: *[
		"certificatesigningrequests",
		"configmaps",
		"cronjobs",
		"daemonsets",
		"deployments",
		"endpointslices",
		"horizontalpodautoscalers",
		"ingresses",
		"jobs",
		"leases",
		"limitranges",
		"mutatingwebhookconfigurations",
		"namespaces",
		"networkpolicies",
		"nodes",
		"persistentvolumeclaims",
		"persistentvolumes",
		"poddisruptionbudgets",
		"pods",
		"replicasets",
		"replicationcontrollers",
		"resourcequotas",
		"secrets",
		"services",
		"statefulsets",
		"storageclasses",
		"validatingwebhookconfigurations",
		"volumeattachments",
	] | [...#CollectorName]

	// The metrics to expose, as exact names and/or regex patterns.
	// Mutually exclusive with `metricDenylist`.
	metricAllowlist: *[] | [...string & =~".+"]

	// The metrics not to expose, as exact names and/or regex patterns.
	metricDenylist: *[] | [...string & =~".+"]
	_metricListsGuard: "valid"
	_metricListsGuard: [
		if len(metricAllowlist) > 0 && len(metricDenylist) > 0 {
			"metricAllowlist and metricDenylist are mutually exclusive"
		},
		"valid",
	][0]

	// The Kubernetes label keys used in the resources' labels metrics,
	// e.g. `"pods=[app.kubernetes.io/name]"` or `"namespaces=[*]"`.
	metricLabelsAllowlist: *[] | [...string & =~".+"]

	// The Kubernetes annotation keys used in the resources' annotations
	// metrics, e.g. `"pods=[example.com/team]"`.
	metricAnnotationsAllowList: *[] | [...string & =~".+"]

	// The namespaces to collect resources from; empty means all
	// namespaces. When both lists are set, the resources are collected
	// from the `namespaces` list minus the `namespacesDenylist` entries.
	namespaces: *[] | [...string & =~".+"]

	// The namespaces to exclude from collecting resources.
	namespacesDenylist: *[] | [...string & =~".+"]

	// Require authentication and authorization on the metrics endpoints
	// through the Kubernetes API (TokenReview and SubjectAccessReview).
	// The required RBAC permissions are added automatically.
	authFilter: enabled: *false | bool

	// Custom Resource State metrics: expose metrics from the fields of
	// custom resources. The configuration is rendered into an immutable
	// ConfigMap whose name is suffixed with the config hash, so config
	// changes roll the pods. Grant kube-state-metrics list/watch access
	// to the configured custom resources with `rbac.extraRules`.
	customResourceState: {
		enabled: *false | bool

		// Expose only the custom resource state metrics, disabling all
		// built-in collectors.
		only: *false | bool

		// Reference an externally managed ConfigMap holding the
		// configuration under `key` instead of generating one from
		// `config`.
		existingConfigMap?: {
			name!: string & =~".+"
			key:   *"config.yaml" | string & =~".+"
		}

		config: {
			kind: "CustomResourceStateMetrics"
			spec: resources: [...{
				groupVersionKind: {
					group!:   string & =~".+"
					version!: string & =~".+"
					kind!:    string & =~".+"
				}
				...
			}]
		}
	}

	// Hidden fields computing the Custom Resource State ConfigMap
	// (immutable, hash-named, so config changes roll the pods), shared
	// between the emitted object and the pod volume referencing it.
	// With `existingConfigMap` the referenced name and key are used
	// instead.
	_crsData: "config.yaml": yaml.Marshal(customResourceState.config)
	_crsConfigMap: timoniv1.#ImmutableConfig & {
		#Suffix: "-crs"
		#Meta:   metadata
		#Data:   _crsData
	}
	_crsConfigMapName: _crsConfigMap.metadata.name
	_crsVolumeConfigMapName: [
		if customResourceState.existingConfigMap != _|_ {
			customResourceState.existingConfigMap.name
		},
		_crsConfigMapName,
	][0]
	_crsFileName: [
		if customResourceState.existingConfigMap != _|_ {
			customResourceState.existingConfigMap.key
		},
		"config.yaml",
	][0]

	// The name of an existing Secret with a `config` key holding a
	// kubeconfig file, for collecting the state of another cluster.
	kubeconfigSecret?: name: string & =~".+"

	// Expose the self-metrics (telemetry) endpoint on the Service and,
	// when the ServiceMonitor is enabled, scrape it.
	selfMonitor: {
		enabled: *false | bool

		// The telemetry listen host and port; the empty host and the
		// default port fall back to the kube-state-metrics defaults.
		telemetryHost: *"" | string
		telemetryPort: *8081 | int & >0 & <=65535
	}
	_portsGuard: "valid"
	_portsGuard: [
		if service.port == selfMonitor.telemetryPort {
			"service.port and selfMonitor.telemetryPort must differ"
		},
		"valid",
	][0]

	// Extra command line arguments appended after the generated ones.
	extraArgs: *[] | [...string]

	// Environment variables for the kube-state-metrics container.
	env: *[] | [...corev1.#EnvVar]

	// The container resource requirements.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"10m" | timoniv1.#CPUQuantity
			memory: *"190Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"250Mi" | timoniv1.#MemoryQuantity
		}
	}

	// The security preset applied to the pod identity defaults: the
	// default "hardened" preset pins the image's non-root UID, while
	// "platform" leaves the identity to an admission controller
	// (e.g. an OpenShift SecurityContextConstraint).
	securityContextPreset: timoniv1.#SecurityContextPreset

	// The container security context, hardened by default.
	securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext

	// The pod security context generated for the security preset.
	podSecurityContext: corev1.#PodSecurityContext & timoniv1.#PodSecurityContext & {
		#Preset: securityContextPreset
		#User:   65534
	}

	// The liveness probe of the kube-state-metrics container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/livez" | string
			port: *"http" | string | int
			if hostNetwork {
				host: *"127.0.0.1" | string
			}
		}
		initialDelaySeconds: *5 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
		successThreshold:    *1 | int
	}

	// The readiness probe of the kube-state-metrics container, served
	// on the telemetry port.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/readyz" | string
			port: *"metrics" | string | int
			if hostNetwork {
				host: *"127.0.0.1" | string
			}
		}
		initialDelaySeconds: *5 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
		successThreshold:    *1 | int
	}

	// The startup probe of the kube-state-metrics container (optional),
	// e.g. `startupProbe: {}` enables it with the default settings.
	startupProbe?: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *"http" | string | int
			if hostNetwork {
				host: *"127.0.0.1" | string
			}
		}
		initialDelaySeconds: *0 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
		successThreshold:    *1 | int
	}

	// Extra volumes and volume mounts for the kube-state-metrics
	// container.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Extra containers and init containers added to the pods.
	extraContainers?: [...corev1.#Container]
	initContainers?: [...corev1.#Container]

	// Pod optional settings.
	podLabels?:      timoniv1.#Labels
	podAnnotations?: timoniv1.#Annotations
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	tolerations?: [...corev1.#Toleration]
	// The affinity rules; Linux placement comes from the nodeSelector
	// default. `podAntiAffinity` accepts the `soft` (default), `hard`
	// and `none` presets for spreading the replicas across nodes, or
	// raw pod anti-affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	dnsConfig?:                     corev1.#PodDNSConfig
	priorityClassName?:             string & =~".+"
	schedulerName?:                 string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

	// Run the pods in the host network namespace.
	hostNetwork: *false | bool
	if hostNetwork {
		dnsPolicy: *"ClusterFirstWithHostNet" | "ClusterFirst" | "Default" | "None"
	}
	if !hostNetwork {
		dnsPolicy: *"ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	}

	// Run the pods in the host user namespace.
	hostUsers?: bool

	// The strategy to replace old pods with new ones (Deployment mode
	// only).
	strategy?: appsv1.#DeploymentStrategy

	// The number of old ReplicaSets or StatefulSet revisions to retain.
	revisionHistoryLimit?: int & >=0

	// Labels and annotations added to the Deployment or StatefulSet.
	workloadLabels?:      timoniv1.#Labels
	workloadAnnotations?: timoniv1.#Annotations

	// Mount the service account token into the pod; kube-state-metrics
	// requires it for accessing the Kubernetes API.
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
		// References to secrets set on the ServiceAccount for pulling
		// images from private registries.
		imagePullSecrets?: [...timoniv1.#ObjectReference]
		// The token is mounted through the pod setting instead.
		automountServiceAccountToken: *false | bool
	}

	// Set `rbac.create: false` when the roles and bindings are managed
	// outside of this module. With `useClusterRole: false`, namespaced
	// Roles and RoleBindings are created in each of the `namespaces`
	// instead of a ClusterRole, restricting collection to those
	// namespaces (cluster-scoped collectors such as `nodes` will not
	// work in this mode); the cluster-scoped permissions the
	// `authFilter` and `customResourceState` features require are then
	// granted through a supplemental ClusterRole. `extraRules` grants
	// access to additional resources, e.g. the custom resources
	// configured in `customResourceState`.
	rbac: {
		create:         *true | bool
		useClusterRole: *true | bool
		extraRules?: [...rbacv1.#PolicyRule]
	}
	_rbacGuard: "valid"
	_rbacGuard: [
		if rbac.create && !rbac.useClusterRole && len(namespaces) == 0 {
			"rbac.useClusterRole=false requires namespaces to be set"
		},
		"valid",
	][0]

	// Service settings. The Service is headless by default; set
	// `clusterIP` to an empty string for an auto-assigned virtual IP.
	service: {
		type: *"ClusterIP" | "NodePort" | "LoadBalancer"
		port: *8080 | int & >0 & <=65535
		if type == "ClusterIP" {
			clusterIP: *"None" | string
		}
		if type != "ClusterIP" {
			clusterIP?: string & =~".+"
		}
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
		externalIPs?: [...string]
		if type == "NodePort" {
			// Zero lets the cluster assign the node ports.
			nodePort:          *0 | int & >=0 & <=32767
			telemetryNodePort: *0 | int & >=0 & <=32767
		}
		if type == "LoadBalancer" {
			loadBalancerIP?: string & =~".+"
			loadBalancerSourceRanges?: [...string]
		}
		if type != "ClusterIP" {
			externalTrafficPolicy?: "Cluster" | "Local"
		}

		// Annotate the Service for Prometheus annotation-based
		// discovery.
		prometheusScrape: *true | bool
	}

	// PodDisruptionBudget (optional). The mutually exclusive
	// `minAvailable` and `maxUnavailable` accept an absolute number
	// or a percentage; `minAvailable: 1` is the default.
	podDisruptionBudget: {
		enabled:                     *false | bool
		unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
		*{minAvailable: *1 | int & >=0 | string & =~"^[0-9]+%$"} | {maxUnavailable: int & >=0 | string & =~"^[0-9]+%$"}
	}

	// Prometheus Operator ServiceMonitor for the metrics endpoint and,
	// when `selfMonitor` is enabled, the telemetry endpoint (optional).
	serviceMonitor: timoniv1.#Monitor & {
		// The namespaces the Service is selected from; empty means its
		// own namespace.
		namespaceSelector?: [...string & =~".+"]
		// Override the label selector matching the Service.
		selectorOverride?: {[string]: string}

		// Scrape settings of the metrics endpoint.
		http: timoniv1.#MonitorEndpoint & {enableHttp2: *false | bool}

		// Scrape settings of the telemetry endpoint.
		metrics: timoniv1.#MonitorEndpoint & {enableHttp2: *false | bool}
	}

	// NetworkPolicy settings; the default rules allow the serving ports
	// in and DNS and the Kubernetes API out.
	networkPolicy: {
		enabled: *false | bool
		ingress: *[{
			ports: [
				{port: "http", protocol: "TCP"},
				if selfMonitor.enabled {
					{port: "metrics", protocol: "TCP"}
				},
			]
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
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			"\(config.metadata.name)-sa": #ServiceAccount & {_config: config}
		}

		if config.rbac.create {
			if config.rbac.useClusterRole {
				"\(config.metadata.name)-cr": #ClusterRole & {_config: config}
				"\(config.metadata.name)-crb": #ClusterRoleBinding & {_config: config}
			}
			if !config.rbac.useClusterRole {
				for ns in config.namespaces {
					"\(config.metadata.name)-role-\(ns)": #Role & {_config: config, #namespace: ns}
					"\(config.metadata.name)-rb-\(ns)": #RoleBinding & {_config: config, #namespace: ns}
				}

				// The auth filter and Custom Resource State permissions
				// are cluster-scoped and cannot be granted through the
				// namespaced Roles.
				if config.authFilter.enabled || config.customResourceState.enabled {
					"\(config.metadata.name)-cluster-access-cr": #ClusterAccessClusterRole & {_config: config}
					"\(config.metadata.name)-cluster-access-crb": #ClusterAccessClusterRoleBinding & {_config: config}
				}
			}
			if config.autosharding.enabled {
				"\(config.metadata.name)-stsdiscovery-role": #StsDiscoveryRole & {_config: config}
				"\(config.metadata.name)-stsdiscovery-rb": #StsDiscoveryRoleBinding & {_config: config}
			}
		}

		if config.customResourceState.enabled if config.customResourceState.existingConfigMap == _|_ {
			"\(config.metadata.name)-crs-cm": config._crsConfigMap
		}

		"\(config.metadata.name)-svc": #Service & {_config: config}

		if !config.autosharding.enabled {
			"\(config.metadata.name)-deploy": #Deployment & {_config: config}
		}
		if config.autosharding.enabled {
			"\(config.metadata.name)-sts": #StatefulSet & {_config: config}
		}

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
	}
}
