# metrics-server

A [Timoni](https://timoni.sh) module for deploying [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server), a scalable source of container resource metrics for built-in autoscaling pipelines.

## Version

<!-- versions:start -->
Latest module version is `0.9.0-5`, packaging the upstream release
[v0.9.0](https://github.com/kubernetes-sigs/metrics-server/releases/tag/v0.9.0)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `registry.k8s.io/metrics-server/metrics-server` | v0.9.0 | `sha256:d9862115e7c7881280d3d75ca26bda8ffc0fc213315979575bf23ce9826205c0` |
| `registry.k8s.io/autoscaling/addon-resizer` | 1.8.24 | `sha256:bcf3d19331e8cb1adf7e834aac0c7a98653bb27604d36482a2fa888dc566463a` |
<!-- versions:end -->

To list all available versions and their digests:

```shell
timoni mod list oci://ghcr.io/timonish/modules/metrics-server
```

## Prerequisites

- Kubernetes 1.25+
- [Timoni](https://timoni.sh/install/) 0.31+

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
	extraArgs: ["--kubelet-insecure-tls"]
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
| `strategy` | `appsv1.#DeploymentStrategy` | unset | Deployment rollout strategy |
| `containerPort` | `int` | `10250` | HTTPS serving port of the container |
| `defaultArgs` | `[...string]` | upstream defaults | Base command line arguments; override only when the upstream defaults are unsuitable |
| `extraArgs` | `[...string]` | `[]` | Extra arguments appended after `defaultArgs`, e.g. `--kubelet-insecure-tls` |
| `env` | `[...corev1.#EnvVar]` | unset | Environment variables for the container |
| `resources` | `timoniv1.#ResourceRequirements` | `100m` / `200Mi` requests | Container resource requirements; ignored when `addonResizer` is enabled (the nanny owns them) |
| `securityContext` | `corev1.#SecurityContext` | hardened | Container security context; defaults: no privilege escalation, read-only rootfs, all capabilities dropped (the pod identity comes from `podSecurityContext`) |
| `livenessProbe` / `readinessProbe` | `corev1.#Probe` | `/livez` / `/readyz` | Container probes |
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |
| `rbac.create` | `bool` | `true` | Create the cluster roles and bindings |
| `serviceAccount.create` | `bool` | `true` | Create the service account; set to `false` to use an existing one |
| `serviceAccount.name` | `string` | instance name, or `default` when `create: false` | Service account name |
| `serviceAccount.labels` / `serviceAccount.annotations` | `{[string]: string}` | unset | Service account metadata (e.g. IRSA annotations) |
| `serviceAccount.secrets` | `[...]` | unset | Secrets mountable by the service account |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount the token through the service account (the pod setting mounts it by default) |
| `automountServiceAccountToken` | `bool` | `true` | Mount the service account token into the pod |

### Pod scheduling values

| Key | Type | Default | Description |
|---|---|---|---|
| `podLabels` / `podAnnotations` | `{[string]: string}` | unset | Extra pod metadata |
| `securityContextPreset` | `hardened` or `platform` | `hardened` | Pod identity defaults: `hardened` pins UID/GID `1000`, `platform` leaves the identity to the cluster (e.g. OpenShift SCCs) |
| `podSecurityContext` | `corev1.#PodSecurityContext` | per `securityContextPreset` | Pod security context |
| `imagePullSecrets` | `[...]` | unset | Secrets for pulling from private registries |
| `priorityClassName` | `string` | `system-cluster-critical` | Pod priority class |
| `hostNetwork` | `bool` | `false` | Run in the host network namespace; rollouts then default to `maxUnavailable: 1` to free the host port |
| `nodeSelector` | `{[string]: string}` | Linux nodes | Node selection; a supplied value replaces the default |
| `affinity.podAntiAffinity` | `soft`, `hard`, `none` or raw rules | `soft` | Spread the replicas across nodes; raw rules replace the preset |
| `affinity.nodeAffinity` / `affinity.podAffinity` | raw rules | unset | Node and pod affinity rules |
| `tolerations` / `topologySpreadConstraints` | | unset | Standard scheduling controls |
| `terminationGracePeriodSeconds` | `int` | unset | Pod termination grace period |
| `dnsPolicy` | `string` | unset | Pod DNS policy, e.g. `ClusterFirstWithHostNet` for host-network pods |
| `dnsConfig` | `corev1.#PodDNSConfig` | unset | Pod DNS configuration |
| `schedulerName` | `string` | unset | Alternate scheduler |
| `deploymentAnnotations` | `{[string]: string}` | unset | Annotations on the Deployment |
| `podDisruptionBudget.enabled` | `bool` | `false` | Create a PodDisruptionBudget; `minAvailable` (default `1`) and `maxUnavailable` are mutually exclusive (schema-enforced), `unhealthyPodEvictionPolicy` is applied on Kubernetes 1.27+ only |
| `extraVolumes` / `extraVolumeMounts` | `[...]` | unset | Additional volumes for the metrics-server container |
| `extraContainers` / `initContainers` | `[...corev1.#Container]` | unset | Additional containers added to the pods |
| `tmpVolume` | `corev1.#VolumeSource` | `emptyDir` | Volume backing the `/tmp` certificate directory |

### Service and APIService values

| Key | Type | Default | Description |
|---|---|---|---|
| `service.type` | `string` | `ClusterIP` | Service type |
| `service.port` | `int` | `443` | Service port |
| `service.clusterIP` | `string` | unset | Explicit cluster IP |
| `service.ipFamilies` / `service.ipFamilyPolicy` | | unset | Dual-stack settings |
| `service.externalIPs` | `[...string]` | unset | External IPs accepted by the Service |
| `service.nodePort` | `int` | `0` (auto) | Node port when `type: NodePort` |
| `service.loadBalancerIP` / `loadBalancerClass` / `loadBalancerSourceRanges` | | unset | LoadBalancer settings when `type: LoadBalancer` |
| `service.externalTrafficPolicy` | `Cluster` or `Local` | unset | Traffic policy for non-ClusterIP types |
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
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor in the instance namespace (implies `metrics.enabled`) |
| `serviceMonitor.additionalLabels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata, e.g. labels for Prometheus discovery |
| `serviceMonitor.jobLabel` | `string` | `app.kubernetes.io/name` | Service label used as the Prometheus job name |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | unset | Scrape cadence; defaults to the Prometheus settings |
| `serviceMonitor.scheme` | `https` or `http` | `https` | Scrape scheme |
| `serviceMonitor.tlsConfig` | `{...}` | `insecureSkipVerify: true` | Scrape TLS settings; with `tls.type: cert-manager` set the issued CA here to verify |
| `serviceMonitor.honorLabels` | `bool` | `false` | Keep scraped label values on collision |
| `serviceMonitor.enableHttp2` | `bool` | unset | Enable HTTP2 for scraping |
| `serviceMonitor.bearerTokenFile` / `bearerTokenSecret` / `proxyUrl` | | unset | Scrape authentication and proxy settings |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules |
| `serviceMonitor.sampleLimit` / `targetLimit` / `labelLimit` / `labelNameLengthLimit` / `labelValueLengthLimit` | `int` | unset | Scrape limits |
| `serviceMonitor.targetLabels` / `podTargetLabels` | `[...string]` | unset | Service/pod labels copied onto the metrics |

### Addon-resizer values

| Key | Type | Default | Description |
|---|---|---|---|
| `addonResizer.enabled` | `bool` | `false` | Run the addon-resizer nanny sidecar that scales resources with cluster size |
| `addonResizer.image` | `timoniv1.#Image` | upstream release | Nanny container image |
| `addonResizer.resources` | `timoniv1.#ResourceRequirements` | `40m` / `25Mi` as both requests and limits | Nanny resource requirements |
| `addonResizer.securityContext` | `corev1.#SecurityContext` | hardened | Nanny security context |
| `addonResizer.nanny` | | `0m`/`1m`/`0Mi`/`2Mi`, `minClusterSize` 100, `pollPeriod` 300000, `threshold` 5 | Scaling parameters: resources are computed as `base + extra * max(nodes, minClusterSize)` |
