package config

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Workload defines the deployment settings common to the controller,
// webhook and cert-controller components.
#Workload: W={
	// The security preset wired from the module's securityContextPreset
	// value. The upstream image runs as the non-root `nobody` user
	// (UID 65534), pinned by the hardened preset.
	#Preset: timoniv1.#SecurityContextPreset

	// The number of pod replicas.
	replicas: *1 | int & >=0

	// The number of old ReplicaSets to retain.
	revisionHistoryLimit?: int & >=0

	// The strategy to replace old pods with new ones.
	strategy?: appsv1.#DeploymentStrategy

	// The container resource requirements.
	resources?: timoniv1.#ResourceRequirements

	// The container security context, hardened by default.
	securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext

	// The pod security context generated for the security preset.
	podSecurityContext: corev1.#PodSecurityContext & timoniv1.#PodSecurityContext & {
		#Preset: W.#Preset
		#User:   65534
	}

	// The log level and timestamp encoding of the component.
	logLevel:        #LogLevel
	logTimeEncoding: #LogTimeEncoding

	// The Prometheus metrics endpoint and its optional Service.
	metrics: #MetricsValues

	// The port of the health endpoint serving the liveness and
	// readiness probes.
	healthPort: int & >0 & <=65535

	// Extra command line arguments appended after the generated ones.
	extraArgs: *[] | [...string]

	// Environment variables for the component container.
	env?: [...corev1.#EnvVar]

	// Extra volumes and volume mounts added to the pod, e.g. a CA
	// bundle or the metrics serving certificate.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Init containers and extra containers added to the pod.
	initContainers?: [...corev1.#Container]
	extraContainers?: [...corev1.#Container]

	// Pod scheduling settings; pods are restricted to Linux nodes by
	// default.
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	// The affinity rules; Linux placement comes from the nodeSelector
	// default. `podAntiAffinity` accepts the `soft` (default), `hard`
	// and `none` presets for spreading the component replicas across
	// nodes, or raw pod anti-affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	// Pod optional settings.
	podLabels?:      timoniv1.#Labels
	podAnnotations?: timoniv1.#Annotations
	dnsPolicy?:      "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	dnsConfig?:      corev1.#PodDNSConfig
	hostAliases?: [...corev1.#HostAlias]
	hostUsers?:                     bool
	priorityClassName?:             string & =~".+"
	schedulerName?:                 string & =~".+"
	runtimeClassName?:              string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

	// Run the pod on the host network; the dnsPolicy defaults to
	// `ClusterFirstWithHostNet` when set.
	hostNetwork: *false | bool
	if hostNetwork {
		dnsPolicy: *"ClusterFirstWithHostNet" | "ClusterFirst" | "Default" | "None"
	}

	// Mount the service account token into the pod; the components
	// require it for accessing the Kubernetes API.
	automountServiceAccountToken: *true | bool

	// Inject information about services into the pod's environment
	// variables.
	enableServiceLinks: *false | bool

	// Annotations added to the Deployment.
	deploymentAnnotations?: timoniv1.#Annotations

	// ServiceAccount settings. Set `create: false` to use an existing
	// service account referenced by `name`.
	serviceAccount: {
		create:       *true | bool
		name:         string & =~".+"
		labels?:      timoniv1.#Labels
		annotations?: timoniv1.#Annotations
		// The token is mounted through the pod setting instead.
		automountServiceAccountToken: *false | bool
	}

	// PodDisruptionBudget, enabled by default when `replicas` is
	// greater than one. The mutually exclusive `minAvailable` and
	// `maxUnavailable` accept an absolute number or a percentage;
	// `minAvailable: 1` is the default. `unhealthyPodEvictionPolicy`
	// requires Kubernetes 1.27 or newer and is omitted on older
	// clusters.
	podDisruptionBudget: {
		enabled:                     *(W.replicas > 1) | bool
		unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
		*{minAvailable: *1 | int & >=0 | string & =~"^[0-9]+%$"} | {maxUnavailable: int & >=0 | string & =~"^[0-9]+%$"}
	}

	// NetworkPolicy settings; the default rules allow the component's
	// serving ports in and DNS, HTTP(S) and the Kubernetes API out.
	networkPolicy: {
		enabled: *false | bool
		ingress: [...netv1.#NetworkPolicyIngressRule]
		egress: *[{
			ports: [
				{port: 80, protocol: "TCP"},
				{port: 443, protocol: "TCP"},
				{port: 53, protocol: "TCP"},
				{port: 53, protocol: "UDP"},
				{port: 6443, protocol: "TCP"},
			]
		}] | [...netv1.#NetworkPolicyEgressRule]
	}
}
