package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Runtime version info automatically set at apply-time.
	moduleVersion!: string
	kubeVersion!:   string

	// Metrics Server requires Kubernetes 1.25 or newer.
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

	// The number of pods replicas.
	replicas: *1 | int & >=0

	// The number of old ReplicaSets to retain.
	revisionHistoryLimit?: int & >=0

	// The strategy to replace old pods with new ones.
	strategy?: appsv1.#DeploymentStrategy

	// The container image repository, tag, digest and pull policy.
	// The default repository and tag track the upstream release
	// and are set in `images.cue` by upengine.
	image: timoniv1.#Image

	// References to secrets used for pulling images from private registries.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// The port on which the metrics-server container serves HTTPS.
	containerPort: *10250 | int & >0 & <=65535

	// The default command line arguments passed to metrics-server.
	// Override only when the upstream defaults are not suitable.
	defaultArgs: *[
		"--cert-dir=/tmp",
		"--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
		"--kubelet-use-node-status-port",
		"--metric-resolution=15s",
	] | [...string]

	// Extra command line arguments appended after the default ones,
	// e.g. `--kubelet-insecure-tls` for clusters with self-signed kubelet certs.
	extraArgs: *[] | [...string]

	// Environment variables for the metrics-server container.
	env?: [...corev1.#EnvVar]

	// The container resource requirements. Ignored when `addonResizer`
	// is enabled: the nanny owns the container resources and computes
	// them from the cluster size.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"200Mi" | timoniv1.#MemoryQuantity
		}
	}

	// The container security context, hardened by default. The pod
	// identity (UID/GID) is a pod-level concern, see podSecurityContext.
	securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext

	// The liveness probe of the metrics-server container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path:   *"/livez" | string
			port:   *"https" | string | int
			scheme: *"HTTPS" | string
		}
		initialDelaySeconds: *0 | int
		periodSeconds:       *10 | int
		failureThreshold:    *3 | int
	}

	// The readiness probe of the metrics-server container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path:   *"/readyz" | string
			port:   *"https" | string | int
			scheme: *"HTTPS" | string
		}
		initialDelaySeconds: *20 | int
		periodSeconds:       *10 | int
		failureThreshold:    *3 | int
	}

	// The volume backing the /tmp certificate directory.
	tmpVolume: *{emptyDir: {}} | corev1.#VolumeSource

	// Extra volumes and volume mounts for the metrics-server container.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Extra containers and init containers added to the pods.
	extraContainers?: [...corev1.#Container]
	initContainers?: [...corev1.#Container]

	// The security preset applied to the pod identity defaults: the
	// default "hardened" preset pins the image's non-root UID, while
	// "platform" leaves the identity to an admission controller
	// (e.g. an OpenShift SecurityContextConstraint).
	securityContextPreset: timoniv1.#SecurityContextPreset

	// The pod security context generated for the security preset.
	podSecurityContext: corev1.#PodSecurityContext & timoniv1.#PodSecurityContext & {
		#Preset: securityContextPreset
		#User:   1000
	}

	// Pod optional settings.
	podLabels?:      timoniv1.#Labels
	podAnnotations?: timoniv1.#Annotations
	// Pods are scheduled on Linux nodes by default.
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	dnsConfig?: corev1.#PodDNSConfig
	// Not in the chart: pods with hostNetwork enabled may need
	// ClusterFirstWithHostNet to resolve cluster services.
	dnsPolicy?:                     "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	schedulerName?:                 string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

	// Mount the service account token into the pod; metrics-server
	// requires it for accessing the Kubernetes API.
	automountServiceAccountToken: *true | bool

	// The priority class of the metrics-server pods.
	priorityClassName: *"system-cluster-critical" | string

	// Run the pods in the host network namespace. Required when the
	// API server cannot reach the pod network (e.g. Weave on EKS).
	hostNetwork: *false | bool

	// The affinity rules; Linux placement comes from the nodeSelector
	// default. `podAntiAffinity` accepts the `soft` (default), `hard`
	// and `none` presets for spreading the replicas across nodes, or
	// raw pod anti-affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}

	// Annotations added to the Deployment.
	deploymentAnnotations?: timoniv1.#Annotations

	// ServiceAccount settings. Set `create: false` to use an existing
	// service account referenced by `name`.
	serviceAccount: {
		create: *true | bool
		if create {
			name: *metadata.name | string
		}
		if !create {
			// Matches the chart: without a name, the pods run under the
			// namespace default service account.
			name: *"default" | string
		}
		labels?:      timoniv1.#Labels
		annotations?: timoniv1.#Annotations
		secrets?: [...timoniv1.#ObjectReference]
		// The token is mounted through the pod setting instead.
		automountServiceAccountToken: *false | bool
	}

	// Set `rbac.create: false` when the cluster roles and bindings
	// are managed outside of this module.
	rbac: create: *true | bool

	// Service settings.
	service: {
		type:       *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:       *443 | int & >0 & <=65535
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

	// The v1beta1.metrics.k8s.io APIService registration. Disable only
	// when the API service is managed outside of this module.
	apiService: {
		create:       *true | bool
		annotations?: timoniv1.#Annotations
		// Skip TLS verification of the metrics API. Defaults to false when
		// cert-manager injects the CA or when a caBundle is supplied.
		insecureSkipTLSVerify: *_insecureSkipTLSVerifyDefault | bool
		// PEM encoded CA bundle for TLS verification, base64 encoded at render time.
		caBundle?: string
	}
	_insecureSkipTLSVerifyDefault: [
		if tls.type == "cert-manager" && tls.certManager.addInjectorAnnotations {false},
		if apiService.caBundle != _|_ {false},
		true,
	][0]

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

	// Expose the /metrics endpoint without authorization.
	metrics: enabled: *false | bool

	// Prometheus Operator ServiceMonitor (optional), created in the
	// instance namespace. Enabling it also enables `metrics`.
	serviceMonitor: timoniv1.#MonitorValues & {
		// The metrics endpoint is served over TLS; the certificate is
		// not verified by default. With `tls.type: cert-manager`, set
		// `tlsConfig` to verify against the issued CA.
		scheme: *"https" | "http"
		tlsConfig: *{insecureSkipVerify: true} | {...}
	}
	if serviceMonitor.enabled {
		metrics: enabled: true
	}

	// The addon-resizer nanny sidecar (optional), scales the
	// metrics-server resources with the cluster size.
	addonResizer: {
		enabled:         *false | bool
		image:           timoniv1.#Image
		securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext
		resources: timoniv1.#ResourceRequirements & {
			requests: {
				cpu:    *"40m" | timoniv1.#CPUQuantity
				memory: *"25Mi" | timoniv1.#MemoryQuantity
			}
			limits: {
				cpu:    *"40m" | timoniv1.#CPUQuantity
				memory: *"25Mi" | timoniv1.#MemoryQuantity
			}
		}
		nanny: {
			cpu:            *"0m" | timoniv1.#CPUQuantity
			extraCpu:       *"1m" | timoniv1.#CPUQuantity
			memory:         *"0Mi" | timoniv1.#MemoryQuantity
			extraMemory:    *"2Mi" | timoniv1.#MemoryQuantity
			minClusterSize: *100 | int & >0
			pollPeriod:     *300000 | int & >0
			threshold:      *5 | int & >=0
		}
	}

	// TLS settings for serving the metrics API:
	// - `metrics-server`: the server generates a self-signed certificate;
	// - `cert-manager`: cert-manager.io issues and maintains the certificate;
	// - `existingSecret`: reuse an existing TLS secret.
	tls: {
		type:          *"metrics-server" | "cert-manager" | "existingSecret"
		clusterDomain: *"cluster.local" | string

		certManager: {
			// Add the cert-manager.io/inject-ca-from annotation to the APIService.
			addInjectorAnnotations: *true | bool
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
			duration?:    string
			renewBefore?: string
			annotations?: timoniv1.#Annotations
			labels?:      timoniv1.#Labels
		}

		if type == "existingSecret" {
			existingSecret: name: string & =~".+"
		}
		if type != "existingSecret" {
			existingSecret: name: *"" | string
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

		if config.rbac.create {
			"\(config.metadata.name)-cr": #ClusterRole & {_config: config}
			"\(config.metadata.name)-cr-aggregated": #AggregatedClusterRole & {_config: config}
			"\(config.metadata.name)-crb": #ClusterRoleBinding & {_config: config}
			"\(config.metadata.name)-crb-delegator": #AuthDelegatorClusterRoleBinding & {_config: config}
			"\(config.metadata.name)-rb-auth-reader": #AuthReaderRoleBinding & {_config: config}
		}

		"\(config.metadata.name)-svc": #Service & {_config: config}
		"\(config.metadata.name)-deploy": #Deployment & {_config: config}

		if config.apiService.create {
			"\(config.metadata.name)-apiservice": #APIService & {_config: config}
		}

		if config.podDisruptionBudget.enabled {
			"\(config.metadata.name)-pdb": #PodDisruptionBudget & {_config: config}
		}

		if config.serviceMonitor.enabled {
			"\(config.metadata.name)-monitor": #ServiceMonitor & {_config: config}
		}

		if config.addonResizer.enabled {
			"\(config.metadata.name)-nanny-cm": #NannyConfigMap & {_config: config}

			if config.rbac.create {
				"\(config.metadata.name)-nanny-cr": #NannyClusterRole & {_config: config}
				"\(config.metadata.name)-nanny-crb": #NannyClusterRoleBinding & {_config: config}
				"\(config.metadata.name)-nanny-role": #NannyRole & {_config: config}
				"\(config.metadata.name)-nanny-rb": #NannyRoleBinding & {_config: config}
			}
		}

		if config.tls.type == "cert-manager" {
			if !config.tls.certManager.existingIssuer.enabled {
				"\(config.metadata.name)-issuer": #Issuer & {_config: config}
			}
			"\(config.metadata.name)-cert": #Certificate & {_config: config}
		}
	}
}
