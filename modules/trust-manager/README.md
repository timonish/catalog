# trust-manager

A [Timoni](https://timoni.sh) module for deploying [trust-manager](https://github.com/cert-manager/trust-manager), the cert-manager operator for distributing trusted CA bundles across clusters.

## Version

<!-- versions:start -->
Latest module version is `0.24.0-3`, packaging the upstream release
[v0.24.0](https://github.com/cert-manager/trust-manager/releases/tag/v0.24.0)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `quay.io/jetstack/trust-manager` | v0.24.0 | `sha256:a7c1d71cad37b404738192213e3801dbf89fe797e72664b0ff0d498db35cea74` |
| `quay.io/jetstack/trust-pkg-debian-trixie` | 20250419.1 | `sha256:17084a794d1e75065c9047438e2a6167907771fe78d7e4b5d4373a4b1d4e0494` |
<!-- versions:end -->

To list all available versions and their digests:

```shell
timoni mod list oci://ghcr.io/timonish/modules/trust-manager
```

## Prerequisites

- Kubernetes 1.25+
- [Timoni](https://timoni.sh/install/) 0.31+
- [cert-manager](https://github.com/timonish/catalog/tree/main/modules/cert-manager) running in the cluster

trust-manager serves a validating webhook whose certificate is issued
and rotated by cert-manager, and its CA is injected into the webhook
configuration by the cert-manager cainjector — cert-manager must be
running before this module is installed.

## Install

To install trust-manager in the same namespace as cert-manager run:

```shell
timoni -n cert-manager apply trust-manager \
  oci://ghcr.io/timonish/modules/trust-manager
```

To uninstall the instance and delete all its Kubernetes resources
including the CRDs:

```shell
timoni -n cert-manager delete trust-manager
```

Set `crds.keep: true` to leave the CRDs in place when the instance is deleted.

## Bundle

For production deployments it is recommended to use a Timoni
[bundle](https://timoni.sh/bundle/) that offers a declarative way of
managing the lifecycle of applications and their infra dependencies.

The following bundle deploys cert-manager and trust-manager together,
with trust-manager allowed to write the trusted material to a named
Secret next to the ConfigMap targets:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "pki"
	instances: {
		"cert-manager": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/cert-manager"
				version: "latest"
			}
			namespace: "cert-manager"
		}
		"trust-manager": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/trust-manager"
				version: "latest"
			}
			namespace: "cert-manager"
			values: {
				secretTargets: {
					enabled: true
					authorizedSecrets: ["public-bundle"]
				}
			}
		}
	}
}
```

Save the bundle as `pki.cue` and apply the stack with:

```shell
timoni bundle apply -f pki.cue
```

Timoni applies the instances in order, waiting for cert-manager to
become ready before installing trust-manager.

## Configuration

All values are optional.

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image` | `timoniv1.#Image` | upstream release | Container image repository, tag, digest and pull policy |
| `replicas` | `int` | `1` | Number of pod replicas; leader election makes extra replicas hot standbys |
| `revisionHistoryLimit` | `int` | `10` | Number of old ReplicaSets to retain |
| `resources` | `timoniv1.#ResourceRequirements` | unset | Container resource requirements |
| `securityContext` | `corev1.#SecurityContext` | hardened | Container security context; defaults: no privilege escalation, read-only rootfs, all capabilities dropped (the pod identity comes from `podSecurityContext`) |
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |
| `logLevel` | `int` | `1` | Log verbosity from `1` to `5`, higher is more verbose |
| `logFormat` | `string` | `text` | `text` or `json` |
| `minTLSVersion` | `string` | Go default | Minimum TLS version of the webhook and metrics servers, e.g. `VersionTLS13` |
| `cipherSuites` | `string` | Go default | Comma-separated TLS cipher suites of the webhook and metrics servers |
| `leaderElection.enabled` | `bool` | `true` | Elect a leader among the replicas |
| `leaderElection.leaseDuration` / `renewDeadline` | `string` | `15s` / `10s` | Leader election timing; raise both on clusters with an overloaded API server |
| `readinessProbe` | `corev1.#Probe` | `/readyz` on port `6060` | Readiness probe; `httpGet.port`/`path` are wired into the container arguments |
| `strategy` | `appsv1.#DeploymentStrategy` | unset | Deployment rollout strategy |
| `env` | `[...corev1.#EnvVar]` | unset | Environment variables for the container |
| `deploymentAnnotations` | `{[string]: string}` | unset | Annotations on the Deployment |
| `extraArgs` | `[...string]` | `[]` | Extra command line arguments appended after the generated ones; flags override the generated configuration |
| `serviceAccount.create` | `bool` | `true` | Create the service account; set to `false` to use an existing one |
| `serviceAccount.name` | `string` | instance name, or `default` when `create: false` | Service account name |
| `serviceAccount.annotations` | `{[string]: string}` | unset | Extra service account annotations (e.g. IRSA role annotations) |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount the token through the service account (the pod setting mounts it by default) |
| `imagePullSecrets` | `[...]` | unset | Secrets for pulling from private registries, attached to the service account |
| `rbac.create` | `bool` | `true` | Create the roles and bindings |
| `rbac.aggregateClusterRoles` | `bool` | `true` | Aggregate Bundle read access into the OpenShift-style `cluster-reader` ClusterRole |
| `crds.install` | `bool` | `true` | Install the Bundle CRD; disable when the CRD is managed outside of this module |
| `crds.keep` | `bool` | `false` | Keep the CRD (and thus all Bundles) around when the instance is deleted |

