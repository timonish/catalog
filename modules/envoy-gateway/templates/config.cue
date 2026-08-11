package templates

import (
	"encoding/yaml"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// PromDuration is a Prometheus duration, e.g. "30s", "1m30s"; a bare
// "0" is allowed.
#PromDuration: =~"^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$"

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Runtime version info automatically set at apply-time.
	moduleVersion!: string
	kubeVersion!:   string

	// The module requires Kubernetes 1.29 or newer.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.29.0"}

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
	// and are set in `versions.cue` by upengine. The Envoy proxy and
	// ratelimit data plane images are compiled into this binary.
	image: timoniv1.#Image & {
		repository: *#defaultImages."envoy-gateway".repository | string
		tag:        *#defaultImages."envoy-gateway".tag | string
		digest:     *#defaultImages."envoy-gateway".digest | string
	}

	// References to secrets used for pulling images from private registries.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// Custom resource definition settings. Set `install: false` when the
	// CRDs are managed outside of this module. `keep: true` preserves the
	// CRDs on uninstall; without it, deleting the instance deletes the
	// CRDs and thereby every gateway.envoyproxy.io custom resource in
	// the cluster. The Gateway API CRDs are not part of this module;
	// install them with the gateway-api module first.
	crds: {
		install: *true | bool
		keep:    *false | bool
	}

	// The Envoy Gateway configuration, rendered into an immutable
	// ConfigMap mounted at /config/envoy-gateway.yaml; configuration
	// changes roll the controller pods. The common fields are typed
	// below; every other EnvoyGateway API field (telemetry, rateLimit,
	// extensionManager, extensionApis, provider.kubernetes overrides,
	// etc.) passes through as-is and is validated by the controller at
	// startup.
	config: {
		// The controller name GatewayClasses reference in
		// `spec.controllerName`.
		gateway: controllerName: *"gateway.envoyproxy.io/gatewayclass-controller" | string & =~".+"

		// The log verbosity, overridable per component.
		logging: level: {
			default:  *"info" | "debug" | "warn" | "error"
			[string]: "debug" | "info" | "warn" | "error"
		}

		// Kubernetes is the only provider supported by this module.
		provider: {
			type: "Kubernetes"

			kubernetes: {
				// The shutdown manager sidecar of the managed Envoy
				// fleet runs this module's envoy-gateway image.
				shutdownManager: image: *_shutdownManagerImage | string

				...
			}

			...
		}

		...
	}

	// The image rendered into the shutdown manager configuration,
	// tracked together with the controller image.
	_shutdownManagerImage: image.reference

	// The topology injector mutating admission webhook, which labels
	// the Envoy fleet pods with their node's topology zone for
	// topology-aware routing (`service.trafficDistribution`).
	topologyInjector: {
		enabled:      *true | bool
		annotations?: timoniv1.#Annotations
	}
	if !topologyInjector.enabled {
		// Stop the controller from serving the injector when the
		// webhook is not installed.
		config: proxyTopologyInjector: disabled: true
	}

	// TLS bootstrap for the control plane certificates: the xDS server,
	// the managed Envoy fleet, the ratelimit service and the topology
	// injector webhook.
	// - `certgen`: the upstream certificate generator Job creates the
	//   `envoy-gateway`, `envoy`, `envoy-rate-limit` and
	//   `envoy-oidc-hmac` secrets with a self-signed CA and patches the
	//   webhook CA bundle. Existing secrets are never overwritten.
	// - `cert-manager`: cert-manager.io issues and rotates the
	//   certificate secrets from a module-managed CA, and injects the
	//   webhook CA bundle; the certgen Job only maintains the
	//   `envoy-oidc-hmac` secret, which cannot be expressed as a
	//   Certificate.
	tls: {
		mode: *"certgen" | "cert-manager"

		certManager: {
			// Issue the CA certificate from an existing issuer instead
			// of the module's self-signed one.
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
			// Validity of the CA and leaf certificates; cert-manager
			// rotates them ahead of expiry.
			caDuration?:  string & =~".+"
			duration?:    string & =~".+"
			renewBefore?: string & =~".+"
			annotations?: timoniv1.#Annotations
			labels?:      timoniv1.#Labels
		}
	}

	// The certificate generator Job settings.
	certgen: {
		annotations?:    timoniv1.#Annotations
		podAnnotations?: timoniv1.#Annotations
		podLabels?:      timoniv1.#Labels
		// Extra arguments appended to the `certgen` command.
		args: *[] | [...string]
		resources?: timoniv1.#ResourceRequirements
		affinity?:  corev1.#Affinity
		tolerations?: [...corev1.#Toleration]
		nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
		// The completed Job is deleted after this many seconds; it is
		// recreated on every apply.
		ttlSecondsAfterFinished: *30 | int & >=0
	}

	// The number of controller pods; ignored when the autoscaler is
	// enabled. Scaling to zero suspends the control plane.
	replicas: *1 | int & >=0

	// HorizontalPodAutoscaler for the controller (optional). When
	// enabled, the Deployment leaves the replica count to the
	// autoscaler.
	hpa: {
		enabled:     *false | bool
		minReplicas: *1 | int & >0
		maxReplicas: *minReplicas | int & >=minReplicas
		metrics: *[] | [...]
		behavior?: {...}
	}

	// The ports of the controller container and Service: xDS gRPC,
	// ratelimit discovery, Wasm HTTP server and metrics.
	ports: {
		grpc:      *18000 | int & >0 & <=65535
		ratelimit: *18001 | int & >0 & <=65535
		wasm:      *18002 | int & >0 & <=65535
		metrics:   *19001 | int & >0 & <=65535
	}

	// Service settings. The Service is named `envoy-gateway`: the
	// managed Envoy fleet dials the xDS server at that fixed DNS name.
	service: {
		type:         *"ClusterIP" | "NodePort" | "LoadBalancer"
		annotations?: timoniv1.#Annotations
		labels?:      timoniv1.#Labels
		// Prefer routing to topologically closer controller pods,
		// e.g. `PreferClose`; requires the topology injector.
		trafficDistribution?: string & =~".+"
		ipFamilies?: [..."IPv4" | "IPv6"]
		ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
		externalIPs?: [...string]
		if type == "LoadBalancer" {
			loadBalancerIP?:    string & =~".+"
			loadBalancerClass?: string & =~".+"
			loadBalancerSourceRanges?: [...string]
		}
		if type != "ClusterIP" {
			externalTrafficPolicy?: "Cluster" | "Local"
		}
	}

	// The cluster domain used for the generated in-cluster addresses.
	kubernetesClusterDomain: *"cluster.local" | string & =~".+"

	// The controller container resource requirements.
	resources: timoniv1.#ResourceRequirements & {
		requests: {
			cpu:    *"100m" | timoniv1.#CPUQuantity
			memory: *"256Mi" | timoniv1.#MemoryQuantity
		}
		limits: {
			memory: *"1024Mi" | timoniv1.#MemoryQuantity
		}
	}

	// The security profile applied to the pod identity defaults: the
	// default "hardened" profile pins the image's non-root UID, while
	// "platform" leaves the identity to an admission controller
	// (e.g. an OpenShift SecurityContextConstraint).
	securityProfile: timoniv1.#SecurityProfile

	// The container security context, hardened by default.
	securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext

	// The pod security context generated for the security profile.
	podSecurityContext: corev1.#PodSecurityContext & timoniv1.#PodSecurityContext & {
		#Profile: securityProfile
		#User:    65532
	}

	// The startup probe of the controller container; the generous
	// failure threshold covers cache priming on large clusters before
	// the liveness probe takes over.
	startupProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *8081 | string | int
		}
		periodSeconds:    *1 | int & >0
		timeoutSeconds:   *1 | int & >0
		failureThreshold: *30 | int & >0
		successThreshold: *1 | int & >0
	}

	// The liveness probe of the controller container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *8081 | string | int
		}
		periodSeconds:    *20 | int & >0
		timeoutSeconds:   *1 | int & >0
		failureThreshold: *3 | int & >0
		successThreshold: *1 | int & >0
	}

	// The readiness probe of the controller container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/readyz" | string
			port: *8081 | string | int
		}
		periodSeconds:    *10 | int & >0
		timeoutSeconds:   *1 | int & >0
		failureThreshold: *3 | int & >0
		successThreshold: *1 | int & >0
	}

	// The volume backing the Wasm module cache at /var/lib/eg/wasm,
	// writable because the root filesystem is read-only. Defaults to an
	// emptyDir; set e.g. a persistentVolumeClaim source to persist the
	// cache across controller restarts.
	wasmCacheVolume?: corev1.#VolumeSource

	// Environment variables appended to the controller container.
	env?: [...corev1.#EnvVar]

	// Extra volumes and volume mounts added to the controller pod.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Pod optional settings.
	podLabels?: timoniv1.#Labels
	podAnnotations: *{
		"prometheus.io/scrape": "true"
		"prometheus.io/port":   "\(ports.metrics)"
	} | timoniv1.#Annotations
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	tolerations?: [...corev1.#Toleration]
	affinity?: corev1.#Affinity
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	dnsPolicy?:                    "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	dnsConfig?:                    corev1.#PodDNSConfig
	priorityClassName?:            string & =~".+"
	schedulerName?:                string & =~".+"
	terminationGracePeriodSeconds: *10 | int & >=0

	// The strategy to replace old pods with new ones.
	strategy?: appsv1.#DeploymentStrategy

	// The number of old ReplicaSets to retain.
	revisionHistoryLimit?: int & >=0

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
			name: *"default" | string
		}
		annotations?: timoniv1.#Annotations
		// The token is mounted through the pod setting instead.
		automountServiceAccountToken: *false | bool
	}

	// PodDisruptionBudget (optional). The mutually exclusive
	// `minAvailable` and `maxUnavailable` accept an absolute number
	// or a percentage.
	podDisruptionBudget: {
		enabled:                     *false | bool
		unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
		*{minAvailable: *1 | int & >=0 | string & =~"^[0-9]+%$"} | {maxUnavailable: int & >=0 | string & =~"^[0-9]+%$"}
	}

	// Prometheus Operator ServiceMonitor for the controller metrics
	// endpoint (optional). The controller exposes its Prometheus
	// metrics on the `metrics` port; enabling this requires the
	// Prometheus Operator CRDs on the cluster.
	serviceMonitor: {
		enabled:           *false | bool
		additionalLabels?: timoniv1.#Labels
		annotations?:      timoniv1.#Annotations
		jobLabel:          *"app.kubernetes.io/name" | string
		// Scrape settings; the default empty string omits the field and
		// falls back to the Prometheus defaults.
		interval:      *"" | #PromDuration
		scrapeTimeout: *"" | #PromDuration
		honorLabels:   *false | bool
		scheme?:       "http" | "https"
		tlsConfig?: {...}
		bearerTokenFile?: string & =~".+"
		bearerTokenSecret?: {...}
		proxyUrl?:              string & =~".+"
		sampleLimit?:           int & >=0
		targetLimit?:           int & >=0
		labelLimit?:            int & >=0
		labelNameLengthLimit?:  int & >=0
		labelValueLengthLimit?: int & >=0
		metricRelabelings?: [...]
		relabelings?: [...]
		targetLabels?: [...string & =~".+"]
		podTargetLabels?: [...string & =~".+"]
	}

	// Set `rbac.create: false` when the roles and bindings are managed
	// outside of this module.
	rbac: create: *true | bool

	// The namespaces the provider watches for Gateway API resources,
	// read from `config.provider.kubernetes.watch.namespaces`; empty
	// means all namespaces. When set, the controller RBAC is scoped to
	// those namespaces with per-namespace roles.
	_watchNamespaces: [...string]
	_watchNamespaces: [
		if config.provider.kubernetes.watch != _|_
		if config.provider.kubernetes.watch.namespaces != _|_
		for ns in config.provider.kubernetes.watch.namespaces {ns},
	]

	// Whether the managed Envoy fleet runs in the Gateway namespaces
	// instead of the controller namespace, read from
	// `config.provider.kubernetes.deploy.type`.
	_gatewayNamespaceMode: *[
		if config.provider.kubernetes.deploy != _|_
		if config.provider.kubernetes.deploy.type != _|_ {
			config.provider.kubernetes.deploy.type == "GatewayNamespace"
		},
		false,
	][0] | bool

	// Whether the provider watch is configured, and whether it selects
	// namespaces by label instead of by name.
	_watchConfigured: *[
		if config.provider.kubernetes.watch != _|_ {true},
		false,
	][0] | bool
	_watchTypeNamespaceSelector: *[
		if config.provider.kubernetes.watch != _|_
		if config.provider.kubernetes.watch.type != _|_ {
			config.provider.kubernetes.watch.type == "NamespaceSelector"
		},
		false,
	][0] | bool

	// The EnvoyGateway configuration document and the immutable
	// ConfigMap carrying it; the object name embeds the hash of the
	// data so configuration changes roll the controller pods.
	_configData: "envoy-gateway.yaml": yaml.Marshal({
		apiVersion: "gateway.envoyproxy.io/v1alpha1"
		kind:       "EnvoyGateway"
		config
	})
	_configMap: timoniv1.#ImmutableConfig & {
		#Suffix: "-config"
		#Meta:   metadata
		#Data:   _configData
	}
	_configMapName: _configMap.metadata.name

	// The control plane object names expected by the envoy-gateway
	// binary: the Envoy fleet dials the xDS Service by DNS name, the
	// certificate secrets are looked up by name, and the certgen Job
	// patches the webhook configuration by name.
	_serviceName:  "envoy-gateway"
	_webhookName:  "envoy-gateway-topology-injector.\(metadata.namespace)"
	_caSecretName: "\(metadata.name)-ca"
	_certSecretNames: ["envoy-gateway", "envoy", "envoy-rate-limit"]
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	// The cert-manager objects are applied and health-checked before
	// the app objects, so the certificate secrets exist before the
	// certgen Job and the controller pods start.
	certObjects: {
		if config.tls.mode == "cert-manager" {
			if !config.tls.certManager.existingIssuer.enabled {
				"\(config.metadata.name)-selfsigned-issuer": #SelfSignedIssuer & {_config: config}
			}
			"\(config.metadata.name)-ca-cert": #CACertificate & {_config: config}
			"\(config.metadata.name)-ca-issuer": #CAIssuer & {_config: config}
			for cert in config._certSecretNames {
				"\(config.metadata.name)-cert-\(cert)": #ControlPlaneCertificate & {
					_config:   config
					_certName: cert
				}
			}
		}
	}

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
			// The certgen Job references this ServiceAccount
			// unconditionally; with `create: false` both accounts are
			// expected to be managed externally.
			"\(config.metadata.name)-certgen-sa": #CertgenServiceAccount & {_config: config}
		}

		if config.rbac.create {
			"\(config.metadata.name)-cr": #ClusterRole & {_config: config}
			"\(config.metadata.name)-crb": #ClusterRoleBinding & {_config: config}
			for ns in config._watchNamespaces {
				"\(config.metadata.name)-role-\(ns)": #WatchedNamespaceRole & {_config: config, #namespace: ns}
				"\(config.metadata.name)-rb-\(ns)": #WatchedNamespaceRoleBinding & {_config: config, #namespace: ns}
			}

			"\(config.metadata.name)-infra-role": #InfraManagerRole & {_config: config}
			"\(config.metadata.name)-infra-rb": #InfraManagerRoleBinding & {_config: config}
			if config._gatewayNamespaceMode {
				if config._watchConfigured {
					"\(config.metadata.name)-infra-tokenreview-cr": #InfraTokenReviewClusterRole & {_config: config}
					"\(config.metadata.name)-infra-tokenreview-crb": #InfraTokenReviewClusterRoleBinding & {_config: config}
					for ns in config._watchNamespaces {
						"\(config.metadata.name)-infra-role-\(ns)": #NamespacedInfraManagerRole & {_config: config, #namespace: ns}
						"\(config.metadata.name)-infra-rb-\(ns)": #NamespacedInfraManagerRoleBinding & {_config: config, #namespace: ns}
					}
				}
				if !config._watchConfigured || config._watchTypeNamespaceSelector {
					"\(config.metadata.name)-cluster-infra-cr": #ClusterInfraManagerClusterRole & {_config: config}
					"\(config.metadata.name)-cluster-infra-crb": #ClusterInfraManagerClusterRoleBinding & {_config: config}
				}
			}

			"\(config.metadata.name)-leader-role": #LeaderElectionRole & {_config: config}
			"\(config.metadata.name)-leader-rb": #LeaderElectionRoleBinding & {_config: config}

			"\(config.metadata.name)-certgen-role": #CertgenRole & {_config: config}
			"\(config.metadata.name)-certgen-rb": #CertgenRoleBinding & {_config: config}
			if config.topologyInjector.enabled && config.tls.mode == "certgen" {
				"\(config.metadata.name)-certgen-cr": #CertgenClusterRole & {_config: config}
				"\(config.metadata.name)-certgen-crb": #CertgenClusterRoleBinding & {_config: config}
			}
		}

		"\(config.metadata.name)-config": config._configMap
		"\(config.metadata.name)-certgen-job": #CertgenJob & {_config: config}
		"\(config.metadata.name)-svc": #Service & {_config: config}
		"\(config.metadata.name)-deploy": #Deployment & {_config: config}

		if config.topologyInjector.enabled {
			"\(config.metadata.name)-mwc": #MutatingWebhookConfiguration & {_config: config}
		}

		if config.hpa.enabled {
			"\(config.metadata.name)-hpa": #HorizontalPodAutoscaler & {_config: config}
		}

		if config.serviceMonitor.enabled {
			"\(config.metadata.name)-monitor": #ServiceMonitor & {_config: config}
		}

		if config.podDisruptionBudget.enabled {
			"\(config.metadata.name)-pdb": #PodDisruptionBudget & {_config: config}
		}
	}
}
