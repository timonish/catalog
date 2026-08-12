package templates

import (
	"list"

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

	// ExternalDNS requires Kubernetes 1.25 or newer.
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

	// The number of pod replicas. ExternalDNS does not support leader
	// election, so at most one replica may run; scaling to zero
	// suspends DNS synchronization.
	replicas: *1 | int & >=0 & <=1

	// The number of old ReplicaSets to retain.
	revisionHistoryLimit?: int & >=0

	// The strategy to replace old pods with new ones. The Recreate
	// default prevents the old and new pod from updating DNS records
	// concurrently during a rollout.
	strategy: appsv1.#DeploymentStrategy & {
		type: *"Recreate" | "RollingUpdate"
	}

	// The container image repository, tag, digest and pull policy.
	// The default repository and tag track the upstream release
	// and are set in `versions.cue` by upengine.
	image: timoniv1.#Image & {
		repository: *#defaultImages."external-dns".repository | string
		tag:        *#defaultImages."external-dns".tag | string
		digest:     *#defaultImages."external-dns".digest | string
	}

	// References to secrets used for pulling images from private registries.
	imagePullSecrets?: [...timoniv1.#ObjectReference]

	// The DNS provider. For the available providers and how to configure
	// them see https://kubernetes-sigs.github.io/external-dns/.
	// Setting the name to `webhook` runs the provider webhook sidecar,
	// which then requires `provider.webhook.image`.
	provider: {
		name: *"aws" | string & =~".+"

		// The provider webhook sidecar container settings, used only
		// when `provider.name` is `webhook`. The image can be pinned by
		// digest like every other container image.
		webhook: {
			image: timoniv1.#Image & {
				repository: *"" | string
				tag:        *"" | string
				digest:     *"" | string
			}
			env?: [...corev1.#EnvVar]
			args: *[] | [...string]
			extraVolumeMounts?: [...corev1.#VolumeMount]
			resources?: timoniv1.#ResourceRequirements
			// The sidecar security context, hardened by default like the
			// main container.
			securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext

			// The liveness probe of the webhook container.
			livenessProbe: corev1.#Probe & {
				httpGet: {
					path: *"/healthz" | string
					port: *"http-webhook" | string | int
				}
				initialDelaySeconds: *10 | int
				periodSeconds:       *10 | int
				timeoutSeconds:      *5 | int
				failureThreshold:    *2 | int
				successThreshold:    *1 | int
			}

			// The readiness probe of the webhook container.
			readinessProbe: corev1.#Probe & {
				httpGet: {
					path: *"/healthz" | string
					port: *"http-webhook" | string | int
				}
				initialDelaySeconds: *5 | int
				periodSeconds:       *10 | int
				timeoutSeconds:      *5 | int
				failureThreshold:    *6 | int
				successThreshold:    *1 | int
			}

			// The Service port exposing the webhook.
			service: port: *8080 | int & >0 & <=65535

			// ServiceMonitor scrape settings of the webhook metrics
			// endpoint, added when `serviceMonitor` is enabled.
			serviceMonitor: timoniv1.#MonitorEndpoint
		}
		if name == "webhook" {
			webhook: image: {
				repository: string & =~".+"
				tag:        string & =~".+"
			}
		}
	}

	// The log verbosity and format.
	logLevel:  *"info" | "panic" | "debug" | "warning" | "error" | "fatal"
	logFormat: *"text" | "json"

	// The interval between DNS reconciliations.
	interval: *"1m" | string & =~".+"

	// Trigger a reconciliation on source create/update/delete events in
	// addition to the regular interval.
	triggerLoopOnEvent: *false | bool

	// The Kubernetes resources monitored for DNS entries. The RBAC rules
	// are derived from this list, granting access only to the resources
	// the enabled sources need.
	sources: *["service", "ingress"] | [...string & =~".+"]

	// How DNS records are synchronized between sources and providers:
	// `upsert-only` never deletes records, `sync` propagates deletions,
	// `create-only` never updates or deletes existing records.
	policy: *"upsert-only" | "sync" | "create-only"

	// The registry storing DNS record ownership and labels.
	registry: *"txt" | "aws-sd" | "dynamodb" | "noop"

	// The identifier of this ExternalDNS instance, recorded in the
	// registry to guard the records it owns.
	txtOwnerId?: string & =~".+"

	// A prefix or suffix (mutually exclusive) for the domain names of
	// the TXT records created by the `txt` registry.
	txtPrefix?: string & =~".+"
	txtSuffix?: string & =~".+"
	_txtGuard:  "valid"
	_txtGuard: [
		if txtPrefix != _|_ && txtSuffix != _|_ {"txtPrefix and txtSuffix are mutually exclusive"},
		"valid",
	][0]

	// Run ExternalDNS in a namespaced scope: sources are watched in a
	// single namespace and the RBAC objects become Role/RoleBinding.
	namespaced: *false | bool

	// The namespace watched for sources when `namespaced` is enabled;
	// defaults to the instance namespace.
	sourceNamespace?: string & =~".+"

	// The namespace watched for Gateway API gateways. With `namespaced`
	// enabled, setting it avoids creating any cluster-scoped RBAC.
	gatewayNamespace?: string & =~".+"

	// Enable the Gateway API ListenerSet support.
	enableGatewayListenerSets: *false | bool

	// Limit the managed zones by domain suffixes, or exclude domains
	// from being managed.
	domainFilters: *[] | [...string]
	excludeDomains: *[] | [...string]

	// Filter the resources queried for endpoints by label, annotation
	// or annotation prefix (useful for split-horizon DNS setups running
	// multiple instances).
	labelFilter?:      string & =~".+"
	annotationFilter?: string & =~".+"
	annotationPrefix?: string & =~".+"

	// The DNS record types to manage; upstream defaults to A, AAAA and CNAME.
	managedRecordTypes: *[] | [...string]

	// Extra command line arguments appended after the generated ones.
	extraArgs: *[] | [...string]

	// Environment variables for the external-dns container, e.g.
	// provider credentials referenced from an existing Secret.
	env?: [...corev1.#EnvVar]

	// The container security context, hardened by default. The pod
	// identity (UID/GID) is a pod-level concern, see podSecurityContext.
	securityContext: corev1.#SecurityContext & timoniv1.#ContainerSecurityContext & {
		privileged: *false | bool
	}

	// The liveness probe of the external-dns container.
	livenessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *"http" | string | int
		}
		initialDelaySeconds: *10 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *2 | int
		successThreshold:    *1 | int
	}

	// The readiness probe of the external-dns container.
	readinessProbe: corev1.#Probe & {
		httpGet: {
			path: *"/healthz" | string
			port: *"http" | string | int
		}
		initialDelaySeconds: *5 | int
		periodSeconds:       *10 | int
		timeoutSeconds:      *5 | int
		failureThreshold:    *6 | int
		successThreshold:    *1 | int
	}

	// The container resource requirements.
	resources?: timoniv1.#ResourceRequirements

	// Extra volumes and volume mounts, e.g. for provider credential
	// files projected from an existing Secret.
	extraVolumes?: [...corev1.#Volume]
	extraVolumeMounts?: [...corev1.#VolumeMount]

	// Init containers and extra containers added to the pod.
	initContainers?: [...corev1.#Container]
	extraContainers?: [...corev1.#Container]

	// Pod optional settings.
	podLabels?:      timoniv1.#Labels
	podAnnotations?: timoniv1.#Annotations
	// Pods are scheduled on Linux nodes by default.
	nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
	tolerations?: [...corev1.#Toleration]
	// The affinity rules; Linux placement comes from the nodeSelector
	// default. `podAntiAffinity` accepts the `soft` (default), `hard`
	// and `none` presets for spreading the replicas across nodes, or
	// raw pod anti-affinity rules with explicit label selectors.
	affinity: timoniv1.#AffinityValues & {
		podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
		nodeAffinity?:   corev1.#NodeAffinity
		podAffinity?:    corev1.#PodAffinity
	}
	topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
	dnsConfig?:                     corev1.#PodDNSConfig
	dnsPolicy?:                     "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
	priorityClassName?:             string & =~".+"
	schedulerName?:                 string & =~".+"
	terminationGracePeriodSeconds?: int & >=0

	// Mount the service account token into the pod.
	automountServiceAccountToken: *true | bool

	// Share a single process namespace between all of the pod containers.
	shareProcessNamespace: *false | bool

	// The security preset applied to the pod identity defaults: the
	// default "hardened" preset pins the image's non-root UID, while
	// "platform" leaves the identity to an admission controller
	// (e.g. an OpenShift SecurityContextConstraint).
	securityContextPreset: timoniv1.#SecurityContextPreset

	// The pod security context generated for the security preset.
	podSecurityContext: corev1.#PodSecurityContext & timoniv1.#PodSecurityContext & {
		#Preset:  securityContextPreset
		#User:    65532
		#FSGroup: 65534
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
			name: *"default" | string
		}
		labels?:      timoniv1.#Labels
		annotations?: timoniv1.#Annotations
		// The token is mounted through the pod setting instead.
		automountServiceAccountToken: *false | bool
	}

	// Set `rbac.create: false` when the roles and bindings are managed
	// outside of this module. `extraRules` extends the source-derived
	// rules.
	rbac: {
		create: *true | bool
		extraRules?: [...rbacv1.#PolicyRule]
	}

	// Service settings for the metrics and webhook endpoints.
	service: {
		enabled:    *true | bool
		type:       *"ClusterIP" | "NodePort" | "LoadBalancer"
		port:       *7979 | int & >0 & <=65535
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

	// Prometheus Operator ServiceMonitor (optional), created in the
	// instance namespace. When the provider webhook sidecar runs, its
	// metrics endpoint is scraped too through
	// `provider.webhook.serviceMonitor`.
	serviceMonitor: timoniv1.#MonitorValues

	// The DNSEndpoint CRD lifecycle. Disable `install` on secondary
	// instances (e.g. split-horizon DNS) so a single instance owns the
	// CRD; `keep: true` preserves the CRD (and all DNSEndpoints) when
	// the instance is deleted.
	crds: {
		install: *true | bool
		keep:    *false | bool
	}

	// Whether any Gateway API route source is enabled.
	_hasGatewaySources: list.Contains(sources, "gateway-httproute") ||
		list.Contains(sources, "gateway-grpcroute") ||
		list.Contains(sources, "gateway-tlsroute") ||
		list.Contains(sources, "gateway-tcproute") ||
		list.Contains(sources, "gateway-udproute")
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

				// Keep the CRD (and thus all DNSEndpoints) around when
				// the instance is deleted.
				if config.crds.keep {
					"crd-\(name)": metadata: annotations: "timoni.sh/prune": "disabled"
				}
			}
		}

		if config.serviceAccount.create {
			"\(config.metadata.name)-sa": #ServiceAccount & {_config: config}
		}

		if config.rbac.create {
			if !config.namespaced {
				"\(config.metadata.name)-cr": #SourcesClusterRole & {_config: config}
				"\(config.metadata.name)-crb": #SourcesClusterRoleBinding & {_config: config}
			}
			if config.namespaced {
				"\(config.metadata.name)-role": #SourcesRole & {_config: config}
				"\(config.metadata.name)-rb": #SourcesRoleBinding & {_config: config}

				// Watching Gateway API sources across the cluster needs
				// namespace discovery; when the gateway namespace is
				// pinned, no cluster-scoped RBAC is created at all.
				if config._hasGatewaySources && config.gatewayNamespace == _|_ {
					"\(config.metadata.name)-ns-cr": #NamespacesClusterRole & {_config: config}
					"\(config.metadata.name)-ns-crb": #NamespacesClusterRoleBinding & {_config: config}
				}
				if config._hasGatewaySources && config.gatewayNamespace != _|_ {
					"\(config.metadata.name)-gw-role": #GatewayRole & {_config: config}
					"\(config.metadata.name)-gw-rb": #GatewayRoleBinding & {_config: config}
				}
			}
		}

		if config.service.enabled {
			"\(config.metadata.name)-svc": #Service & {_config: config}
		}

		"\(config.metadata.name)-deploy": #Deployment & {_config: config}

		if config.serviceMonitor.enabled {
			"\(config.metadata.name)-monitor": #ServiceMonitor & {_config: config}
		}
	}
}
