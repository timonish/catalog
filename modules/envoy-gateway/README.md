# envoy-gateway

A [Timoni](https://timoni.sh) module for deploying [Envoy Gateway](https://github.com/envoyproxy/gateway), an implementation of the Kubernetes Gateway API based on the Envoy proxy.

## Version

<!-- versions:start -->
Latest module version is `1.9.0-1`, packaging the upstream release
[v1.9.0](https://github.com/envoyproxy/gateway/releases/tag/v1.9.0)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `docker.io/envoyproxy/gateway` | v1.9.0 | `sha256:6f40c7b218b4ff1c4cb481923ed2c9a7634580365913434dd5dda9e954c0114b` |
<!-- versions:end -->

The Envoy proxy and ratelimit data plane images are managed by the
Envoy Gateway controller itself and track its compiled-in defaults;
they can be overridden through the
[EnvoyProxy](https://gateway.envoyproxy.io/docs/api/extension_types/#envoyproxy)
custom resource and `config.provider.kubernetes` respectively.

## Prerequisites

- Kubernetes 1.29+
- [Timoni](https://timoni.sh/install/) 0.31+
- The [Gateway API](https://gateway-api.sigs.k8s.io) CRDs, e.g. from
  the [gateway-api module](https://github.com/timonish/catalog/tree/main/modules/gateway-api)

## Install

The module deploys the Envoy Gateway controller, an implementation of
the Kubernetes Gateway API: it watches GatewayClasses, Gateways and
routes, and runs a fleet of Envoy proxies serving the configured
traffic.

The Gateway API CRDs are a hard dependency and are not part of this
module. Install them first:

```shell
timoni -n gateway-system apply gateway-api \
  oci://ghcr.io/timonish/modules/gateway-api
```

Then create an envoy-gateway instance using the default values:

```shell
timoni -n envoy-gateway apply envoy-gateway \
  oci://ghcr.io/timonish/modules/envoy-gateway
```

Note that the module installs the controller together with its
`gateway.envoyproxy.io` CRDs, the control plane certificate generator
Job and the topology injector webhook. The controller Service is named
`envoy-gateway` regardless of the instance name, as the managed Envoy
fleet dials the xDS server at that fixed DNS name.

To verify the installation, create a GatewayClass referencing the
controller and a Gateway for it, e.g. with the upstream quickstart:

```shell
kubectl apply -f https://github.com/envoyproxy/gateway/releases/latest/download/quickstart.yaml -n default
```

To change the [configuration](#configuration), create a `values.cue`
file:

```cue
values: {
	config: {
		logging: level: default: "debug"
		provider: kubernetes: envoyDeployment: replicas: 2
	}
}
```

And apply the values with:

```shell
timoni -n envoy-gateway apply envoy-gateway \
  oci://ghcr.io/timonish/modules/envoy-gateway \
  --values ./values.cue
```

## Envoy Gateway configuration

The `config` value is rendered into the
[EnvoyGateway](https://gateway.envoyproxy.io/docs/api/extension_types/#envoygateway)
configuration file and mounted into the controller through an
immutable ConfigMap whose name carries the configuration hash, so
configuration changes roll the controller pods automatically.

The common fields are typed and validated at build time; every other
EnvoyGateway API field (`telemetry`, `rateLimit`, `extensionManager`,
`extensionApis`, the `provider.kubernetes` deployment overrides,
etc.) passes through as-is and is validated by the controller at
startup. For example, to enable the global rate limit backed by an
existing Redis:

```cue
values: {
	config: rateLimit: backend: {
		type: "Redis"
		redis: url: "redis.redis-system.svc:6379"
	}
}
```

The controller then deploys the ratelimit service automatically, with
its image tracking the compiled-in default.

The watched namespaces are configured through
`config.provider.kubernetes.watch`; when namespaces are enumerated
by name, the module scopes the controller RBAC to those namespaces
with per-namespace roles. The `GatewayNamespace` deploy mode
(`config.provider.kubernetes.deploy.type`) grants the
infrastructure manager access in the watched namespaces and enables
TokenReview-based authentication for the Envoy fleet.

## Control plane TLS

The Envoy Gateway control plane uses mutual TLS between the xDS
server, the Envoy fleet and the ratelimit service. By default the
module runs the upstream certificate generator Job on every apply; the
Job bootstraps the `envoy-gateway`, `envoy`, `envoy-rate-limit` and
`envoy-oidc-hmac` secrets with a self-signed CA and never overwrites
existing secrets.

With [cert-manager](https://cert-manager.io) installed on the cluster,
the module can instead delegate the certificates to cert-manager,
which also rotates them ahead of expiry:

```cue
values: {
	tls: mode: "cert-manager"
}
```

In this mode the module manages a self-signed CA (overridable with
`tls.certManager.existingIssuer`) and issues the control plane
certificates from it, the webhook CA bundle is injected by
cert-manager, and the certificate generator Job only maintains the
`envoy-oidc-hmac` secret used for OIDC token encryption.

Note that when switching an existing instance from `certgen` to
`cert-manager`, the previously generated `envoy`, `envoy-gateway` and
`envoy-rate-limit` secrets must be deleted first: cert-manager only
injects the webhook CA bundle from secrets it created itself, and
deleting the secrets triggers an immediate re-issuance.

The generated secrets are not owned by the module: like upstream, they
survive uninstalling the instance and must be deleted manually for a
complete cleanup (in cert-manager mode this applies to the
`envoy-oidc-hmac` secret only).

## Topology-aware routing

The module installs a mutating admission webhook that labels the Envoy
fleet pods with their node's topology zone at binding time. Combined
with `service: trafficDistribution: "PreferClose"` on the xDS Service,
the Envoy fleet prefers connecting to topologically closer controller
pods. The webhook is fail-open and can be removed with
`topologyInjector: enabled: false`.

## Monitoring

The controller exposes Prometheus metrics on the `metrics` port,
annotated for Prometheus annotation-based discovery. With a Prometheus
Operator running in the cluster, set `serviceMonitor: enabled: true`
to scrape the instance through a ServiceMonitor instead.

## Bundle

An example [bundle](https://timoni.sh/bundle/) for deploying the
Gateway API CRDs and Envoy Gateway together:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "ingress"
	instances: {
		"gateway-api": {
			module: url: "oci://ghcr.io/timonish/modules/gateway-api"
			namespace: "gateway-system"
		}
		"envoy-gateway": {
			module: url: "oci://ghcr.io/timonish/modules/envoy-gateway"
			namespace: "envoy-gateway"
			values: {
				podDisruptionBudget: {
					enabled:      true
					minAvailable: 1
				}
			}
		}
	}
}
```

Apply the bundle with:

```shell
timoni bundle apply -f bundle.cue
```

## Configuration

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `crds.install` | `bool` | `true` | Install the `gateway.envoyproxy.io` CRDs; set to `false` when they are managed outside of this module |
| `crds.keep` | `bool` | `false` | Keep the CRDs (and thereby all Envoy Gateway custom resources) when the instance is deleted |
| `image.repository` | `string` | `docker.io/envoyproxy/gateway` | Container image repository |
| `image.tag` | `string` | `<version>` | Container image tag, tracking the upstream release |
| `image.digest` | `string` | `""` | Container image digest, takes precedence over `tag` when specified |
| `image.pullPolicy` | `string` | `IfNotPresent` | Kubernetes image pull policy |
| `imagePullSecrets` | `[...timoniv1.#ObjectReference]` | unset | References to secrets for pulling images from private registries |
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |
| `metadata.annotations` | `{[string]: string}` | unset | Annotations added to all resources |
| `config` | `object` | see [above](#envoy-gateway-configuration) | The EnvoyGateway configuration file contents |
| `config.gateway.controllerName` | `string` | `gateway.envoyproxy.io/gatewayclass-controller` | The controller name GatewayClasses reference |
| `config.logging.level.default` | `string` | `info` | Log verbosity (`debug`, `info`, `warn`, `error`), overridable per component |
| `tls.mode` | `string` | `certgen` | Control plane TLS bootstrap: `certgen` or `cert-manager` |
| `tls.certManager.existingIssuer` | `object` | `enabled: false` | Issue the CA from an existing `Issuer` or `ClusterIssuer` instead of the module's self-signed one |
| `tls.certManager.caDuration` | `string` | unset | Validity of the CA certificate |
| `tls.certManager.duration` | `string` | unset | Validity of the leaf certificates |
| `tls.certManager.renewBefore` | `string` | unset | Renewal window of the leaf certificates |
| `tls.certManager.annotations` | `{[string]: string}` | unset | Annotations added to the cert-manager objects |
| `tls.certManager.labels` | `{[string]: string}` | unset | Labels added to the cert-manager objects |
| `rbac.create` | `bool` | `true` | Create the cluster roles, roles and bindings |
| `serviceAccount.create` | `bool` | `true` | Create the controller and certgen service accounts; when `false`, both are expected to exist and `name` defaults to `default` |
| `serviceAccount.name` | `string` | instance name | The service account used by the controller pods |
| `serviceAccount.annotations` | `{[string]: string}` | unset | Annotations added to the service account |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount the token on the ServiceAccount itself; the pods that need API access mount it explicitly |
| `kubernetesClusterDomain` | `string` | `cluster.local` | The cluster domain used for the generated in-cluster addresses |

### Certificate generator values

| Key | Type | Default | Description |
|---|---|---|---|
| `certgen.args` | `[...string]` | `[]` | Extra arguments appended to the `certgen` command |
| `certgen.annotations` | `{[string]: string}` | unset | Annotations added to the Job |
| `certgen.podAnnotations` | `{[string]: string}` | unset | Annotations added to the Job pod |
| `certgen.podLabels` | `{[string]: string}` | unset | Labels added to the Job pod |
| `certgen.resources` | `timoniv1.#ResourceRequirements` | unset | The Job container resource requirements |
| `certgen.affinity` | `corev1.#Affinity` | unset | The Job pod affinity rules |
| `certgen.tolerations` | `[...corev1.#Toleration]` | unset | The Job pod tolerations |
| `certgen.nodeSelector` | `{[string]: string}` | `kubernetes.io/os: linux` | The Job pod node selector |
| `certgen.ttlSecondsAfterFinished` | `int` | `30` | Delete the completed Job after this many seconds |

### Workload values

| Key | Type | Default | Description |
|---|---|---|---|
| `replicas` | `int` | `1` | The number of controller pods; zero suspends the control plane, ignored when `hpa.enabled` |
| `dnsPolicy` / `dnsConfig` | | unset | Pod DNS settings |
| `schedulerName` | `string` | unset | Alternate scheduler |
| `hpa.enabled` | `bool` | `false` | Autoscale the controller with a HorizontalPodAutoscaler |
| `hpa.minReplicas` | `int` | `1` | The lower replica bound |
| `hpa.maxReplicas` | `int` | `1` | The upper replica bound |
| `hpa.metrics` | `[...]` | `[]` | The autoscaling metrics (`autoscaling/v2`) |
| `hpa.behavior` | `object` | unset | The autoscaling behavior |
| `resources` | `timoniv1.#ResourceRequirements` | `100m/256Mi` requests, `1024Mi` memory limit | The controller container resource requirements |
| `securityContext` | `corev1.#SecurityContext` | hardened | The controller container security context |
| `securityContextPreset` | `hardened` or `platform` | `hardened` | Pod identity defaults: `hardened` pins UID/GID `65532`, `platform` leaves the identity to the cluster (e.g. OpenShift SCCs) |
| `podSecurityContext` | `corev1.#PodSecurityContext` | per `securityContextPreset` | The controller pod security context |
| `startupProbe` | `corev1.#Probe` | `/healthz` on `8081` | The startup probe, with a generous failure threshold for cache priming |
| `livenessProbe` | `corev1.#Probe` | `/healthz` on `8081` | The liveness probe |
| `readinessProbe` | `corev1.#Probe` | `/readyz` on `8081` | The readiness probe |
| `wasmCacheVolume` | `corev1.#VolumeSource` | unset (an emptyDir) | The volume backing the Wasm module cache at `/var/lib/eg/wasm` |
| `env` | `[...corev1.#EnvVar]` | unset | Environment variables appended to the controller container |
| `extraVolumes` | `[...corev1.#Volume]` | unset | Volumes added to the controller pod |
| `extraVolumeMounts` | `[...corev1.#VolumeMount]` | unset | Volume mounts added to the controller container |
| `podAnnotations` | `{[string]: string}` | `prometheus.io/scrape` and `prometheus.io/port` | Annotations added to the pods |
| `podLabels` | `{[string]: string}` | unset | Labels added to the pods |
| `nodeSelector` | `{[string]: string}` | `kubernetes.io/os: linux` | The pod node selector |
| `tolerations` | `[...corev1.#Toleration]` | unset | The pod tolerations |
| `affinity.podAntiAffinity` | `soft`, `hard`, `none` or raw rules | `soft` | Spread the replicas across nodes; raw rules replace the preset |
| `affinity.nodeAffinity` / `affinity.podAffinity` | raw rules | unset | Node and pod affinity rules |
| `topologySpreadConstraints` | `[...corev1.#TopologySpreadConstraint]` | unset | The pod topology spread constraints |
| `priorityClassName` | `string` | unset | The priority class of the pods |
| `terminationGracePeriodSeconds` | `int` | `10` | Seconds the pods are given to shut down |
| `strategy` | `appsv1.#DeploymentStrategy` | unset | The strategy to replace old pods with new ones |
| `revisionHistoryLimit` | `int` | unset | The number of old ReplicaSets to retain |
| `deploymentAnnotations` | `{[string]: string}` | unset | Annotations added to the Deployment |
| `podDisruptionBudget.enabled` | `bool` | `false` | Create a PodDisruptionBudget for the controller pods |
| `podDisruptionBudget.minAvailable` | `int or %` | `1` | Number or percentage of pods that must remain available |
| `podDisruptionBudget.maxUnavailable` | `int \| string` | unset | Number or percentage of pods that can be unavailable |
| `podDisruptionBudget.unhealthyPodEvictionPolicy` | `string` | unset | `IfHealthyBudget` or `AlwaysAllow` |

### Service values

| Key | Type | Default | Description |
|---|---|---|---|
| `ports.grpc` | `int` | `18000` | The xDS gRPC port |
| `ports.ratelimit` | `int` | `18001` | The ratelimit discovery port |
| `ports.wasm` | `int` | `18002` | The Wasm HTTP server port |
| `ports.metrics` | `int` | `19001` | The Prometheus metrics port |
| `service.type` | `string` | `ClusterIP` | Kubernetes Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `service.annotations` / `labels` | `{[string]: string}` | unset | Extra Service metadata |
| `service.trafficDistribution` | `string` | unset | Prefer routing to topologically closer pods, e.g. `PreferClose` |
| `service.ipFamilies` | `[...string]` | unset | The Service IP families |
| `service.ipFamilyPolicy` | `string` | unset | The Service dual-stack policy |
| `service.loadBalancerIP` | `string` | unset | The load balancer IP (`LoadBalancer` type only) |
| `service.loadBalancerClass` | `string` | unset | The load balancer class (`LoadBalancer` type only) |
| `service.loadBalancerSourceRanges` / `externalIPs` / `externalTrafficPolicy` | | unset | Load balancer CIDR allowlist, external IPs and traffic policy |
| `topologyInjector.enabled` | `bool` | `true` | Install the topology injector webhook |
| `topologyInjector.annotations` | `{[string]: string}` | unset | Annotations added to the webhook configuration |

### Monitoring values

| Key | Type | Default | Description |
|---|---|---|---|
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor for the metrics endpoint, in the instance namespace |
| `serviceMonitor.additionalLabels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata, e.g. labels for Prometheus discovery |
| `serviceMonitor.jobLabel` | `string` | `app.kubernetes.io/name` | Service label used as the Prometheus job name |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | unset | Scrape cadence; defaults to the Prometheus settings |
| `serviceMonitor.honorLabels` | `bool` | `false` | Keep scraped label values on collision |
| `serviceMonitor.enableHttp2` | `bool` | unset | Enable HTTP2 for scraping |
| `serviceMonitor.scheme` / `tlsConfig` / `bearerTokenFile` / `bearerTokenSecret` / `proxyUrl` | | unset | Scrape scheme, TLS, authentication and proxy settings |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules for the samples and the targets |
| `serviceMonitor.sampleLimit` / `targetLimit` / `labelLimit` / `labelNameLengthLimit` / `labelValueLengthLimit` | `int` | unset | Scrape limits |
| `serviceMonitor.targetLabels` / `podTargetLabels` | `[...string]` | unset | Service/pod labels copied onto the metrics |
