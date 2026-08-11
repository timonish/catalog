package config

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Duration in Go time.ParseDuration format, e.g. "15s" or "1h30m".
#Duration: string & =~"^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"

// Duration in Prometheus format, e.g. "30s" or "1m30s".
#PromDuration: string & =~"^([0-9]+(ms|s|m|h|d|w|y))+$"

// Workload defines the deployment settings common to the recommender,
// updater and admission-controller components.
#Workload: W={
	// The component name, set by the module for each component and used
	// as the object name suffix and the component label value.
	#Component: string

	// The security profile wired from the module's securityProfile
	// value.
	#Profile: timoniv1.#SecurityProfile

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
		#Profile: W.#Profile
		#User:    65534
	}

	// Extra command line arguments appended to the component container.
	extraArgs: *[] | [...string]

	// Environment variables for the component container.
	env?: [...corev1.#EnvVar]

	// Pod scheduling settings; pods are restricted to Linux nodes by
	// default and prefer spreading the component replicas across nodes.
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	affinity: *{
		podAntiAffinity: preferredDuringSchedulingIgnoredDuringExecution: [{
			weight: 100
			podAffinityTerm: {
				labelSelector: matchExpressions: [{
					key:      "app.kubernetes.io/component"
					operator: "In"
					values: [W.#Component]
				}]
				topologyKey: "kubernetes.io/hostname"
			}
		}]
	} | corev1.#Affinity
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]

	// Pod optional settings.
	podLabels?:         timoniv1.#Labels
	podAnnotations?:    timoniv1.#Annotations
	dnsPolicy?:         "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	priorityClassName?: string & =~".+"

	// Annotations added to the Deployment.
	deploymentAnnotations?: timoniv1.#Annotations

	// ServiceAccount settings. Set `create: false` to use an existing
	// service account referenced by `name`.
	serviceAccount: {
		create:                       *true | bool
		name:                         string & =~".+"
		labels?:                      timoniv1.#Labels
		annotations?:                 timoniv1.#Annotations
		automountServiceAccountToken: *true | bool
	}

	// PodDisruptionBudget settings; created by default when running
	// more than one replica, with `minAvailable` defaulting to 1 when
	// neither it nor `maxUnavailable` is set.
	podDisruptionBudget: {
		enabled:         *(W.replicas > 1) | bool
		minAvailable?:   int | string
		maxUnavailable?: int | string
		_guard:          "valid"
		_guard: [
			if minAvailable != _|_ && maxUnavailable != _|_ {
				"minAvailable and maxUnavailable are mutually exclusive"
			},
			"valid",
		][0]
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
