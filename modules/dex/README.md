# dex

A [Timoni](https://timoni.sh) module for deploying [Dex](https://github.com/dexidp/dex), a federated OpenID Connect identity provider.

## Version

<!-- versions:start -->
Latest module version is `2.45.1-0`, packaging the upstream release
[v2.45.1](https://github.com/dexidp/dex/releases/tag/v2.45.1)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `ghcr.io/dexidp/dex` | v2.45.1 | `sha256:8499afd690c437f52301efd2b05b2455da5bd2dfc20332cd697dc9937f808462` |
<!-- versions:end -->

To list all available versions and their digests:

```shell
timoni mod list oci://ghcr.io/timonish/modules/dex
```

## Prerequisites

- Kubernetes 1.25+
- [Timoni](https://timoni.sh/install/) 0.31+

## Install

The Dex configuration is part of the instance values: the module
renders it into an immutable Secret whose hash-suffixed name rolls the
pods on every configuration change. By default the Dex state (signing
keys, sessions, tokens) is stored in `dex.coreos.com` custom resources
in the instance namespace, so an instance is functional without any
external database.

Place the configuration in a `values.cue` file, for example a local
password database with a statically registered OAuth2 client:

```cue
values: {
	config: {
		issuer: "https://dex.example.com"
		staticClients: [{
			id:        "example-app"
			name:      "Example App"
			secretEnv: "EXAMPLE_APP_SECRET"
			redirectURIs: ["https://app.example.com/callback"]
		}]
		enablePasswordDB: true
		staticPasswords: [{
			email:       "admin@example.com"
			hashFromEnv: "ADMIN_PASSWORD_HASH"
			username:    "admin"
			userID:      "08a8684b-db88-4b73-90a9-3cd1661f5466"
		}]
	}
	envFrom: [{
		secretRef: name: "dex-credentials"
	}]
}
```

And apply it with:

```shell
timoni -n dex apply dex \
  oci://ghcr.io/timonish/modules/dex \
  --values values.cue
```

Keep client secrets, bcrypt hashes and connector credentials out of
the instance values: reference an existing Secret with `env` or
`envFrom` and let Dex read them through `secretEnv`, `hashFromEnv` and
`$VAR` expansion in the storage, connector and signer settings.

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n dex delete dex
```

With the `kubernetes` storage backend, the `dex.coreos.com` custom
resource definitions created by Dex at runtime are not managed by the
instance and survive its deletion; remove them with
`kubectl delete crd` to discard the stored state.

## Bundle

For production deployments it is recommended to use a Timoni
[bundle](https://timoni.sh/bundle/) that offers a declarative way of
managing the lifecycle of applications and their infra dependencies.

The following bundle deploys a highly-available Dex that federates to
GitHub and serves an OAuth2 client, with the credentials expanded from
an existing `dex-credentials` Secret and the issuer exposed through a
Gateway API HTTPRoute:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "dex"
	instances: {
		"dex": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/dex"
				version: "latest"
			}
			namespace: "dex"
			values: {
				config: {
					issuer: "https://dex.example.com"
					connectors: [{
						type: "github"
						id:   "github"
						name: "GitHub"
						config: {
							clientID:     "$GITHUB_CLIENT_ID"
							clientSecret: "$GITHUB_CLIENT_SECRET"
							redirectURI:  "https://dex.example.com/callback"
						}
					}]
					staticClients: [{
						id:        "oauth2-proxy"
						name:      "OAuth2 Proxy"
						secretEnv: "OAUTH2_PROXY_CLIENT_SECRET"
						redirectURIs: ["https://apps.example.com/oauth2/callback"]
					}]
				}
				envFrom: [{
					secretRef: name: "dex-credentials"
				}]
				replicas: 2
				podDisruptionBudget: enabled: true
				httpRoute: {
					enabled: true
					parentRefs: [{
						name:      "gateway"
						namespace: "gateway-system"
					}]
					hostnames: ["dex.example.com"]
				}
			}
		}
	}
}
```

The `$VAR` references in the connector settings and the `secretEnv`
client secret are expanded by Dex from the environment sourced out of
the `dex-credentials` Secret, keeping the credentials out of the
bundle.

Save the bundle as `dex.cue` and apply the stack with:

```shell
timoni bundle apply -f dex.cue
```

## Configuration

All values are optional.

### Dex configuration values

The `config` values are rendered as-is into the Dex
[configuration file](https://dexidp.io/docs/configuration/); the listen
addresses are managed by the module and map to the fixed container
ports 5556 (http), 5554 (https), 5557 (grpc) and 5558 (telemetry).

| Key | Type | Default | Description |
|---|---|---|---|
| `config.issuer` | `string` | in-cluster Service URL | Base path of Dex and the external name of the OpenID Connect service, used as the `iss` claim of the issued ID tokens |
| `config.storage.type` | `string` | `kubernetes` | State backend: `kubernetes`, `memory`, `sqlite3`, `postgres`, `mysql` or `etcd` |
| `config.storage.config` | | `inCluster: true` | Backend settings; for `kubernetes`: `inCluster`, `kubeConfigFile` and `crdHandling` (`ensure` creates the missing CRDs on startup, `check` requires them pre-installed), for the other types the backend connection settings |
| `config.web.tlsCert` / `tlsKey` | `string` | unset | Certificate and key file paths (mounted with `extraVolumes`); setting them enables the HTTPS listener and its ports |
| `config.web.tlsMinVersion` / `tlsMaxVersion` | `string` | unset | TLS version bounds, `1.2` or `1.3` |
| `config.web.headers` | | unset | Security headers added to the HTTP responses |
| `config.web.allowedOrigins` / `allowedHeaders` | `[...string]` | unset | CORS settings for the discovery, token and keys endpoints |
| `config.web.clientRemoteIP` | | unset | Derive the client IP from a forwarding header set by trusted proxies |
| `config.telemetry.enableProfiling` | `bool` | unset | Serve pprof profiles on the telemetry port |
| `config.grpc` | | unset | Setting the struct enables the gRPC API and its ports; fields: `tlsCert`, `tlsKey`, `tlsClientCA`, `tlsMinVersion`, `tlsMaxVersion`, `reflection` |
| `config.oauth2` | | unset | OAuth2 flow customization: `grantTypes`, `responseTypes`, `skipApprovalScreen`, `alwaysShowLoginScreen`, `passwordConnector` |
| `config.expiry` | | unset | Lifetime of `signingKeys`, `idTokens`, `authRequests`, `deviceRequests` and the `refreshTokens` rotation policy |
| `config.logger.level` | `string` | unset (`info`) | One of `debug`, `info`, `warn`, `error` |
| `config.logger.format` | `string` | unset (`text`) | `text` or `json` |
| `config.frontend` | | unset | Web UI customization: `dir`, `logoURL`, `issuer`, `theme`, `extra` |
| `config.signer` | | unset | Token signer: `local` (storage-managed keys) or `vault` with its settings |
| `config.connectors` | `[...#DexConnector]` | unset | Federated [identity providers](https://dexidp.io/docs/connectors/); each takes `type`, `id`, `name` and the connector-specific `config` |
| `config.staticClients` | `[...#DexStaticClient]` | unset | Statically registered OAuth2 clients; each takes `name`, `id` or `idEnv`, `secret` or `secretEnv` (required unless `public: true`), `redirectURIs`, `trustedPeers` and `logoURL` |
| `config.enablePasswordDB` | `bool` | unset | Maintain a local email/password identity database; forced on by `staticPasswords` |
| `config.staticPasswords` | `[...#DexStaticPassword]` | unset | Local identities; each takes `email`, a bcrypt `hash` or `hashFromEnv`, `username`, `userID`, `name`, `preferredUsername`, `emailVerified` and `groups` |
| `configSecretName` | `string` | unset | Mount an existing Secret carrying the configuration under the `config.yaml` key instead of rendering one; configuration changes then no longer roll the pods |

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image` | `timoniv1.#Image` | upstream release | Container image repository, tag, digest and pull policy |
| `replicas` | `int` | `1` | Number of pod replicas; ignored when `hpa` is enabled |
| `revisionHistoryLimit` | `int` | unset | Number of old ReplicaSets to retain |
| `strategy` | `appsv1.#DeploymentStrategy` | `RollingUpdate` | Rollout strategy |
| `extraArgs` | `[...string]` | `[]` | Extra command line arguments appended to `dex serve` |
| `env` | `[...corev1.#EnvVar]` | unset | Environment variables: feature flags (e.g. `DEX_EXPAND_ENV`) and the variables expanded in the configuration |
| `envFrom` | `[...corev1.#EnvFromSource]` | unset | Environment variables sourced from ConfigMaps or Secrets |
| `resources` | `timoniv1.#ResourceRequirements` | unset | Container resource requirements |
| `securityContext` | `corev1.#SecurityContext` | hardened | Container security context; defaults: no privilege escalation, read-only rootfs, all capabilities dropped (the pod identity comes from `podSecurityContext`) |
| `livenessProbe` / `readinessProbe` | `corev1.#Probe` | `/healthz/live`, `/healthz/ready` | Container probes on the telemetry port; readiness covers the storage backend health |
| `startupProbe` | `corev1.#Probe` | unset | Startup probe |
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |
| `rbac.create` | `bool` | `true` | Create the Role over the `dex.coreos.com` custom resources; rendered only with the `kubernetes` storage backend |
| `rbac.createClusterScoped` | `bool` | `true` | Create the ClusterRole allowing Dex to create the custom resource definitions on startup; disable when they are pre-installed and `crdHandling: check` is set |
| `rbac.extraRules` | `[...rbacv1.#PolicyRule]` | unset | Extra rules appended to the Role |
| `serviceAccount.create` | `bool` | `true` | Create the service account; set to `false` to use an existing one |
| `serviceAccount.name` | `string` | instance name, or `default` when `create: false` | Service account name |
| `serviceAccount.labels` / `annotations` | `{[string]: string}` | unset | Extra service account metadata (e.g. IRSA role annotations) |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount the token through the service account (the pod setting mounts it instead) |

### Pod scheduling values

| Key | Type | Default | Description |
|---|---|---|---|
| `podLabels` / `podAnnotations` | `{[string]: string}` | unset | Extra pod metadata |
| `securityContextPreset` | `hardened` or `platform` | `hardened` | Pod identity defaults: `hardened` pins the image's non-root UID/GID `1001`, `platform` leaves the identity to the cluster (e.g. OpenShift SCCs) |
| `podSecurityContext` | `corev1.#PodSecurityContext` | per `securityContextPreset` | Pod security context |
| `imagePullSecrets` | `[...]` | unset | Secrets for pulling from private registries |
| `priorityClassName` | `string` | unset | Pod priority class |
| `affinity.podAntiAffinity` | `soft`, `hard`, `none` or raw rules | `soft` | Spread the replicas across nodes; raw rules replace the preset and need explicit label selectors |
| `affinity.nodeAffinity` / `affinity.podAffinity` | raw rules | unset | Node and pod affinity rules |
| `nodeSelector` | `{[string]: string}` | Linux nodes | Node selection; a supplied value replaces the default |
| `tolerations` / `topologySpreadConstraints` | | unset | Standard scheduling controls; spread constraints without a label selector match the instance pods |
| `hostAliases` | `[...corev1.#HostAlias]` | unset | Extra entries for the pod /etc/hosts |
| `schedulerName` | `string` | unset | Alternate scheduler |
| `dnsPolicy` / `dnsConfig` | | unset | Pod DNS settings |
| `terminationGracePeriodSeconds` | `int` | unset | Pod termination grace period |
| `automountServiceAccountToken` | `bool` | `true` with `kubernetes` storage, else `false` | Automount the API credentials in the pod |
| `initContainers` / `extraContainers` | `[...corev1.#Container]` | unset | Additional containers |
| `tmpVolume` | `corev1.#VolumeSource` | `emptyDir` | Volume backing /tmp, where the image entrypoint preprocesses the configuration (the root filesystem is read-only) |
| `extraVolumes` / `extraVolumeMounts` | `[...]` | unset | Additional volumes, e.g. the TLS certificates referenced in the configuration |
| `deploymentLabels` / `deploymentAnnotations` | `{[string]: string}` | unset | Extra Deployment metadata |

### Service values

The https and grpc ports follow the listeners enabled in the Dex
configuration; the telemetry port (5558) is always exposed for
scraping.

| Key | Type | Default | Description |
|---|---|---|---|
| `service.port` | `int` | `5556` | Service http port, the backend of `ingress` and `httpRoute` |
| `service.httpsPort` | `int` | `5554` | Service https port, exposed when the HTTPS listener is enabled |
| `service.grpcPort` | `int` | `5557` | Service grpc port, exposed when the gRPC API is enabled |
| `service.type` | `string` | `ClusterIP` | Service type |
| `service.annotations` / `labels` | `{[string]: string}` | unset | Extra Service metadata |
| `service.clusterIP` / `externalIPs` / `loadBalancerIP` / `loadBalancerClass` / `loadBalancerSourceRanges` / `externalTrafficPolicy` | | unset | Service networking settings per type |
| `service.nodePort` / `httpsNodePort` / `grpcNodePort` | `int` | `0` (auto) | Node ports with the `NodePort` and `LoadBalancer` service types |
| `service.ipFamilies` / `ipFamilyPolicy` | | unset | Service IP family settings |

### Routing values

| Key | Type | Default | Description |
|---|---|---|---|
| `ingress.enabled` | `bool` | `false` | Create an Ingress for the http Service port |
| `ingress.className` | `string` | unset | IngressClass name |
| `ingress.hosts` | `[...#IngressHost]` | required when enabled | Ingress rules: each host takes `paths` with `path` and `pathType` (default `/` `Prefix`) |
| `ingress.tls` | `[...networkingv1.#IngressTLS]` | unset | TLS termination settings |
| `ingress.annotations` / `labels` | `{[string]: string}` | unset | Extra Ingress metadata |
| `httpRoute.enabled` | `bool` | `false` | Create a Gateway API HTTPRoute for the http Service port |
| `httpRoute.parentRefs` | `[...]` | required when enabled | Gateways the route attaches to |
| `httpRoute.hostnames` | `[...string]` | unset | Hostnames the route matches |
| `httpRoute.rules` | `[...]` | match all | Route rules with `matches` and `filters`; the backend reference is generated by the module |
| `httpRoute.annotations` / `labels` | `{[string]: string}` | unset | Extra HTTPRoute metadata |
| `networkPolicy.enabled` | `bool` | `false` | Create a NetworkPolicy allowing ingress to the exposed ports from any peer |
| `networkPolicy.egress` | `[...networkingv1.#NetworkPolicyEgressRule]` | unset | Restrict egress to the given rules, e.g. the upstream identity providers and DNS |

### Autoscaling and disruption values

| Key | Type | Default | Description |
|---|---|---|---|
| `hpa.enabled` | `bool` | `false` | Create a HorizontalPodAutoscaler owning the replica count |
| `hpa.minReplicas` / `maxReplicas` | `int` | `1` / `minReplicas` | Autoscaling bounds |
| `hpa.metrics` | `[...]` | `[]` | Scaling metrics, e.g. CPU utilization targets |
| `hpa.behavior` | | unset | Scaling behavior tuning |
| `podDisruptionBudget.enabled` | `bool` | `false` | Create a PodDisruptionBudget |
| `podDisruptionBudget.minAvailable` | `int` or percent | `1` | Minimum available pods; mutually exclusive with `maxUnavailable` |
| `podDisruptionBudget.maxUnavailable` | `int` or percent | unset | Maximum unavailable pods |
| `podDisruptionBudget.unhealthyPodEvictionPolicy` | `string` | unset | `IfHealthyBudget` or `AlwaysAllow`; requires Kubernetes 1.27+ |

### Monitoring values

| Key | Type | Default | Description |
|---|---|---|---|
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor for the telemetry Service port, in the instance namespace |
| `serviceMonitor.additionalLabels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata, e.g. labels for Prometheus discovery |
| `serviceMonitor.jobLabel` | `string` | `app.kubernetes.io/name` | Service label used as the Prometheus job name |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | unset | Scrape cadence; defaults to the Prometheus settings |
| `serviceMonitor.honorLabels` | `bool` | `false` | Keep scraped label values on collision |
| `serviceMonitor.enableHttp2` | `bool` | unset | Enable HTTP2 for scraping |
| `serviceMonitor.scheme` / `tlsConfig` / `bearerTokenFile` / `bearerTokenSecret` / `proxyUrl` | | unset | Scrape scheme, TLS, authentication and proxy settings |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules for the samples and the targets |
| `serviceMonitor.sampleLimit` / `targetLimit` / `labelLimit` / `labelNameLengthLimit` / `labelValueLengthLimit` | `int` | unset | Scrape limits |
| `serviceMonitor.targetLabels` / `podTargetLabels` | `[...string]` | unset | Service/pod labels copied onto the metrics |
