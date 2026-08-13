package config

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Workload defines the deployment settings common to the controller,
// webhook and cainjector components.
#Workload: W={
	// The security preset wired from the module's securityContextPreset
	// value. The upstream images pin no UID, so the pod identity is
	// left to the container runtime or the cluster's admission
	// controller under both presets.
	#Preset: timoniv1.#SecurityContextPreset

	// The number of pod replicas.
	replicas: *1 | int & >=0

	// The number of old ReplicaSets to retain.
	revisionHistoryLimit?: int & >=0

	// The strategy to replace old pods with new ones.
	strategy?: appsv1.#DeploymentStrategy

	// The container image repository, tag, digest and pull policy.
	// The default repository and tag track the upstream release
	// and are set in `images.cue` by upengine.
	image: timoniv1.#Image

	// The container resource requirements.
	resources?: timoniv1.#ResourceRequirements

	// The container security context, hardened by default.
	securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext

	// The pod security context generated for the security preset.
	podSecurityContext: corev1.#PodSecurityContext & timoniv1.#PodSecurityContext & {
		#Preset: W.#Preset
	}

	// Extra command line arguments appended after `--config`. Prefer
	// the typed `config` value; flags override the configuration file.
	extraArgs: *[] | [...string]

	// Environment variables for the component container.
	env?: [...corev1.#EnvVar]

	// Extra volumes and volume mounts added to the pod, e.g. a CA
	// bundle or serving certificate files.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Extra containers added to the pod.
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
	hostUsers?:         bool
	priorityClassName?: string & =~".+"
	runtimeClassName?:  string & =~".+"

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

	// PodDisruptionBudget (optional). The mutually exclusive
	// `minAvailable` and `maxUnavailable` accept an absolute number
	// or a percentage; `minAvailable: 1` is the default.
	// `unhealthyPodEvictionPolicy` requires Kubernetes 1.27 or newer
	// and is omitted on older clusters.
	podDisruptionBudget: {
		enabled:                     *false | bool
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
