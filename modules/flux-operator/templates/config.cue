package templates

import (
	"encoding/yaml"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Duration is a string in the Go duration format, e.g. `5m` or `1h30m`.
#Duration: string & =~"^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"

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

	// Extra annotations added to all resources.
	commonAnnotations?: timoniv1.#Annotations
	if commonAnnotations != _|_ {
		metadata: annotations: commonAnnotations
	}

	// Label selector common to all resources.
	selector: timoniv1.#Selector & {#Name: metadata.name}

	// The container image repository, tag, digest and pull policy.
	// The default repository and tag track the upstream release
	// and are set in `images.cue` by upengine.
	image: timoniv1.#Image

	// References to secrets used for pulling images from private registries.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// Custom resource definition settings. Set `install: false` when
	// the CRDs are managed outside of this module. `keep: true`
	// preserves the CRDs on uninstall; without it, deleting the
	// instance deletes the CRDs and thereby every
	// fluxcd.controlplane.io custom resource in the cluster.
	crds: {
		install: *true | bool
		keep:    *false | bool
	}

	// Multitenancy lockdown for the ResourceSet APIs: reconcile the
	// resources with the given service account instead of
	// cluster-admin, and pin the workload identity service account.
	multitenancy: {
		enabled:                               *false | bool
		enabledForWorkloadIdentity:            *false | bool
		defaultServiceAccount:                 *"flux-operator" | string & =~".+"
		defaultWorkloadIdentityServiceAccount: *"flux-operator" | string & =~".+"
	}

	// The interval at which the FluxReport is computed.
	reporting: interval: *"5m" | #Duration

	// The log verbosity of the operator.
	logLevel: *"info" | "debug" | "error"

	// The Flux Status web server settings.
	web: {
		// Serve the Flux Status web interface on port 9080.
		enabled: *true | bool

		// The Flux Status Page configuration, rendered into a
		// hash-named immutable Secret so configuration changes roll
		// the pods.
		config?: #WebConfig

		// Load the Flux Status Page configuration from an existing
		// Secret in the instance namespace carrying the Web Config API
		// document under the `config.yaml` key, instead of rendering
		// one from `config`. The operator reads the Secret through the
		// Kubernetes API and reloads the configuration on change.
		configSecretName?: string & =~".+"

		// How GitOps actions are authorized, unified into
		// `config.userActions.access` (CUE rejects conflicting
		// settings between the two). Set it explicitly when the
		// configuration comes from an existing Secret
		// (`configSecretName`) so the ClusterRole rules rendered in
		// `serverOnly` mode match the access mode of the loaded
		// configuration.
		userActions: access?: "Impersonated" | "FineGrained"
		if userActions.access != _|_ && configSecretName == _|_ {
			// The hidden alias pins the concrete value; referencing
			// userActions.access directly in the comprehension body
			// resolves to the field's disjunction instead.
			_access: userActions.access
			config: userActions: access: _access
		}

		// Run only the Flux Status web server, without the operator
		// controllers; requires a separate instance running the
		// operator. The service account is bound to a read-only
		// ClusterRole instead of cluster-admin.
		serverOnly: *false | bool

		// The number of web server replicas, applied only in
		// `serverOnly` mode; the operator deployment leaves the
		// replica count at the API default of one.
		serverReplicas: *1 | int & >=0

		// NetworkPolicy allowing ingress to the web interface from any
		// namespace, and to the metrics port when the ServiceMonitor
		// is enabled.
		networkPolicy: create: *true | bool

		// User access management roles: `createRoles` renders the
		// `flux-web-user` and `flux-web-admin` ClusterRoles to bind
		// web users to, and `createAggregation` renders the
		// `flux-web-edit` ClusterRole aggregated into the Kubernetes
		// `edit` role.
		rbac: {
			createRoles:       *true | bool
			createAggregation: *false | bool
		}

		// Ingress for the web interface (optional).
		ingress: {
			enabled:    *false | bool
			className?: string & =~".+"
			if enabled {
				hosts: [#IngressHost, ...#IngressHost]
			}
			tls?: [...networkingv1.#IngressTLS]
			annotations?: timoniv1.#Annotations
			labels?:      timoniv1.#Labels
		}

		// Gateway API HTTPRoute for the web interface (optional), an
		// alternative to the Ingress. The route backend is generated
		// by the module; each rule takes matches and filters.
		httpRoute: {
			enabled: *false | bool
			if enabled {
				parentRefs: [{...}, ...{...}]
			}
			hostnames?: [...string & =~".+"]
			rules: *[{matches: [{path: {type: "PathPrefix", value: "/"}}]}] | [...{
				matches?: [...{...}]
				filters?: [...{...}]
			}]
			annotations?: timoniv1.#Annotations
			labels?:      timoniv1.#Labels
		}
	}

	// Whether the instance runs only the web server.
	_serverOnly: web.enabled && web.serverOnly

	// Whether the web configuration is rendered into a Secret.
	_createWebConfigSecret: web.enabled && web.config != _|_

	// Whether the web configuration is mounted from an existing Secret.
	_useWebConfigSecret: web.enabled && web.configSecretName != _|_

	// Whether GitOps actions run with the web server's own privileges,
	// from the explicit access value or the inline configuration.
	_webFineGrained: [
		if web.userActions.access != _|_ {
			web.userActions.access == "FineGrained"
		},
		if web.config != _|_
		if web.config.userActions != _|_
		if web.config.userActions.access != _|_ {
			web.config.userActions.access == "FineGrained"
		},
		false,
	][0]

	_guard: "valid"
	_guard: [
		if web.config != _|_ && web.configSecretName != _|_ {
			"web.config and web.configSecretName are mutually exclusive"
		},
		if web.ingress.enabled && !web.enabled {
			"web.ingress requires web.enabled"
		},
		if web.httpRoute.enabled && !web.enabled {
			"web.httpRoute requires web.enabled"
		},
		"valid",
	][0]

	// The Web Config API document rendered into a hash-named immutable
	// Secret; the object name embeds the hash of the data so
	// configuration changes roll the pods.
	if web.config != _|_ {
		_webConfigSecret: timoniv1.#ImmutableConfig & {
			#Kind:   timoniv1.#SecretKind
			#Suffix: "-web-config"
			#Meta:   metadata
			#Data: "config.yaml": yaml.Marshal({
				apiVersion: "web.fluxcd.controlplane.io/v1"
				kind:       "Config"
				spec:       web.config
			})
		}
	}

	// Marketplace deployment settings for the enterprise distribution.
	marketplace: {
		type?:    string & =~".+"
		account?: string & =~".+"
		license?: string & =~".+"
	}

	// Kubernetes API priority and fairness: a FlowSchema assigning the
	// operator requests — and those of the given extra service
	// accounts, e.g. the Flux controllers — to the priority level.
	// Requires Kubernetes 1.29 or newer.
	apiPriority: {
		enabled: *false | bool
		level:   *"workload-high" | string & =~".+"
		extraServiceAccounts: *[] | [...{
			name:      string & =~".+"
			namespace: string & =~".+"
		}]
	}

	// Extra command line arguments appended after the generated ones;
	// flags override the generated settings.
	extraArgs: *[] | [...string]

	// Environment variables for the operator container, appended after
	// the generated ones.
	env?: [...corev1.#EnvVar]

	// The container resource requirements, matching the upstream
	// defaults.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"64Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			cpu:    *"2000m" | timoniv1.#CPUQuantity
			memory: *"1Gi" | timoniv1.#MemoryQuantity
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
			port: *8081 | string | int
		}
		initialDelaySeconds: *15 | int
		periodSeconds:       *20 | int
	}

	// The readiness probe of the operator container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/readyz" | string
			port: *8081 | string | int
		}
		initialDelaySeconds: *5 | int
		periodSeconds:       *10 | int
	}

	// The startup probe of the operator container (optional).
	startupProbe?: corev1.#Probe

	// The volume backing /tmp: the operator writes temporary files
	// into it (the root filesystem is read-only).
	tmpVolume: *{emptyDir: {}} | corev1.#VolumeSource

	// Extra volumes and volume mounts, e.g. a CA certificates bundle.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Extra containers and init containers added to the pods.
	extraContainers?: [...corev1.#Container]
	initContainers?: [...corev1.#Container]

	// Pod optional settings.
	podLabels?:      timoniv1.#Labels
	podAnnotations?: timoniv1.#Annotations
	// Pods are scheduled on Linux nodes by default.
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	hostAliases?: [...corev1.#HostAlias]
	dnsConfig?: corev1.#PodDNSConfig
	// With the host network, the default flips so the pods keep
	// resolving cluster services.
	if hostNetwork {
		dnsPolicy: *"ClusterFirstWithHostNet" | "ClusterFirst" | "Default" | "None"
	}
	if !hostNetwork {
		dnsPolicy?: "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	}
	priorityClassName?:             string & =~".+"
	schedulerName?:                 string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

	// Expose the container ports (8080, 8081 and 9080) on the host
	// network; pods resolving cluster names may need
	// `dnsPolicy: "ClusterFirstWithHostNet"`.
	hostNetwork: *false | bool

	// Mount the service account token into the pod; the operator
	// requires it for the Kubernetes API access.
	automountServiceAccountToken: *true | bool

	// The affinity rules; Linux placement comes from the nodeSelector
	// default. `podAntiAffinity` accepts the `soft` (default), `hard`
	// and `none` presets for spreading the replicas across nodes, or
	// raw pod anti-affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}

	// The strategy to replace old pods with new ones.
	strategy?: appsv1.#DeploymentStrategy

	// The number of old ReplicaSets to retain.
	revisionHistoryLimit?: int & >=0

	// Labels and annotations added to the Deployment.
	deploymentLabels?:      timoniv1.#Labels
	deploymentAnnotations?: timoniv1.#Annotations

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

	// RBAC settings: `create` binds the operator service account to
	// the cluster-admin role, required for deploying the Flux
	// distribution from a FluxInstance; `aggregateClusterRoles` grants
	// the Kubernetes view, edit and admin roles access to the
	// ResourceSet APIs. Both are skipped in `web.serverOnly` mode,
	// where the read-only web ClusterRole is rendered instead.
	rbac: {
		create:                *true | bool
		aggregateClusterRoles: *true | bool
	}

	// Service settings. The metrics port is always exposed, the web
	// port follows `web.enabled`.
	service: {
		type:       *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:       *8080 | int & >0 & <=65535
		webPort:    *9080 | int & >0 & <=65535
		clusterIP?: string & =~".+"
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
		externalIPs?: [...string]
		if type != "ClusterIP" {
			// Zero lets the cluster assign the node ports.
			nodePort:    *0 | int & >=0 & <=32767
			webNodePort: *0 | int & >=0 & <=32767
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

	// PodDisruptionBudget, enabled by default when the web server
	// runs replicated in `serverOnly` mode. The mutually exclusive
	// `minAvailable` and `maxUnavailable` accept an absolute number
	// or a percentage; `minAvailable: 1` is the default.
	podDisruptionBudget: {
		enabled:                     *(_serverOnly && web.serverReplicas > 1) | bool
		unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
		*{minAvailable: *1 | int & >=0 | string & =~"^[0-9]+%$"} | {maxUnavailable: int & >=0 | string & =~"^[0-9]+%$"}
	}

	// Prometheus Operator ServiceMonitor for the operator metrics
	// endpoint (optional), created in the instance namespace.
	serviceMonitor: timoniv1.#MonitorValues
}

// IngressHost defines the schema for an Ingress rule of one host.
#IngressHost: {
	host: string & =~".+"
	paths: *[{path: "/", pathType: "Prefix"}] | [...{
		path:     string & =~".+"
		pathType: *"Prefix" | "Exact" | "ImplementationSpecific"
	}]
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

		if config.rbac.create && !config._serverOnly {
			"\(config.metadata.name)-crb": #AdminClusterRoleBinding & {_config: config}
		}

		if config.rbac.aggregateClusterRoles && !config._serverOnly {
			"\(config.metadata.name)-cr-edit": #AggregateEditClusterRole & {_config: config}
			"\(config.metadata.name)-cr-view": #AggregateViewClusterRole & {_config: config}
		}

		if config._serverOnly {
			"\(config.metadata.name)-web-cr": #WebClusterRole & {_config: config}
			"\(config.metadata.name)-web-crb": #WebClusterRoleBinding & {_config: config}
		}

		if config.web.enabled && config.web.rbac.createRoles {
			"flux-web-user-cr": #WebUserClusterRole & {_config: config}
			"flux-web-admin-cr": #WebAdminClusterRole & {_config: config}
		}

		if config.web.enabled && config.web.rbac.createAggregation {
			"flux-web-edit-cr": #WebEditClusterRole & {_config: config}
		}

		if config._createWebConfigSecret {
			"\(config.metadata.name)-web-config": config._webConfigSecret
		}

		"\(config.metadata.name)-svc": #Service & {_config: config}
		"\(config.metadata.name)-deploy": #Deployment & {_config: config}

		if config.web.enabled && config.web.networkPolicy.create {
			"\(config.metadata.name)-netpol": #NetworkPolicy & {_config: config}
		}

		if config.apiPriority.enabled {
			"\(config.metadata.name)-flowschema": #FlowSchema & {_config: config}
		}

		if config.web.ingress.enabled {
			"\(config.metadata.name)-ingress": #Ingress & {_config: config}
		}

		if config.web.httpRoute.enabled {
			"\(config.metadata.name)-httproute": #HTTPRoute & {_config: config}
		}

		if config.podDisruptionBudget.enabled {
			"\(config.metadata.name)-pdb": #PodDisruptionBudget & {_config: config}
		}

		if config.serviceMonitor.enabled {
			"\(config.metadata.name)-monitor": #ServiceMonitor & {_config: config}
		}
	}
}
