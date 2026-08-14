package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
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
	// and are set in `images.cue` by upengine.
	image: timoniv1.#Image

	// References to secrets used for pulling images from private registries.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// Custom resource definition settings. Set `install: false` when the
	// CRDs are managed outside of this module. `keep: true` preserves the
	// CRDs on uninstall; without it, deleting the instance deletes the
	// CRDs and thereby every fluentbit.fluent.io and fluentd.fluent.io
	// custom resource in the cluster.
	crds: {
		install: *true | bool
		keep:    *false | bool
	}

	// The container runtime of the cluster nodes, which determines the
	// container log path the operator configures the Fluent Bit agents
	// with.
	containerRuntime: *"containerd" | "crio" | "docker"

	// The container log path derived from the container runtime.
	_containerLogPath: [
		if containerRuntime == "docker" {"/var/lib/docker/containers"},
		"/var/log/containers",
	][0]
	_containerRootDir: [
		if containerRuntime == "docker" {"/var/lib/docker"},
		"/var/log",
	][0]

	// The number of operator replicas. Leader election is enabled
	// automatically when running more than one.
	replicas: *1 | int & >=0

	// Leader election for the controller manager, enabled by default
	// when `replicas` is greater than one.
	leaderElection: {
		enabled: *(replicas > 1) | bool
	}

	// Disable one of the component controllers to run the operator for
	// Fluent Bit or Fluentd only; empty runs both.
	disableComponentControllers: *"" | "fluent-bit" | "fluentd"

	// The namespaces watched for namespaced custom resources; empty
	// means all namespaces.
	watchNamespaces: *[] | [...string & =~".+"]

	// Extra command line arguments appended after the generated ones.
	extraArgs: *[] | [...string]

	// Environment variables for the operator container, appended after
	// the generated ones.
	env?: [...corev1.#EnvVar]

	// The container resource requirements.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"20Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"60Mi" | timoniv1.#MemoryQuantity
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
		#User:   65532
	}

	// The liveness probe of the operator container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *8081 | int
		}
		initialDelaySeconds: *15 | int
		periodSeconds:       *20 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *3 | int
		successThreshold:    *1 | int
	}

	// The readiness probe of the operator container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/readyz" | string
			port: *8081 | int
		}
		initialDelaySeconds: *5 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
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
	dnsPolicy?:                     "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	dnsConfig?:                     corev1.#PodDNSConfig
	priorityClassName?:             string & =~".+"
	schedulerName?:                 string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

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
		labels?:      timoniv1.#Labels
		annotations?: timoniv1.#Annotations
		// The token is mounted through the pod setting instead.
		automountServiceAccountToken: *false | bool
	}

	// Set `rbac.create: false` when the cluster roles and bindings are
	// managed outside of this module. The operator can only grant the
	// Fluent Bit and Fluentd workloads permissions it holds itself, so
	// `extraRules` extends its ClusterRole with the rules those
	// workloads need beyond the defaults.
	rbac: {
		create: *true | bool
		extraRules?: [...rbacv1.#PolicyRule]
	}

	// Service settings for the operator metrics endpoint. The operator
	// listens for metrics on the service port.
	service: {
		enabled:    *true | bool
		type:       *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:       *8080 | int & >0 & <=65535
		portName:   *"metrics" | string & =~".+"
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
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
	}

	// PodDisruptionBudget, enabled by default when `replicas` is
	// greater than one. The mutually exclusive `minAvailable` and
	// `maxUnavailable` accept an absolute number or a percentage;
	// `minAvailable: 1` is the default.
	podDisruptionBudget: {
		enabled:                     *(replicas > 1) | bool
		unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
		*{minAvailable: *1 | int & >=0 | string & =~"^[0-9]+%$"} | {maxUnavailable: int & >=0 | string & =~"^[0-9]+%$"}
	}

	// Prometheus Operator ServiceMonitor for the operator metrics
	// endpoint (optional), created in the instance namespace.
	serviceMonitor: timoniv1.#MonitorValues

	// The ServiceMonitor scrapes through the metrics Service.
	_serviceGuard: "valid"
	_serviceGuard: [
		if serviceMonitor.enabled && !service.enabled {
			"serviceMonitor requires service.enabled"
		},
		"valid",
	][0]

	// The environment file the operator writes into the Fluent Bit
	// agents it manages, rendered into a hash-named immutable
	// ConfigMap so content changes roll the operator pod.
	_envConfigMap: timoniv1.#ImmutableConfig & {
		#Suffix: "-env"
		#Meta:   metadata
		#Data: "fluent-bit.env": "CONTAINER_ROOT_DIR=\(_containerRootDir)\n"
	}
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
			if config.leaderElection.enabled {
				"\(config.metadata.name)-le-role": #LeaderElectionRole & {_config: config}
				"\(config.metadata.name)-le-rb": #LeaderElectionRoleBinding & {_config: config}
			}
		}

		"\(config.metadata.name)-env": config._envConfigMap

		if config.service.enabled {
			"\(config.metadata.name)-svc": #Service & {_config: config}
		}

		"\(config.metadata.name)-deploy": #Deployment & {_config: config}

		if config.podDisruptionBudget.enabled {
			"\(config.metadata.name)-pdb": #PodDisruptionBudget & {_config: config}
		}

		if config.serviceMonitor.enabled {
			"\(config.metadata.name)-monitor": #ServiceMonitor & {_config: config}
		}
	}
}
