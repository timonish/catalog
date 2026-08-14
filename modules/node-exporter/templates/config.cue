package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// The default node affinity keeps the exporter off nodes without a
// kubelet-managed host to observe (AWS Fargate and virtual-kubelet
// providers). User-supplied affinity rules replace it entirely.
#DefaultAffinity: {
	nodeAffinity: requiredDuringSchedulingIgnoredDuringExecution: nodeSelectorTerms: [{
		matchExpressions: [{
			key:      "eks.amazonaws.com/compute-type"
			operator: "NotIn"
			values: ["fargate"]
		}, {
			key:      "type"
			operator: "NotIn"
			values: ["virtual-kubelet"]
		}]
	}]
}

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
	// and are set in `images.cue` by upengine.
	image: timoniv1.#Image

	// References to secrets used for pulling images from private registries.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// Run the pods in the host network namespace, exposing the metrics
	// endpoint on the node address. Required for the network collectors
	// to observe the host interfaces.
	hostNetwork: *true | bool
	if hostNetwork {
		dnsPolicy: *"ClusterFirstWithHostNet" | "ClusterFirst" | "Default" | "None"
	}
	if !hostNetwork {
		dnsPolicy: *"ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	}

	// Share the host process ID namespace, required by the process
	// related collectors.
	hostPID: *true | bool

	// Share the host IPC namespace.
	hostIPC: *false | bool

	// Run the pods in the host user namespace. A dedicated user
	// namespace (`false`) is incompatible with the host network, PID
	// and IPC namespaces.
	hostUsers?:      bool
	_hostUsersGuard: "valid"
	_hostUsersGuard: [
		if hostUsers != _|_ if !hostUsers && (hostNetwork || hostPID || hostIPC) {
			"hostUsers: false requires hostNetwork, hostPID and hostIPC to be disabled"
		},
		"valid",
	][0]

	// Mount the node root filesystem (`/`) at `/host/root` read-only,
	// enabling the filesystem and udev collectors.
	hostRootFsMount: {
		enabled:          *true | bool
		mountPropagation: *"HostToContainer" | "None" | "Bidirectional"
	}

	// Mount propagation of the node proc filesystem mount (`/host/proc`).
	hostProcFsMount: mountPropagation?: "None" | "HostToContainer" | "Bidirectional"

	// Mount propagation of the node sys filesystem mount (`/host/sys`).
	hostSysFsMount: mountPropagation?: "None" | "HostToContainer" | "Bidirectional"

	// Listen on all interfaces; when disabled, the exporter binds to
	// the node address only.
	listenOnAllInterfaces: *true | bool

	// Extra command line arguments appended after the generated ones,
	// e.g. `"--collector.textfile.directory=/run/prometheus"`.
	extraArgs: *[] | [...string]

	// Environment variables for the node-exporter container.
	env?: [...corev1.#EnvVar]

	// Extra volumes and volume mounts, e.g. hostPath volumes for the
	// textfile collector. The `proc` and `sys` host volumes are always
	// present — and `root` while `hostRootFsMount` is enabled — and can
	// also be mounted into extra containers.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Extra containers and init containers added to the pods, e.g.
	// sidecars writing textfile collector metrics.
	extraContainers?: [...corev1.#Container]
	initContainers?: [...corev1.#Container]

	// The container resource requirements (optional).
	resources?: timoniv1.#ResourceRequirements

	// The container termination message settings (optional).
	terminationMessagePath?:   string & =~".+"
	terminationMessagePolicy?: "File" | "FallbackToLogsOnError"

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

	// The liveness probe of the node-exporter container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path:   *"/" | string
			port:   *service.portName | string | int
			scheme: *"HTTP" | "HTTPS"
		}
		initialDelaySeconds: *0 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *1 | int
		failureThreshold:    *3 | int
		successThreshold:    *1 | int
	}

	// The readiness probe of the node-exporter container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path:   *"/" | string
			port:   *service.portName | string | int
			scheme: *"HTTP" | "HTTPS"
		}
		initialDelaySeconds: *0 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *1 | int
		failureThreshold:    *3 | int
		successThreshold:    *1 | int
	}

	// Pod optional settings.
	podLabels?: timoniv1.#Labels

	// Annotations added to the pods; the default marks them safe to
	// evict for the cluster autoscaler. A user-supplied struct replaces
	// the default.
	podAnnotations: *{"cluster-autoscaler.kubernetes.io/safe-to-evict": "true"} | timoniv1.#Annotations

	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}

	// The pod tolerations; by default the exporter runs on every
	// schedulable node, tainted ones included.
	tolerations: *[{operator: "Exists", effect: "NoSchedule"}] | [...corev1.#Toleration]

	// The pod affinity rules. As a per-node workload the DaemonSet has
	// no replicas to spread, so the anti-affinity presets do not apply;
	// the default keeps the exporter off Fargate nodes and virtual
	// kubelets, and user-supplied rules replace it entirely.
	affinity: *#DefaultAffinity | corev1.#Affinity

	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	dnsConfig?:                     corev1.#PodDNSConfig
	priorityClassName?:             string & =~".+"
	schedulerName?:                 string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

	// Mount the service account token into the pod; node-exporter does
	// not use the Kubernetes API.
	automountServiceAccountToken: *false | bool

	// The DaemonSet rolling update strategy (optional).
	strategy?: appsv1.#DaemonSetUpdateStrategy

	// The number of old ControllerRevisions to retain.
	revisionHistoryLimit?: int & >=0

	// Labels and annotations added to the DaemonSet.
	daemonsetLabels?:      timoniv1.#Labels
	daemonsetAnnotations?: timoniv1.#Annotations

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
		labels?:      timoniv1.#Labels
		annotations?: timoniv1.#Annotations
		// References to secrets set on the ServiceAccount for pulling
		// images from private registries.
		imagePullSecrets?: [...timoniv1.#ObjectReference]
		// The token is mounted through the pod setting instead.
		automountServiceAccountToken: *false | bool
	}

	// Service settings. The Service is optional for setups scraping the
	// pods directly through the `podMonitor`.
	service: {
		enabled: *true | bool
		type:    *"ClusterIP" | "NodePort" | "LoadBalancer"

		// The port of the metrics endpoint on the Service.
		port: *9100 | int & >0 & <=65535

		// The port the exporter listens on; defaults to the Service
		// port. With `hostNetwork` this is the port claimed on every
		// node.
		targetPort: *port | int & >0 & <=65535

		// The name of the metrics port on the Service and the container.
		portName: *"metrics" | string & =~".+"

		clusterIP?: string & =~".+"
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
		externalIPs?: [...string]
		if type == "NodePort" {
			// Zero lets the cluster assign the node port.
			nodePort: *0 | int & >=0 & <=32767
		}
		if type == "LoadBalancer" {
			loadBalancerIP?:    string & =~".+"
			loadBalancerClass?: string & =~".+"
			loadBalancerSourceRanges?: [...string]
		}
		if type != "ClusterIP" {
			externalTrafficPolicy?: "Cluster" | "Local"
		}
		internalTrafficPolicy?: "Cluster" | "Local"

		// Annotate the Service for Prometheus annotation-based
		// discovery.
		prometheusScrape: *true | bool

		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
	}

	// Addresses of node exporters running outside the cluster, added to
	// the Service as static Endpoints on port 9100.
	endpoints: *[] | [...string & =~".+"]

	_serviceGuard: "valid"
	_serviceGuard: [
		if serviceMonitor.enabled && !service.enabled {
			"serviceMonitor requires service.enabled"
		},
		if len(endpoints) > 0 && !service.enabled {
			"endpoints requires service.enabled"
		},
		"valid",
	][0]

	// Prometheus Operator ServiceMonitor for the metrics endpoint
	// (optional).
	serviceMonitor: timoniv1.#MonitorValues & {
		// Override the label selector matching the Service.
		selectorOverride?: {[string]: string}

		// Attach node metadata to the discovered targets
		// (Prometheus 2.35+).
		attachMetadata?: node: bool

		// Basic authentication credentials of the scrape requests.
		basicAuth?: {...}
	}

	// Prometheus Operator PodMonitor scraping the pods directly, for
	// large clusters where the number of exporter endpoints behind a
	// single Service becomes a bottleneck (optional).
	podMonitor: timoniv1.#MonitorValues & {
		// The HTTP path to scrape metrics from.
		path: *"/metrics" | string & =~".+"

		// Basic authentication credentials of the scrape requests.
		basicAuth?: {...}

		// Keep the timestamps present in the scraped data.
		honorTimestamps: *true | bool

		// Drop pods not in the Running phase.
		filterRunning: *true | bool

		// Follow HTTP 3xx redirects.
		followRedirects: *false | bool

		// Optional HTTP URL parameters.
		params?: {[string]: [...string]}

		// OAuth2 settings of the scrape requests (Prometheus 2.27+).
		oauth2?: {...}

		// Authorization header settings of the scrape requests.
		authorization?: {...}

		// Attach node metadata to the discovered targets
		// (Prometheus 2.35+).
		attachMetadata?: node: bool

		// Override the label selector matching the pods.
		selectorOverride?: {[string]: string}
	}

	// NetworkPolicy settings; the default rules allow the metrics port
	// in and deny all egress, as the exporter makes no outbound
	// connections.
	networkPolicy: {
		enabled: *false | bool
		ingress: *[{
			ports: [
				{port: service.targetPort, protocol: "TCP"},
			]
		}] | [...netv1.#NetworkPolicyIngressRule]
		egress: *[] | [...netv1.#NetworkPolicyEgressRule]
	}

	// VerticalPodAutoscaler for the DaemonSet (optional); requires the
	// autoscaling.k8s.io CRDs, e.g. from the vertical-pod-autoscaler
	// module.
	verticalPodAutoscaler: {
		enabled: *false | bool

		// The recommender responsible for generating recommendations;
		// empty selects the default recommender.
		recommenders?: [...{name!: string & =~".+"}]

		// The resources the autoscaler controls; empty means CPU and
		// memory.
		controlledResources?: [..."cpu" | "memory"]

		// Whether recommendations apply to requests only or to both
		// requests and limits.
		controlledValues?: "RequestsOnly" | "RequestsAndLimits"

		// The maximum and minimum resources allowed per pod.
		maxAllowed?: {
			cpu?:    timoniv1.#CPUQuantity
			memory?: timoniv1.#MemoryQuantity
		}
		minAllowed?: {
			cpu?:    timoniv1.#CPUQuantity
			memory?: timoniv1.#MemoryQuantity
		}

		// How the recommendations are applied to the pods.
		updatePolicy?: {
			minReplicas?: int & >=1
			updateMode?:  "Off" | "Initial" | "Recreate" | "Auto"
		}
	}
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	objects: {
		if config.serviceAccount.create {
			"\(config.metadata.name)-sa": #ServiceAccount & {_config: config}
		}

		if config.service.enabled {
			"\(config.metadata.name)-svc": #Service & {_config: config}
		}

		if len(config.endpoints) > 0 {
			"\(config.metadata.name)-ep": #Endpoints & {_config: config}
		}

		"\(config.metadata.name)-ds": #DaemonSet & {_config: config}

		if config.serviceMonitor.enabled {
			"\(config.metadata.name)-monitor": #ServiceMonitor & {_config: config}
		}

		if config.podMonitor.enabled {
			"\(config.metadata.name)-podmonitor": #PodMonitor & {_config: config}
		}

		if config.networkPolicy.enabled {
			"\(config.metadata.name)-netpol-ingress": #NetworkPolicyIngress & {_config: config}
			"\(config.metadata.name)-netpol-egress": #NetworkPolicyEgress & {_config: config}
		}

		if config.verticalPodAutoscaler.enabled {
			"\(config.metadata.name)-vpa": #VerticalPodAutoscaler & {_config: config}
		}
	}
}
