package config

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Duration in Go time.ParseDuration format, e.g. "15s" or "1h30m".
#Duration: string & =~"^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"

// Workload defines the deployment settings common to the recommender,
// updater and admission-controller components.
#Workload: W={
	// The component name, set by the module for each component and used
	// as the object name suffix and the component label value.
	#Component: string

	// The security preset wired from the module's securityContextPreset
	// value.
	#Preset: timoniv1.#SecurityContextPreset

	// Whether to deploy the component.
	enabled: *true | bool

	// The number of pod replicas. Leader election and the
	// PodDisruptionBudget default to enabled when running more than one
	// replica.
	replicas: *1 | int & >=0

	// The number of old ReplicaSets to retain.
	revisionHistoryLimit: *10 | int & >=0

	// The strategy to replace old pods with new ones.
	strategy?: appsv1.#DeploymentStrategy

	// The container image repository, tag, digest and pull policy.
	// The default repository and tag track the upstream release
	// and are set in `versions.cue` by upengine.
	image: timoniv1.#Image

	// The container resource requirements.
	resources?: timoniv1.#ResourceRequirements

	// The container security context, hardened by default.
	securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext

	// The pod security context generated for the security profile; the
	// upstream images run as the non-root UID 65534.
	podSecurityContext: corev1.#PodSecurityContext & timoniv1.#PodSecurityContext & {
		#Preset: W.#Preset
		#User:   65534
	}

	// Extra command line arguments appended to the component container.
	extraArgs: *[] | [...string]

	// Environment variables for the component container.
	env?: [...corev1.#EnvVar]

	// The liveness probe of the component container, served on the
	// metrics port.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path:   *"/health-check" | string
			port:   *"prometheus" | string | int
			scheme: *"HTTP" | string
		}
		initialDelaySeconds: *5 | int
		periodSeconds:       *10 | int
		failureThreshold:    *3 | int
	}

	// The readiness probe of the component container, served on the
	// metrics port.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path:   *"/health-check" | string
			port:   *"prometheus" | string | int
			scheme: *"HTTP" | string
		}
		periodSeconds:    *10 | int
		failureThreshold: *3 | int
	}

	// The metrics Service settings; the Service is created together
	// with the ServiceMonitor.
	metricsService: {
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
	}

	// Pod scheduling settings; pods are restricted to Linux nodes by
	// default and prefer spreading the component replicas across nodes.
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	// The affinity rules; `podAntiAffinity` accepts the `soft`
	// (default), `hard` and `none` presets for spreading the component
	// replicas across nodes, or raw pod anti-affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	// Pod optional settings.
	podLabels?:                     timoniv1.#Labels
	podAnnotations?:                timoniv1.#Annotations
	dnsPolicy?:                     "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	dnsConfig?:                     corev1.#PodDNSConfig
	priorityClassName?:             string & =~".+"
	schedulerName?:                 string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

	// Mount the service account token into the pod; the components
	// require it for accessing the Kubernetes API.
	automountServiceAccountToken: *true | bool

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

	// PodDisruptionBudget, created by default when running more than
	// one replica. The mutually exclusive `minAvailable` and
	// `maxUnavailable` accept an absolute number or a percentage;
	// `minAvailable: 1` is the default. `unhealthyPodEvictionPolicy`
	// requires Kubernetes 1.27 or newer and is omitted on older
	// clusters.
	podDisruptionBudget: {
		enabled:                     *(W.replicas > 1) | bool
		unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
		*{minAvailable: *1 | int & >=0 | string & =~"^[0-9]+%$"} | {maxUnavailable: int & >=0 | string & =~"^[0-9]+%$"}
	}
}

// LeaderElection defines the leader election settings of the
// recommender and updater components; enabled by default when running
// more than one replica.
#LeaderElection: {
	enabled: bool

	// The namespace of the lease resource; defaults to the instance
	// namespace.
	resourceNamespace: string & =~".+"

	// The name of the lease resource.
	resourceName: string & =~".+"

	// Duration that non-leader candidates wait after observing a
	// leadership renewal.
	leaseDuration: *"15s" | #Duration

	// Interval between attempts by the acting leader to renew the
	// leadership slot.
	renewDeadline: *"10s" | #Duration

	// Duration the clients wait between attempting acquisition and
	// renewal of a leadership.
	retryPeriod: *"2s" | #Duration
}
