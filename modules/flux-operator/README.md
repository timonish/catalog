# flux-operator

A [Timoni](https://timoni.sh) module for deploying the [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator), a Kubernetes operator that manages the lifecycle of the Flux CD distribution and serves the Flux Status web interface.

## Version

<!-- versions:start -->
Latest module version is `0.58.1-0`, packaging the upstream release
[v0.58.1](https://github.com/controlplaneio-fluxcd/flux-operator/releases/tag/v0.58.1)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `ghcr.io/controlplaneio-fluxcd/flux-operator` | v0.58.1 | `sha256:63d1eb008fc5a1a92fad331a23f1eb600e1158fd5d63a5e541f0ce266d2dbd5b` |
<!-- versions:end -->

To list all available versions and their digests:

```shell
timoni mod list oci://ghcr.io/timonish/modules/flux-operator
```

## Prerequisites

- Kubernetes 1.25+
- [Timoni](https://timoni.sh/install/) 0.31+

## Install

The module installs the operator and its custom resource definitions
(FluxInstance, FluxReport, ResourceSet, ResourceSetInputProvider).
After the install, deploy Flux by creating a
[FluxInstance](https://fluxoperator.dev/docs/crd/fluxinstance/)
resource in the same namespace.

To install the operator with its default settings in the `flux-system`
namespace:

```shell
timoni -n flux-system apply flux-operator \
  oci://ghcr.io/timonish/modules/flux-operator
```

The [Flux Web UI](https://fluxoperator.dev/web-ui/) is
served on port 9080 and configured through the `web.config` values.
For example, to grant read-only access without login by
impersonating a group bound to the `flux-web-user` ClusterRole,
place the following in a `values.cue` file:

```cue
values: {
	web: config: authentication: {
		type: "Anonymous"
		anonymous: groups: ["flux-web-viewers"]
	}
}
```

And apply it with:

```shell
timoni -n flux-system apply flux-operator \
  oci://ghcr.io/timonish/modules/flux-operator \
  --values values.cue
```

To uninstall an instance and delete all its Kubernetes resources:

```shell
timoni -n flux-system delete flux-operator
```

Note that deleting the instance also deletes the custom resource
definitions and thereby every `fluxcd.controlplane.io` custom resource
in the cluster; set `crds.keep: true` to preserve them on uninstall.
Delete the FluxInstance resource first and let the operator tear down
the Flux distribution before removing the operator itself.

## Bundle

For production deployments it is recommended to use a Timoni
[bundle](https://timoni.sh/bundle/) that offers a declarative way of
managing the lifecycle of applications and their infra dependencies.

The following bundle deploys the operator with multitenancy lockdown
for the ResourceSet APIs, Prometheus scraping, and the web interface
authenticated through an OIDC provider (with the client secret
supplied at apply-time) and exposed through a Gateway API HTTPRoute:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "flux-operator"
	instances: {
		"flux-operator": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/flux-operator"
				version: "latest"
			}
			namespace: "flux-system"
			values: {
				multitenancy: {
					enabled:               true
					defaultServiceAccount: "flux"
				}
				web: {
					config: {
						baseURL: "https://flux.example.com"
						authentication: {
							type: "OAuth2"
							oauth2: {
								provider:     "OIDC"
								issuerURL:    "https://dex.example.com"
								clientID:     "flux-web"
								clientSecret: string @timoni(runtime:string:FLUX_WEB_CLIENT_SECRET)
							}
						}
					}
					httpRoute: {
						enabled: true
						parentRefs: [{
							name:      "gateway"
							namespace: "gateway-system"
						}]
						hostnames: ["flux.example.com"]
					}
				}
				serviceMonitor: enabled: true
			}
		}
	}
}
```

The client secret is read at apply-time through a Timoni
[runtime](https://timoni.sh/bundle-runtime/) attribute, keeping the
credentials out of the bundle. To mount the whole web configuration
from an existing Secret instead, set `web.configSecretName`.

Save the bundle as `flux-operator.cue` and apply the stack with:

```shell
timoni bundle apply -f flux-operator.cue
```

## Configuration

All values are optional.

### Operator values

| Key | Type | Default | Description |
|---|---|---|---|
| `crds.install` | `bool` | `true` | Install and manage the custom resource definitions; disable when they are managed outside of this module |
| `crds.keep` | `bool` | `false` | Preserve the custom resource definitions on uninstall |
| `multitenancy.enabled` | `bool` | `false` | Enable [multitenancy lockdown](https://fluxoperator.dev/docs/crd/resourceset/#role-based-access-control) for the ResourceSet APIs |
| `multitenancy.defaultServiceAccount` | `string` | `flux-operator` | Service account used for reconciling the ResourceSet resources when the lockdown is enabled |
| `multitenancy.enabledForWorkloadIdentity` | `bool` | `false` | Pin the workload identity service account of the ResourceSetInputProvider API |
| `multitenancy.defaultWorkloadIdentityServiceAccount` | `string` | `flux-operator` | Service account used for workload identity when its lockdown is enabled |
| `reporting.interval` | `string` | `5m` | Interval at which the [FluxReport](https://fluxoperator.dev/docs/crd/fluxreport/) is computed |
| `logLevel` | `string` | `info` | Log verbosity: `debug`, `info` or `error` |
| `apiPriority.enabled` | `bool` | `false` | Create a FlowSchema assigning the operator API requests to a [priority level](https://kubernetes.io/docs/concepts/cluster-administration/flow-control/); requires Kubernetes 1.29+ |
| `apiPriority.level` | `string` | `workload-high` | Priority level the requests are assigned to |
| `apiPriority.extraServiceAccounts` | `[...]` | `[]` | Additional service accounts matched by the FlowSchema, e.g. the Flux controllers; each takes `name` and `namespace` |
| `marketplace.type` / `account` / `license` | `string` | unset | Marketplace deployment settings for the [enterprise distribution](https://fluxoperator.dev/pricing/) |
| `rbac.create` | `bool` | `true` | Bind the operator service account to the `cluster-admin` role, required for deploying the Flux distribution; skipped in `web.serverOnly` mode |
| `rbac.aggregateClusterRoles` | `bool` | `true` | Grant the Kubernetes `view`, `edit` and `admin` roles access to the ResourceSet APIs |

### Web UI values

| Key | Type | Default | Description |
|---|---|---|---|
| `web.enabled` | `bool` | `true` | Serve the [Flux Status web interface](https://fluxoperator.dev/web-ui/) on port 9080 |
| `web.config` | `#WebConfig` | unset | The Flux Status Page configuration, rendered into an immutable Secret (see the web configuration values below) |
| `web.configSecretName` | `string` | unset | Load the configuration from an existing Secret in the instance namespace carrying the Web Config API document under the `config.yaml` key; the operator reads it through the Kubernetes API and reloads it on change |
| `web.userActions.access` | `string` | unset | GitOps actions access mode, unified into `web.config.userActions.access`; set it explicitly when the configuration comes from `web.configSecretName` so the `serverOnly` ClusterRole matches the loaded configuration |
| `web.serverOnly` | `bool` | `false` | Run only the web server without the operator controllers, bound to a read-only ClusterRole instead of `cluster-admin`; requires a separate instance running the operator |
| `web.serverReplicas` | `int` | `1` | Number of web server replicas, applied only in `serverOnly` mode |
| `web.networkPolicy.create` | `bool` | `true` | Create a NetworkPolicy allowing ingress to the web interface from any namespace, and to the metrics port when the ServiceMonitor is enabled |
| `web.rbac.createRoles` | `bool` | `true` | Create the `flux-web-user` and `flux-web-admin` ClusterRoles for [user access management](https://fluxoperator.dev/docs/web-ui/user-management/) |
| `web.rbac.createAggregation` | `bool` | `false` | Create the `flux-web-edit` ClusterRole aggregating the GitOps action verbs into the Kubernetes `edit` role |

### Web configuration values

The `web.config` values are rendered as the `spec` of the
[Web Config API](https://fluxoperator.dev/docs/web-ui/web-config-api/) document.

| Key | Type | Default | Description |
|---|---|---|---|
| `web.config.baseURL` | `string` | unset | Base URL for constructing the Flux Status Page URLs; required for the `OAuth2` authentication type |
| `web.config.insecure` | `bool` | unset | Use insecure settings across the web application |
| `web.config.search.cached` | `bool` | unset | Serve resource listings from the periodically refreshed in-memory search index instead of querying the Kubernetes API in realtime |
| `web.config.metrics.disabled` | `bool` | unset | Turn off pod metrics collection and hide the resource usage charts |
| `web.config.metrics.scrapeInterval` | `string` | unset (`60s`) | Interval at which pod metrics are collected, clamped to `15s`–`10m` |
| `web.config.userActions.audit` | `[...string]` | unset | GitOps actions to audit (`reconcile`, `suspend`, `resume`, `download`, `restart`, `delete`), or `["*"]` for all of them |
| `web.config.userActions.access` | `string` | unset (`Impersonated`) | How actions are performed: `Impersonated` requires the per-action and native Kubernetes verbs from the user; `FineGrained` uses the web server's own privileges and requires only the per-action verb, extending the `serverOnly` ClusterRole with the permissions the actions need |
| `web.config.authentication.type` | `string` | unset | Authentication type: `Anonymous` or `OAuth2` |
| `web.config.authentication.anonymous` | | unset | Anonymous impersonation identity: `username` and/or `groups` |
| `web.config.authentication.oauth2.provider` | `string` | required with `OAuth2` | OAuth2 provider name: `OIDC` |
| `web.config.authentication.oauth2.clientID` / `clientSecret` | `string` | required with `OAuth2` | OAuth2 client credentials; keep the secret out of the values with a runtime attribute or `web.configSecretName` |
| `web.config.authentication.oauth2.issuerURL` | `string` | required with `OAuth2` | Issuer URL used for OIDC provider discovery |
| `web.config.authentication.oauth2.scopes` | `[...string]` | unset | OAuth2 scopes to request |
| `web.config.authentication.oauth2.authURLParams` | `{[string]: string}` | unset | Additional authorization URL query parameters, e.g. `access_type: offline` |
| `web.config.authentication.oauth2.autoLogin` | `bool` | unset | Redirect unauthenticated users straight to the provider instead of showing the login page |
| `web.config.authentication.oauth2.variables` / `validations` | `[...]` | unset | CEL expressions extracting named variables from the ID token claims and validating them |
| `web.config.authentication.oauth2.profile` / `impersonation` | | unset | CEL expressions populating the user profile and the Kubernetes RBAC impersonation identity |
| `web.config.authentication.sessionDuration` | `string` | unset (one week) | Duration of the user session |
| `web.config.authentication.userCacheSize` | `int` | unset (`100`) | Size of the user cache in number of users |

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image` | `timoniv1.#Image` | upstream release | Container image repository, tag, digest and pull policy |
| `revisionHistoryLimit` | `int` | unset | Number of old ReplicaSets to retain |
| `strategy` | `appsv1.#DeploymentStrategy` | `RollingUpdate` | Rollout strategy; set `type: "Recreate"` for single-replica installs whose web UI is fronted by a load balancer health check |
| `extraArgs` | `[...string]` | `[]` | Extra command line arguments appended after the generated ones; flags override the generated settings |
| `env` | `[...corev1.#EnvVar]` | unset | Environment variables appended after the generated ones |
| `resources` | `timoniv1.#ResourceRequirements` | `100m`/`64Mi` requests, `2000m`/`1Gi` limits | Container resource requirements |
| `securityContext` | `corev1.#SecurityContext` | hardened | Container security context; defaults: no privilege escalation, read-only rootfs, all capabilities dropped (the pod identity comes from `podSecurityContext`) |
| `livenessProbe` / `readinessProbe` | `corev1.#Probe` | `/healthz`, `/readyz` on port 8081 | Container probes |
| `startupProbe` | `corev1.#Probe` | unset | Startup probe |
| `commonLabels` / `commonAnnotations` | `{[string]: string}` | unset | Extra metadata added to all resources |
| `serviceAccount.create` | `bool` | `true` | Create the service account; set to `false` to use an existing one |
| `serviceAccount.name` | `string` | instance name, or `default` when `create: false` | Service account name |
| `serviceAccount.labels` / `annotations` | `{[string]: string}` | unset | Extra service account metadata (e.g. IRSA role annotations) |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount the token through the service account (the pod setting mounts it instead) |

### Pod scheduling values

| Key | Type | Default | Description |
|---|---|---|---|
| `podLabels` / `podAnnotations` | `{[string]: string}` | unset | Extra pod metadata |
| `securityContextPreset` | `hardened` or `platform` | `hardened` | Pod identity defaults: `hardened` pins the image's non-root UID/GID `65532`, `platform` leaves the identity to the cluster (e.g. OpenShift SCCs) |
| `podSecurityContext` | `corev1.#PodSecurityContext` | per `securityContextPreset` | Pod security context |
| `imagePullSecrets` | `[...]` | unset | Secrets for pulling from private registries |
| `priorityClassName` | `string` | unset | Pod priority class; `system-cluster-critical` is recommended for the operator |
| `affinity.podAntiAffinity` | `soft`, `hard`, `none` or raw rules | `soft` | Spread the replicas across nodes; raw rules replace the preset and need explicit label selectors |
| `affinity.nodeAffinity` / `affinity.podAffinity` | raw rules | unset | Node and pod affinity rules |
| `nodeSelector` | `{[string]: string}` | Linux nodes | Node selection; a supplied value replaces the default |
| `tolerations` / `topologySpreadConstraints` | | unset | Standard scheduling controls; spread constraints without a label selector match the instance pods |
| `hostAliases` | `[...corev1.#HostAlias]` | unset | Extra entries for the pod /etc/hosts |
| `schedulerName` | `string` | unset | Alternate scheduler |
| `dnsPolicy` / `dnsConfig` | | unset | Pod DNS settings |
| `hostNetwork` | `bool` | `false` | Expose the container ports on the host network; pods resolving cluster names may need `dnsPolicy: "ClusterFirstWithHostNet"` |
| `terminationGracePeriodSeconds` | `int` | unset | Pod termination grace period |
| `automountServiceAccountToken` | `bool` | `true` | Automount the API credentials in the pod |
| `initContainers` / `extraContainers` | `[...corev1.#Container]` | unset | Additional containers |
| `tmpVolume` | `corev1.#VolumeSource` | `emptyDir` | Volume backing /tmp (the root filesystem is read-only) |
| `extraVolumes` / `extraVolumeMounts` | `[...]` | unset | Additional volumes, e.g. a CA certificates bundle |
| `deploymentLabels` / `deploymentAnnotations` | `{[string]: string}` | unset | Extra Deployment metadata |

### Service values

| Key | Type | Default | Description |
|---|---|---|---|
| `service.port` | `int` | `8080` | Service metrics port |
| `service.webPort` | `int` | `9080` | Service web port, the backend of `web.ingress` and `web.httpRoute`; exposed when the web interface is enabled |
| `service.type` | `string` | `ClusterIP` | Service type |
| `service.annotations` / `labels` | `{[string]: string}` | unset | Extra Service metadata |
| `service.clusterIP` / `externalIPs` / `loadBalancerIP` / `loadBalancerClass` / `loadBalancerSourceRanges` / `externalTrafficPolicy` | | unset | Service networking settings per type |
| `service.nodePort` / `webNodePort` | `int` | `0` (auto) | Node ports with the `NodePort` and `LoadBalancer` service types |
| `service.ipFamilies` / `ipFamilyPolicy` | | unset | Service IP family settings |

### Routing values

| Key | Type | Default | Description |
|---|---|---|---|
| `web.ingress.enabled` | `bool` | `false` | Create an Ingress for the web interface |
| `web.ingress.className` | `string` | unset | IngressClass name |
| `web.ingress.hosts` | `[...#IngressHost]` | required when enabled | Ingress rules: each host takes `paths` with `path` and `pathType` (default `/` `Prefix`) |
| `web.ingress.tls` | `[...networkingv1.#IngressTLS]` | unset | TLS termination settings |
| `web.ingress.annotations` / `labels` | `{[string]: string}` | unset | Extra Ingress metadata |
| `web.httpRoute.enabled` | `bool` | `false` | Create a Gateway API HTTPRoute for the web interface |
| `web.httpRoute.parentRefs` | `[...]` | required when enabled | Gateways the route attaches to |
| `web.httpRoute.hostnames` | `[...string]` | unset | Hostnames the route matches |
| `web.httpRoute.rules` | `[...]` | match all | Route rules with `matches` and `filters`; the backend reference is generated by the module |
| `web.httpRoute.annotations` / `labels` | `{[string]: string}` | unset | Extra HTTPRoute metadata |

### Disruption values

| Key | Type | Default | Description |
|---|---|---|---|
| `podDisruptionBudget.enabled` | `bool` | `true` when the web server runs replicated in `serverOnly` mode | Create a PodDisruptionBudget |
| `podDisruptionBudget.minAvailable` | `int` or percent | `1` | Minimum available pods; mutually exclusive with `maxUnavailable` |
| `podDisruptionBudget.maxUnavailable` | `int` or percent | unset | Maximum unavailable pods |
| `podDisruptionBudget.unhealthyPodEvictionPolicy` | `string` | unset | `IfHealthyBudget` or `AlwaysAllow`; requires Kubernetes 1.27+ |

### Monitoring values

| Key | Type | Default | Description |
|---|---|---|---|
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor for the operator metrics endpoint, in the instance namespace |
| `serviceMonitor.additionalLabels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata, e.g. labels for Prometheus discovery |
| `serviceMonitor.jobLabel` | `string` | `app.kubernetes.io/name` | Service label used as the Prometheus job name |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | unset | Scrape cadence; defaults to the Prometheus settings |
| `serviceMonitor.honorLabels` | `bool` | `false` | Keep scraped label values on collision |
| `serviceMonitor.enableHttp2` | `bool` | unset | Enable HTTP2 for scraping |
| `serviceMonitor.scheme` / `tlsConfig` / `bearerTokenFile` / `bearerTokenSecret` / `proxyUrl` | | unset | Scrape scheme, TLS, authentication and proxy settings |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules for the samples and the targets |
| `serviceMonitor.sampleLimit` / `targetLimit` / `labelLimit` / `labelNameLengthLimit` / `labelValueLengthLimit` | `int` | unset | Scrape limits |
| `serviceMonitor.targetLabels` / `podTargetLabels` | `[...string]` | unset | Service/pod labels copied onto the metrics |