### Trust values

| Key | Type | Default | Description |
|---|---|---|---|
| `trust.namespace` | `string` | instance namespace | The trust namespace: Bundle sources are read from ConfigMaps and Secrets in this namespace only; it must exist at install time |
| `targetNamespaces` | `[...string]` | unset (all namespaces) | Restrict the namespaces trust-manager writes targets to; the ConfigMap, Secret and Event grants become per-namespace Roles over the targets, the trust namespace and the instance namespace; must be non-empty when set (schema-enforced) |
| `secretTargets.enabled` | `bool` | `false` | Allow writing trust bundles to Secret targets; only Secrets authorized below are ever written |
| `secretTargets.authorizedSecretsAll` | `bool` | `false` | Authorize every Secret in the cluster; grants cluster-wide Secret read access, use with caution |
| `secretTargets.authorizedSecrets` | `[...string]` | `[]` | Secret names trust-manager may read and write across all namespaces |
| `filterExpiredCertificates` | `bool` | `false` | Filter expired certificates out of the bundle targets |
| `filterNonCACerts` | `bool` | `false` | Keep only CA certificates in the bundle targets |
| `defaultPackage.enabled` | `bool` | `true` | Ship the default package of publicly trusted CA certificates (derived from Debian ca-certificates) in an init container, enabling the `useDefaultCAs` Bundle source |
| `defaultPackage.image` | `timoniv1.#Image` | tracked package release | Default package image; its version follows the Debian cadence independently of the trust-manager releases |
| `defaultPackage.resources` | `timoniv1.#ResourceRequirements` | unset | Init container resource requirements |
| `defaultPackage.securityContext` | `corev1.#SecurityContext` | hardened | Init container security context |

### Webhook values

The webhook certificate is issued by cert-manager from a dedicated
self-signed Issuer created by this module, and rotated automatically;
the cainjector keeps the webhook configuration CA in sync.

