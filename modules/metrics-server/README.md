# metrics-server

A [Timoni](https://timoni.sh) module for deploying [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server), a scalable source of container resource metrics for built-in autoscaling pipelines.

## Version

<!-- versions:start -->
Latest module version is `0.9.0-1`, packaging the upstream release
[v0.9.0](https://github.com/kubernetes-sigs/metrics-server/releases/tag/v0.9.0)
with the following container images:

| Image | Tag |
|---|---|
| `registry.k8s.io/metrics-server/metrics-server` | v0.9.0 |
| `registry.k8s.io/autoscaling/addon-resizer` | 1.8.24 |
<!-- versions:end -->

To list all available versions and their digests:

```shell
timoni mod list oci://ghcr.io/timonish/modules/metrics-server
```

## Prerequisites

- Kubernetes 1.25+
- Timoni 0.30+

## Install

To create an instance using the default values:

```shell
timoni -n kube-system apply metrics-server \
  oci://ghcr.io/timonish/modules/metrics-server
```

To customize the instance, place the configuration in a `values.cue` file:

```cue
values: {
	// Required on clusters where the kubelet serving certificates
	// are self-signed (e.g. kind, k3s, minikube).
	args: ["--kubelet-insecure-tls"]
}
```

And apply it with:

```shell
timoni -n kube-system apply metrics-server \
  oci://ghcr.io/timonish/modules/metrics-server \
  --values values.cue
```

To uninstall an instance and delete all the Kubernetes resources:

```shell
timoni -n kube-system delete metrics-server
```

## Bundle

For production deployments it is recommended to use a Timoni
[bundle](https://timoni.sh/bundle/) that offers a declarative way of
managing the lifecycle of applications and their infra dependencies.

The following bundle deploys a highly available metrics-server on a
cluster with cert-manager and prometheus-operator installed:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "monitoring"
	instances: {
		"metrics-server": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/metrics-server"
				version: "latest"
			}
			namespace: "monitoring"
			values: {
				replicas: 2
				podDisruptionBudget: {
					enabled:      true
					minAvailable: 1
				}
				topologySpreadConstraints: [{
					maxSkew:           1
					topologyKey:       "kubernetes.io/hostname"
					whenUnsatisfiable: "DoNotSchedule"
					labelSelector: matchLabels: "app.kubernetes.io/name": "metrics-server"
				}]
				serviceMonitor: enabled: true
				tls: type: "cert-manager"
				apiService: insecureSkipTLSVerify: false
			}
		}
	}
}
```

With `tls.type: cert-manager`, the module creates a Certificate issued by
a self-signed Issuer (or by `tls.certManager.existingIssuer`) and injects
the CA into the APIService; the apply waits for the certificate issuance.

Save the bundle as `monitoring.cue` and apply the stack with:

```shell
timoni bundle apply -f monitoring.cue
```

## Configuration

All values are optional.

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `image` | `timoniv1.#Image` | upstream release | Container image repository, tag, digest and pull policy |
| `replicas` | `int` | `1` | Number of pod replicas |
| `revisionHistoryLimit` | `int` | unset | Number of old ReplicaSets to retain |
| `updateStrategy` | `appsv1.#DeploymentStrategy` | unset | Deployment rollout strategy |
| `containerPort` | `int` | `10250` | HTTPS serving port of the container |
| `defaultArgs` | `[...string]` | upstream defaults | Base command line arguments; override only when the upstream defaults are unsuitable |
| `args` | `[...string]` | `[]` | Extra arguments appended after `defaultArgs`, e.g. `--kubelet-insecure-tls` |
| `resources` | `timoniv1.#ResourceRequirements` | `100m` / `200Mi` requests | Container resource requirements; ignored when `addonResizer` is enabled (the nanny owns them) |
| `securityContext` | `corev1.#SecurityContext` | hardened | Container security context; defaults: no privilege escalation, read-only rootfs, runAsNonRoot, UID 1000, RuntimeDefault seccomp, all capabilities dropped |
| `livenessProbe` / `readinessProbe` | `corev1.#Probe` | `/livez` / `/readyz` | Container probes |
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |
| `rbac.create` | `bool` | `true` | Create the cluster roles and bindings |
| `serviceAccount.create` | `bool` | `true` | Create the service account; set to `false` to use an existing one |
| `serviceAccount.name` | `string` | instance name, or `default` when `create: false` | Service account name |
| `serviceAccount.annotations` | `{[string]: string}` | unset | Service account annotations (e.g. for IRSA) |
| `serviceAccount.secrets` | `[...]` | unset | Secrets mountable by the service account |

### Pod scheduling values

