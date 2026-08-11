package config

import (
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Runtime version info automatically set at apply-time.
	moduleVersion!: string
	kubeVersion!:   string

	// The Vertical Pod Autoscaler requires Kubernetes 1.25 or newer.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.25.0"}

	// Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// Extra labels added to all resources.
	commonLabels?: timoniv1.#Labels
	if commonLabels != _|_ {
		metadata: labels: commonLabels
	}

	// CRD lifecycle settings. `install: false` skips the CRDs for
	// secondary instances; `keep: true` marks them with
	// `timoni.sh/prune: disabled` so an uninstall preserves the CRDs
	// and every VerticalPodAutoscaler custom resource in the cluster.
	crds: {
		install: *true | bool
		keep:    *false | bool
	}

	// References to secrets used for pulling images from private
	// registries, added to all service accounts.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// Set `rbac.create: false` when the roles and bindings are managed
	// outside of this module. `extraRules` appends rules to the
	// recommender metrics-reader ClusterRole, e.g. for reading custom
	// metrics.
	rbac: {
		create: *true | bool
		extraRules?: [...rbacv1.#PolicyRule]
	}

	// Prometheus ServiceMonitor settings; when enabled, a metrics
	// Service and a ServiceMonitor are created for every deployed
	// component, in the instance namespace.
	serviceMonitor: {
		enabled:           *false | bool
		additionalLabels?: timoniv1.#Labels
		annotations?:      timoniv1.#Annotations
		// The Prometheus job name follows the component label.
		jobLabel: *"app.kubernetes.io/component" | string
		// Scrape settings; the default empty string omits the field and
		// falls back to the Prometheus defaults.
		interval:      *"" | #PromDuration
		scrapeTimeout: *"" | #PromDuration
		honorLabels:   *false | bool
		scheme?:       "http" | "https"
		tlsConfig?: {...}
		bearerTokenFile?: string & =~".+"
		bearerTokenSecret?: {...}
		proxyUrl?: string & =~".+"
		metricRelabelings?: [...]
		relabelings?: [...]
		sampleLimit?:           int & >=0
		targetLimit?:           int & >=0
		labelLimit?:            int & >=0
		labelNameLengthLimit?:  int & >=0
		labelValueLengthLimit?: int & >=0
		targetLabels?: [...string & =~".+"]
		podTargetLabels?: [...string & =~".+"]
	}

	// The security profile applied to the pod identity defaults of all
	// components: the default "hardened" profile pins the upstream
	// image's non-root UID 65534, while "platform" leaves the identity
	// to an admission controller (e.g. an OpenShift
	// SecurityContextConstraint).
	securityProfile: timoniv1.#SecurityProfile

	// The recommender computes the recommended resource requests from
	// the metrics history.
	recommender: #RecommenderValues & {
		#Component: "recommender"
		#Profile:   securityProfile
		image: {
			repository: *#defaultImages.recommender.repository | string
			tag:        *#defaultImages.recommender.tag | string
			digest:     *#defaultImages.recommender.digest | string
		}
		serviceAccount: name:              *"\(metadata.name)-recommender" | string & =~".+"
		leaderElection: resourceNamespace: *metadata.namespace | string & =~".+"
	}

	// The updater evicts (or resizes in place) the pods whose resources
	// diverge from the recommendation.
	updater: #UpdaterValues & {
		#Component: "updater"
		#Profile:   securityProfile
		image: {
			repository: *#defaultImages.updater.repository | string
			tag:        *#defaultImages.updater.tag | string
			digest:     *#defaultImages.updater.digest | string
		}
		serviceAccount: name:              *"\(metadata.name)-updater" | string & =~".+"
		leaderElection: resourceNamespace: *metadata.namespace | string & =~".+"
	}

	// The admission controller mutates pod creation requests with the
	// recommended resources.
	admissionController: #AdmissionControllerValues & {
		#Component: "admission-controller"
		#Profile:   securityProfile
		image: {
			repository: *#defaultImages."admission-controller".repository | string
			tag:        *#defaultImages."admission-controller".tag | string
			digest:     *#defaultImages."admission-controller".digest | string
		}
		serviceAccount: name: *"\(metadata.name)-admission-controller" | string & =~".+"
	}
}

// RecommenderValues defines the recommender component settings.
#RecommenderValues: R={
	#Workload

	// Leader election for running multiple recommender replicas.
	leaderElection: #LeaderElection & {
		enabled:      *(R.replicas > 1) | bool
		resourceName: *"vpa-recommender-lease" | string & =~".+"
	}

	// Extra volumes and volume mounts for the recommender container.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]
}

// UpdaterValues defines the updater component settings.
#UpdaterValues: U={
	#Workload

	// Leader election for running multiple updater replicas.
	leaderElection: #LeaderElection & {
		enabled:      *(U.replicas > 1) | bool
		resourceName: *"vpa-updater-lease" | string & =~".+"
	}

	// Skip the PodDisruptionBudget check when applying in-place
	// updates, which are non-disruptive by design.
	inPlaceSkipDisruptionBudget: *true | bool

	// Extra volumes and volume mounts for the updater container.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]
}
