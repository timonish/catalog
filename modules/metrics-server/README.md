# metrics-server

A timoni.sh module for deploying Kubernetes Metrics Server, a scalable source of container resource metrics for built-in autoscaling pipelines.

## Install

To create an instance using the default values:

```shell
timoni -n kube-system apply metrics-server \
  oci://ghcr.io/timonish/modules/metrics-server
```

On clusters where the kubelet serving certificates are self-signed
(e.g. kind, k3s, minikube):

```shell
timoni -n kube-system apply metrics-server \
  oci://ghcr.io/timonish/modules/metrics-server \
  --values - <<EOF
values: args: ["--kubelet-insecure-tls"]
EOF
```

To change the configuration of an existing instance, rerun `timoni apply`
with the updated values; to uninstall:

```shell
timoni -n kube-system delete metrics-server
```

## Configuration

The module covers the full configuration surface of the upstream Helm chart
(`metrics-server-helm-chart-3.13.0`). All values are optional.

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
| `resources` | `timoniv1.#ResourceRequirements` | `100m` / `200Mi` requests | Container resource requirements |
| `securityContext` | `corev1.#SecurityContext` | hardened | Container security context |
| `livenessProbe` / `readinessProbe` | `corev1.#Probe` | `/livez` / `/readyz` | Container probes |
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |
| `rbac.create` | `bool` | `true` | Create the cluster roles and bindings |
| `serviceAccount.create` | `bool` | `true` | Create the service account; set to `false` to use an existing one |
| `serviceAccount.name` | `string` | instance name | Service account name |
| `serviceAccount.annotations` | `{[string]: string}` | unset | Service account annotations (e.g. for IRSA) |
| `serviceAccount.secrets` | `[...]` | unset | Secrets mountable by the service account |

### Pod scheduling values

| Key | Type | Default | Description |
|---|---|---|---|
| `podLabels` / `podAnnotations` | `{[string]: string}` | unset | Extra pod metadata |
| `podSecurityContext` | `corev1.#PodSecurityContext` | unset | Pod security context |
| `imagePullSecrets` | `[...]` | unset | Secrets for pulling from private registries |
| `priorityClassName` | `string` | `system-cluster-critical` | Pod priority class |
| `hostNetwork` | `bool` | `false` | Run in the host network namespace (e.g. Weave on EKS) |
| `nodeSelector` / `tolerations` / `affinity` / `topologySpreadConstraints` | | Linux nodes | Standard scheduling controls |
| `dnsConfig` | `corev1.#PodDNSConfig` | unset | Pod DNS configuration |
| `schedulerName` | `string` | unset | Alternate scheduler |
| `deploymentAnnotations` | `{[string]: string}` | unset | Annotations on the Deployment |
| `podDisruptionBudget.enabled` | `bool` | `false` | Create a PodDisruptionBudget; set one of `minAvailable` / `maxUnavailable`, optionally `unhealthyPodEvictionPolicy` |
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
| `apiService.insecureSkipTLSVerify` | `bool` | `true` | Skip TLS verification of the metrics API |
| `apiService.caBundle` | `string` | unset | PEM encoded CA bundle for TLS verification |

### TLS values

| Key | Type | Default | Description |
|---|---|---|---|
| `tls.type` | `string` | `metrics-server` | One of `metrics-server` (self-signed at runtime), `cert-manager`, `existingSecret` |
| `tls.clusterDomain` | `string` | `cluster.local` | Cluster domain used for the certificate SANs |
| `tls.certManager.addInjectorAnnotations` | `bool` | `true` | Add the `cert-manager.io/inject-ca-from` annotation to the APIService |
| `tls.certManager.existingIssuer` | | disabled | Reference an existing `Issuer`/`ClusterIssuer` instead of the generated self-signed one |
| `tls.certManager.duration` / `renewBefore` | `string` | unset | Certificate lifetime settings |
| `tls.certManager.annotations` / `labels` | `{[string]: string}` | unset | Extra Certificate/Issuer metadata |
| `tls.existingSecret.name` | `string` | unset | Name of an existing TLS secret to mount |

### Monitoring values

| Key | Type | Default | Description |
|---|---|---|---|
| `metrics.enabled` | `bool` | `false` | Allow unauthenticated access to `/metrics` |
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor (implies `metrics.enabled`) |
| `serviceMonitor.additionalLabels` | `{[string]: string}` | unset | Labels for Prometheus discovery |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | `1m` / `10s` | Scrape settings |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules |

### Addon-resizer values

| Key | Type | Default | Description |
|---|---|---|---|
| `addonResizer.enabled` | `bool` | `false` | Run the addon-resizer nanny sidecar that scales resources with cluster size |
| `addonResizer.image` | `timoniv1.#Image` | upstream release | Nanny container image |
| `addonResizer.resources` | `timoniv1.#ResourceRequirements` | `40m` / `25Mi` | Nanny resource requirements |
| `addonResizer.securityContext` | `corev1.#SecurityContext` | hardened | Nanny security context |
| `addonResizer.nanny` | | upstream defaults | Scaling parameters: `cpu`, `extraCpu`, `memory`, `extraMemory`, `minClusterSize`, `pollPeriod`, `threshold` |

### Deviations from the Helm chart

- `tls.type: helm` is not supported: it depends on Helm-only certificate
  generation and secret lookups. Use `metrics-server` (default),
  `cert-manager` or `existingSecret`.
- Secret lookups are not supported: with `tls.type: existingSecret`, provide
  the CA via `apiService.caBundle` or keep `insecureSkipTLSVerify`.
- `rbac.pspEnabled` is not supported: PodSecurityPolicy was removed in
  Kubernetes 1.25, the minimum version required by this module.
- `nameOverride`/`fullnameOverride` are covered by the Timoni instance name.

### Improvements over the Helm chart

- With `addonResizer.enabled`, the module stops managing the metrics-server
  container resources: the nanny owns and patches them at runtime, so
  upgrades no longer fight the resizer (the chart re-applies `resources`
  on every upgrade, which conflicts with the nanny-set values).
- With `hostNetwork` enabled and no explicit `updateStrategy`, the rollout
  strategy defaults to `maxUnavailable: 1`: the Kubernetes default of
  `maxUnavailable: 0` deadlocks host-network rollouts because the new pod
  cannot bind the host port while the old one holds it.

## Example: TLS with cert-manager

```cue
values: {
	tls: type: "cert-manager"
	apiService: insecureSkipTLSVerify: false
}
```

## Example: high availability

```cue
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
}
```