| Key | Type | Default | Description |
|---|---|---|---|
| `webhook.host` / `port` | `string` / `int` | `0.0.0.0` / `6443` | Webhook listener inside the pod |
| `webhook.timeoutSeconds` | `int` | `5` | Admission review request timeout |
| `webhook.hostNetwork` | `bool` | `false` | Run the pod in the host network namespace, for managed clusters with a custom CNI where the control plane cannot reach the pod network |
| `webhook.service.type` | `string` | `ClusterIP` | Webhook Service type |
| `webhook.service.nodePort` | `int` | `0` (auto) | Node port of the webhook Service when the type is `NodePort` |
| `webhook.service.annotations` / `labels` | `{[string]: string}` | unset | Extra webhook Service metadata |
| `metrics.service.annotations` / `labels` | `{[string]: string}` | unset | Extra metrics Service metadata |
| `webhook.service.ipFamilies` / `ipFamilyPolicy` | | unset | Service IP family settings |
| `webhook.tls.certificate.duration` | `string` | cert-manager default | Webhook certificate duration, e.g. `8766h` for a year |
| `webhook.tls.certificate.secretTemplate.labels` / `annotations` | `{[string]: string}` | unset | Extra metadata on the certificate Secret |
| `webhook.tls.approverPolicy.enabled` | `bool` | `false` | Create an approver-policy CertificateRequestPolicy auto-approving the webhook certificate; enable when approver-policy manages certificate request approval in the cluster |
| `webhook.tls.approverPolicy.certManagerNamespace` / `certManagerServiceAccount` | `string` | `cert-manager` | The cert-manager installation granted use of the policy |

### Pod scheduling values

| Key | Type | Default | Description |
|---|---|---|---|
| `podLabels` / `podAnnotations` | `{[string]: string}` | unset | Extra pod metadata |
| `securityContextPreset` | `hardened` or `platform` | `hardened` | Pod identity defaults: `hardened` pins the image's non-root UID `65532`, `platform` leaves the identity to the cluster (e.g. OpenShift SCCs) |
| `podSecurityContext` | `corev1.#PodSecurityContext` | per `securityContextPreset` | Pod security context |
| `priorityClassName` | `string` | unset | Pod priority class |
| `nodeSelector` | `{[string]: string}` | Linux nodes | Node selection; trust-manager does not support Windows nodes |
| `affinity.podAntiAffinity` | `soft`, `hard`, `none` or raw rules | `soft` | Spread the replicas across nodes; raw rules replace the preset |
| `affinity.nodeAffinity` / `affinity.podAffinity` | raw rules | unset | Node and pod affinity rules |
| `tolerations` / `topologySpreadConstraints` | | unset | Standard scheduling controls |
| `automountServiceAccountToken` | `bool` | `true` | Automount the API credentials in the pod |
| `extraVolumes` / `extraVolumeMounts` | `[...]` | unset | Additional volumes and container mounts |
| `podDisruptionBudget.enabled` | `bool` | `false` | Create a PodDisruptionBudget for the pods |
| `podDisruptionBudget.minAvailable` / `maxUnavailable` | `int` or percent | `minAvailable: 1` | Disruption budget; the two are mutually exclusive (schema-enforced) |
| `podDisruptionBudget.unhealthyPodEvictionPolicy` | `string` | unset | `IfHealthyBudget` or `AlwaysAllow` (Kubernetes 1.27+) |

### Monitoring values

| Key | Type | Default | Description |
|---|---|---|---|
| `metrics.port` | `int` | `9402` | Prometheus metrics port, served on `/metrics` |
| `metrics.service.enabled` | `bool` | `true` | Create the metrics Service |
| `metrics.service.type` | `string` | `ClusterIP` | Metrics Service type |
| `metrics.service.ipFamilies` / `ipFamilyPolicy` | | unset | Service IP family settings |
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor for the metrics Service, in the instance namespace |
| `serviceMonitor.additionalLabels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata, e.g. labels for Prometheus discovery |
| `serviceMonitor.jobLabel` | `string` | `app.kubernetes.io/name` | Service label used as the Prometheus job name |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | unset | Scrape cadence; defaults to the Prometheus settings |
| `serviceMonitor.honorLabels` | `bool` | `false` | Keep scraped label values on collision |
| `serviceMonitor.enableHttp2` | `bool` | unset | Enable HTTP2 for scraping |
| `serviceMonitor.scheme` / `tlsConfig` / `bearerTokenFile` / `bearerTokenSecret` / `proxyUrl` | | unset | Scrape scheme, TLS, authentication and proxy settings |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules for the samples and the targets |
| `serviceMonitor.sampleLimit` / `targetLimit` / `labelLimit` / `labelNameLengthLimit` / `labelValueLengthLimit` | `int` | unset | Scrape limits |
| `serviceMonitor.targetLabels` / `podTargetLabels` | `[...string]` | unset | Service/pod labels copied onto the metrics |