| Key | Type | Default | Description |
|---|---|---|---|
| `podLabels` / `podAnnotations` | `{[string]: string}` | unset | Extra pod metadata |
| `podSecurityContext` | `corev1.#PodSecurityContext` | unset | Pod security context |
| `imagePullSecrets` | `[...]` | unset | Secrets for pulling from private registries |
| `priorityClassName` | `string` | `system-cluster-critical` | Pod priority class |
| `hostNetwork` | `bool` | `false` | Run in the host network namespace; rollouts then default to `maxUnavailable: 1` to free the host port |
| `affinity` | `corev1.#Affinity` | Linux nodes | Pod affinity; a supplied value replaces the default |
| `nodeSelector` / `tolerations` / `topologySpreadConstraints` | | unset | Standard scheduling controls |
| `dnsPolicy` | `string` | unset | Pod DNS policy, e.g. `ClusterFirstWithHostNet` for host-network pods |
| `dnsConfig` | `corev1.#PodDNSConfig` | unset | Pod DNS configuration |
| `schedulerName` | `string` | unset | Alternate scheduler |
| `deploymentAnnotations` | `{[string]: string}` | unset | Annotations on the Deployment |
| `podDisruptionBudget.enabled` | `bool` | `false` | Create a PodDisruptionBudget; `minAvailable` / `maxUnavailable` are mutually exclusive (schema-enforced), `unhealthyPodEvictionPolicy` is applied on Kubernetes 1.27+ only |
| `extraVolumes` / `extraVolumeMounts` | `[...]` | unset | Additional volumes for the metrics-server container |
| `tmpVolume` | `corev1.#VolumeSource` | `emptyDir` | Volume backing the `/tmp` certificate directory |

### Service and APIService values

| Key | Type | Default | Description |
|---|---|---|---|
| `service.type` | `string` | `ClusterIP` | Service type |
| `service.port` | `int` | `443` | Service port |
| `service.annotations` / `service.labels` | `{[string]: string}` | unset | Extra Service metadata |
| `apiService.create` | `bool` | `true` | Register the `v1beta1.metrics.k8s.io` APIService |
| `apiService.annotations` | `{[string]: string}` | unset | Extra APIService annotations |
| `apiService.insecureSkipTLSVerify` | `bool` | `true`; `false` when cert-manager injects the CA or `caBundle` is set | Skip TLS verification of the metrics API |
| `apiService.caBundle` | `string` | unset | PEM encoded CA bundle for TLS verification |

### TLS values

| Key | Type | Default | Description |
|---|---|---|---|
| `tls.type` | `string` | `metrics-server` | One of `metrics-server` (self-signed at runtime), `cert-manager`, `existingSecret` |
| `tls.clusterDomain` | `string` | `cluster.local` | Cluster domain used for the certificate SANs |
| `tls.certManager.addInjectorAnnotations` | `bool` | `true` | Add the `cert-manager.io/inject-ca-from` annotation to the APIService |
| `tls.certManager.existingIssuer` | | disabled | Reference an existing `Issuer`/`ClusterIssuer`; `name` is required (schema-enforced) when `enabled` |
| `tls.certManager.duration` / `renewBefore` | `string` | unset | Certificate lifetime settings |
| `tls.certManager.annotations` / `labels` | `{[string]: string}` | unset | Extra Certificate/Issuer metadata |
| `tls.existingSecret.name` | `string` | unset | Name of an existing TLS secret to mount; the CA must be supplied via `apiService.caBundle` unless TLS verification is skipped |

### Monitoring values

| Key | Type | Default | Description |
|---|---|---|---|
| `metrics.enabled` | `bool` | `false` | Allow unauthenticated access to `/metrics` |
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor (implies `metrics.enabled`) |
| `serviceMonitor.additionalLabels` | `{[string]: string}` | unset | Labels for Prometheus discovery |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | `1m` / `10s` | Scrape settings; set to `""` to fall back to the Prometheus Operator defaults |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules |

### Addon-resizer values

| Key | Type | Default | Description |
|---|---|---|---|
| `addonResizer.enabled` | `bool` | `false` | Run the addon-resizer nanny sidecar that scales resources with cluster size |
| `addonResizer.image` | `timoniv1.#Image` | upstream release | Nanny container image |
| `addonResizer.resources` | `timoniv1.#ResourceRequirements` | `40m` / `25Mi` as both requests and limits | Nanny resource requirements |
| `addonResizer.securityContext` | `corev1.#SecurityContext` | hardened | Nanny security context |
| `addonResizer.nanny` | | `0m`/`1m`/`0Mi`/`2Mi`, `minClusterSize` 100, `pollPeriod` 300000, `threshold` 5 | Scaling parameters: resources are computed as `base + extra * max(nodes, minClusterSize)` |
