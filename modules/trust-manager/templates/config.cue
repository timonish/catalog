package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Duration is a Go duration string, e.g. "15s", "1h30m".
#Duration: string & =~"^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Runtime version info automatically set at apply-time.
	moduleVersion!: string
	kubeVersion!:   string

	// trust-manager requires Kubernetes 1.25 or newer.
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

	// The number of pod replicas. trust-manager elects a leader, so
	// running more than one replica provides fast failover.
	replicas: *1 | int & >=0

	// The number of old ReplicaSets to retain.
	revisionHistoryLimit: *10 | int & >=0

	// The strategy to replace old pods with new ones.
	strategy?: appsv1.#DeploymentStrategy

	// The container image repository, tag, digest and pull policy.
	// The default repository and tag track the upstream release
	// and are set in `images.cue` by upengine.
	image: timoniv1.#Image

	// References to secrets used for pulling images from private
	// registries, attached to the ServiceAccount.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// The default CA package (optional, enabled by default): an init
	// container ships a package of publicly trusted certificates derived
	// from Debian's ca-certificates, enabling the `useDefaultCAs` source
	// on Bundles. The package version follows the Debian cadence
	// independently of the trust-manager releases.
	defaultPackage: {
		enabled:         *true | bool
		image:           timoniv1.#Image
		resources?:      timoniv1.#ResourceRequirements
		securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext
	}

	// The namespace used as the trust source: Bundle sources are read
	// from Secrets and ConfigMaps in this namespace only. Defaults to
	// the instance namespace.
	trust: namespace: *metadata.namespace | string & =~".+"

	// The namespaces trust-manager is allowed to write targets to.
	// By default targets are written to all namespaces with
	// cluster-scoped RBAC; restricting the list switches the ConfigMap,
	// Secret and Event grants to per-namespace Roles. The list must not
	// be empty: leave it unset for the all-namespaces default.
	targetNamespaces?: [string & =~".+", ...string & =~".+"]

	// Writing trust bundles to Secret targets (optional). trust-manager
	// only ever writes to Secrets explicitly allowed here: either every
	// Secret in the cluster (`authorizedSecretsAll`, use with caution —
	// it grants cluster-wide Secret read access) or the named Secrets
	// across all namespaces.
	secretTargets: {
		enabled:              *false | bool
		authorizedSecretsAll: *false | bool
		authorizedSecrets: *[] | [...string & =~".+"]
	}

	// Filter certificates expired at reconciliation time out of the
	// trust bundle targets.
	filterExpiredCertificates: *false | bool

	// Filter non-CA certificates out of the trust bundle targets.
	filterNonCACerts: *false | bool

	// The minimum TLS version of the webhook and metrics servers,
	// e.g. `VersionTLS13`; defaults to the Go minimum version.
	minTLSVersion?: string & =~".+"

	// Comma-separated list of cipher suites for the webhook and metrics
	// servers; defaults to the Go cipher suites.
	cipherSuites?: string & =~".+"

	// The log verbosity (1-5, higher is more verbose) and format.
	logLevel:  *1 | int & >=1 & <=5
	logFormat: *"text" | "json"

	// Leader election settings. The renew deadline must not exceed the
	// lease duration; both can be raised on clusters with an overloaded
	// API server to prevent restart loops.
	leaderElection: {
		enabled:       *true | bool
		leaseDuration: *"15s" | #Duration
		renewDeadline: *"10s" | #Duration
	}

	// The readiness probe of the trust-manager container; the listen
	// port and path are wired into the container arguments (the port
	// must be a number).
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/readyz" | string & =~"^/.*"
			port: *6060 | int & >0 & <=65535
		}
		initialDelaySeconds: *3 | int
		periodSeconds:       *7 | int
	}

	// The validating webhook guarding Bundle resources. Its serving
	// certificate is issued by cert-manager (a hard dependency of this
	// module) from a dedicated self-signed Issuer, and the CA is
	// injected into the webhook configuration by the cainjector.
	webhook: {
		// The host and port the webhook listens on inside the pod.
		host: *"0.0.0.0" | string & =~".+"
		port: *6443 | int & >0 & <=65535

		// Timeout of the admission review HTTP request.
		timeoutSeconds: *5 | int & >=1 & <=30

		// Run the pod in the host network namespace, e.g. for managed
		// clusters with a custom CNI where the control plane cannot
		// reach the pod network.
		hostNetwork: *false | bool

		// The Service exposing the webhook to the API server.
		service: {
			type: *"ClusterIP" | "NodePort" | "LoadBalancer"
			ipFamilies?: [..."IPv4" | "IPv6"]
			ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
			if type == "NodePort" {
				// Zero lets the cluster assign the node port.
				nodePort: *0 | int & >=0 & <=32767
			}
			annotations?: timoniv1.#Annotations
			labels?:      timoniv1.#Labels
		}

		tls: {
			// The webhook serving Certificate settings.
			certificate: {
				// Certificate duration; defaults to the cert-manager default.
				duration?: string & =~".+"
				// Labels and annotations added to the certificate Secret.
				secretTemplate: {
					annotations?: timoniv1.#Annotations
					labels?:      timoniv1.#Labels
				}
			}

			// Create an approver-policy CertificateRequestPolicy allowing
			// auto-approval of the webhook certificate, for clusters
			// running cert-manager with approver-policy installed.
			approverPolicy: {
				enabled: *false | bool
				// The namespace and ServiceAccount name of the cert-manager
				// installation granted use of the policy.
				certManagerNamespace:      *"cert-manager" | string & =~".+"
				certManagerServiceAccount: *"cert-manager" | string & =~".+"
			}
		}
	}

	// The Prometheus metrics endpoint, served on `/metrics`.
	metrics: {
		port: *9402 | int & >0 & <=65535
		// The Service exposing the metrics endpoint.
		service: {
			enabled: *true | bool
			type:    *"ClusterIP" | "NodePort" | "LoadBalancer"
			ipFamilies?: [..."IPv4" | "IPv6"]
			ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
			annotations?:    timoniv1.#Annotations
			labels?:         timoniv1.#Labels
		}
	}

	// Prometheus Operator ServiceMonitor (optional) for the metrics
	// Service, created in the instance namespace. Enabling it also
	// enables `metrics.service`.
	serviceMonitor: timoniv1.#MonitorValues
	if serviceMonitor.enabled {
		metrics: service: enabled: true
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

	// The container resource requirements.
	resources?: timoniv1.#ResourceRequirements

	// The container security context, hardened by default. The pod
	// identity (UID/GID) is a pod-level concern, see podSecurityContext.
	securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext

	// The security preset applied to the pod identity defaults: the
	// default "hardened" preset pins the image's non-root UID, while
	// "platform" leaves the identity to an admission controller
	// (e.g. an OpenShift SecurityContextConstraint).
	securityContextPreset: timoniv1.#SecurityContextPreset

	// The pod security context generated for the security preset.
	podSecurityContext: corev1.#PodSecurityContext & timoniv1.#PodSecurityContext & {
		#Preset: securityContextPreset
		#User:   65532
	}

	// Pod optional settings.
	podLabels?:      timoniv1.#Labels
	podAnnotations?: timoniv1.#Annotations
	// Pods are scheduled on Linux nodes by default; trust-manager does
	// not support Windows nodes.
	nodeSelector: *{(corev1.#LabelOSStable): "linux"} | {[string]: string}
	// The affinity rules; Linux placement comes from the nodeSelector
	// default. `podAntiAffinity` accepts the `soft` (default), `hard`
	// and `none` presets for spreading the replicas across nodes, or
	// raw pod anti-affinity rules.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}
	tolerations?: [...corev1.#Toleration]
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	dnsConfig?: corev1.#PodDNSConfig
	// Pods on the host network (webhook.hostNetwork) default to
	// ClusterFirstWithHostNet to resolve cluster services.
	if webhook.hostNetwork {
		dnsPolicy: *"ClusterFirstWithHostNet" | "ClusterFirst" | "Default" | "None"
	}
	if !webhook.hostNetwork {
		dnsPolicy?: "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	}
	priorityClassName?:             string & =~".+"
	schedulerName?:                 string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

	// Environment variables for the trust-manager container.
	env?: [...corev1.#EnvVar]

	// Annotations added to the Deployment.
	deploymentAnnotations?: timoniv1.#Annotations

	// Mount the service account token into the pod.
	automountServiceAccountToken: *true | bool

	// Extra volumes and volume mounts for the trust-manager container.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Extra command line arguments appended after the generated ones;
	// flags override the generated configuration.
	extraArgs: *[] | [...string]

	// ServiceAccount settings. Set `create: false` to use an existing
	// service account referenced by `name`.
	serviceAccount: {
		create: *true | bool
		if create {
			name: *metadata.name | string
		}
		if !create {
			// Matches the upstream default: without a name, the pods run
			// under the namespace default service account.
			name: *"default" | string
		}
		labels?:      timoniv1.#Labels
		annotations?: timoniv1.#Annotations
		// The token is mounted through the pod setting instead.
		automountServiceAccountToken: *false | bool
	}

	// Set `rbac.create: false` when the roles and bindings are managed
	// outside of this module. `aggregateClusterRoles` aggregates Bundle
	// read access into the OpenShift-style `cluster-reader` ClusterRole.
	rbac: {
		create:                *true | bool
		aggregateClusterRoles: *true | bool
	}

	// Install the Bundle CRD. Disable it when the CRD is managed
	// outside of this module; keep it (and thus all Bundles) around
	// when the instance is deleted.
	crds: {
		install: *true | bool
		keep:    *false | bool
	}

	// The namespaces receiving per-namespace RBAC when
	// `targetNamespaces` restricts the write scope: the targets, the
	// trust source namespace and the instance namespace, deduplicated.
	if targetNamespaces != _|_ {
		_rbacNamespaces: {
			for ns in targetNamespaces {(ns): true}
			(trust.namespace):    true
			(metadata.namespace): true
		}
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
				if config.metadata.annotations != _|_ {
					"crd-\(name)": metadata: annotations: config.metadata.annotations
				}

				// Keep the CRD (and thus all Bundles) around when the
				// instance is deleted.
				if config.crds.keep {
					"crd-\(name)": metadata: annotations: "timoni.sh/prune": "disabled"
				}
			}
		}

		if config.serviceAccount.create {
			"\(config.metadata.name)-sa": #ServiceAccount & {_config: config}
		}

		if config.rbac.create {
			"\(config.metadata.name)-cr": #ClusterRole & {_config: config}
			"\(config.metadata.name)-crb": #ClusterRoleBinding & {_config: config}
			"\(config.metadata.name)-role-trust": #TrustSourceRole & {_config: config}
			"\(config.metadata.name)-rb-trust": #TrustSourceRoleBinding & {_config: config}
			"\(config.metadata.name)-role-leader": #LeaderElectionRole & {_config: config}
			"\(config.metadata.name)-rb-leader": #LeaderElectionRoleBinding & {_config: config}

			if config.rbac.aggregateClusterRoles {
				"\(config.metadata.name)-cr-aggregated": #AggregatedClusterRole & {_config: config}
			}

			// With a restricted write scope the ConfigMap, Secret and
			// Event grants become per-namespace Roles.
			if config.targetNamespaces != _|_ {
				for ns, _ in config._rbacNamespaces {
					"\(config.metadata.name)-role-target-\(ns)": #TargetRole & {_config: config, _namespace: ns}
					"\(config.metadata.name)-rb-target-\(ns)": #TargetRoleBinding & {_config: config, _namespace: ns}
				}
			}
		}

		"\(config.metadata.name)-svc": #WebhookService & {_config: config}
		"\(config.metadata.name)-webhook": #ValidatingWebhookConfiguration & {_config: config}
		"\(config.metadata.name)-issuer": #Issuer & {_config: config}
		"\(config.metadata.name)-cert": #Certificate & {_config: config}
		"\(config.metadata.name)-deploy": #Deployment & {_config: config}

		// The policy and its use-grant are all-or-nothing: without the
		// RBAC the webhook certificate requests would stay unapproved.
		if config.webhook.tls.approverPolicy.enabled {
			"\(config.metadata.name)-policy": #CertificateRequestPolicy & {_config: config}
			"\(config.metadata.name)-policy-cr": #PolicyClusterRole & {_config: config}
			"\(config.metadata.name)-policy-crb": #PolicyClusterRoleBinding & {_config: config}
		}

		if config.metrics.service.enabled {
			"\(config.metadata.name)-svc-metrics": #MetricsService & {_config: config}
		}

		if config.serviceMonitor.enabled {
			"\(config.metadata.name)-monitor": #ServiceMonitor & {_config: config}
		}

		if config.podDisruptionBudget.enabled {
			"\(config.metadata.name)-pdb": #PodDisruptionBudget & {_config: config}
		}
	}
}
