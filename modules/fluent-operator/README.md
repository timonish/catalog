# fluent-operator

A [Timoni](https://timoni.sh) module for deploying [Fluent Operator](https://github.com/fluent/fluent-operator), the operator that manages Fluent Bit and Fluentd logging pipelines through Kubernetes custom resources.

## Version

<!-- versions:start -->
Latest module version is `3.9.0-0`, packaging the upstream release
[v3.9.0](https://github.com/fluent/fluent-operator/releases/tag/v3.9.0)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `ghcr.io/fluent/fluent-operator/fluent-operator` | v3.9.0 | `sha256:705375468232d8d39d47c60d55296b1587501fc1cb4f2f313e7e7b4ad82cc3ed` |
<!-- versions:end -->

## Prerequisites

- Kubernetes 1.25+
- [Timoni](https://timoni.sh/install/) 0.31+

## Install

The module installs the `fluentbit.fluent.io` and `fluentd.fluent.io`
custom resource definitions and the operator that reconciles them.
Logging agents and aggregators are not part of the module: after
installing it, create `FluentBit` or `Fluentd` custom resources
together with their pipeline resources (inputs, filters, parsers and
outputs) and the operator builds the workloads from them; see the
[Fluent Operator documentation](https://github.com/fluent/fluent-operator/tree/master/docs)
for the custom resource reference.

To create an instance using the default values:

```shell
timoni -n fluent-system apply fluent-operator \
  oci://ghcr.io/timonish/modules/fluent-operator
```

To change the [configuration](#configuration), create a `values.cue` file:

```cue
values: {
	watchNamespaces: ["fluent-system", "apps"]
	replicas: 2
}
```

And apply the values with:

```shell
timoni -n fluent-system apply fluent-operator \
  oci://ghcr.io/timonish/modules/fluent-operator \
  --values ./values.cue
```

The operator derives the node log paths from the cluster's container
runtime, `containerd` by default; on CRI-O or Docker nodes set
`containerRuntime: "crio"` or `containerRuntime: "docker"`.

### Uninstall

**Warning**: uninstalling the instance deletes the custom resource
definitions and with them **every** `fluentbit.fluent.io` and
`fluentd.fluent.io` custom resource in the cluster (Fluent Bit agents,
pipeline configurations, and so on). To preserve them, apply
`crds: keep: true` before uninstalling:

```cue
values: {
	crds: keep: true
}
```

With `keep` enabled, uninstalling removes the operator but leaves the
CRDs and all custom resources in place:

```shell
timoni -n fluent-system delete fluent-operator
```

On clusters where the CRD lifecycle is managed out of band, the module
can skip installing them altogether with `crds: install: false`.

## Bundle

An example [bundle](https://timoni.sh/bundle/) for deploying the
operator in high-availability mode along with Prometheus Operator
(instances are applied in definition order, so the ServiceMonitor
custom resource definition is available right away):

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "logging-stack"
	instances: {
		"prometheus-operator": {
			module: url: "oci://ghcr.io/timonish/modules/prometheus-operator"
			namespace: "monitoring"
		}
		"fluent-operator": {
			module: url: "oci://ghcr.io/timonish/modules/fluent-operator"
			namespace: "fluent-system"
			values: {
				replicas: 2
				serviceMonitor: enabled: true
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
|-----|------|---------|-------------|
| `crds.install` | `bool` | `true` | Install the `fluentbit.fluent.io` and `fluentd.fluent.io` custom resource definitions |
| `crds.keep` | `bool` | `false` | Keep the CRDs and all custom resources when the instance is uninstalled |
| `image.repository` | `string` | `ghcr.io/fluent/fluent-operator/fluent-operator` | Container image repository |
| `image.tag` | `string` | `<latest version>` | Container image tag |
| `image.digest` | `string` | `""` | Container image digest, takes precedence over `tag` when specified |
| `image.pullPolicy` | `string` | `IfNotPresent` | Container image pull policy |
| `imagePullSecrets` | `[...ObjectReference]` | `[]` | References to secrets for pulling images from private registries |
| `metadata.labels` | `{[string]: string}` | `{}` | Labels added to all resources |
| `metadata.annotations` | `{[string]: string}` | `{}` | Annotations added to all resources |
| `commonLabels` | `{[string]: string}` | `{}` | Extra labels added to all resources |
| `env` | `[...EnvVar]` | `[]` | Environment variables for the operator container, appended after the generated ones |
| `extraArgs` | `[...string]` | `[]` | Extra command line arguments appended after the generated ones |
| `extraVolumes` | `[...Volume]` | `[]` | Extra volumes added to the pod |
| `extraVolumeMounts` | `[...VolumeMount]` | `[]` | Extra volume mounts for the operator container |
| `resources` | `ResourceRequirements` | `100m/20Mi (requests), 100m/60Mi (limits)` | Container resource requirements |
| `securityContext` | `SecurityContext` | hardened | Container security context |
| `livenessProbe` | `Probe` | `/healthz` on port `8081` | Liveness probe of the operator container |
| `readinessProbe` | `Probe` | `/readyz` on port `8081` | Readiness probe of the operator container |
| `rbac.create` | `bool` | `true` | Create the ClusterRole and ClusterRoleBinding |
| `rbac.extraRules` | `[...PolicyRule]` | `[]` | Extra rules added to the operator ClusterRole, e.g. permissions the managed Fluent Bit agents need beyond the defaults |
| `serviceAccount.create` | `bool` | `true` | Create the ServiceAccount, or reference an existing one via `name` |
| `serviceAccount.name` | `string` | instance name | Name of the ServiceAccount the operator runs under |
| `serviceAccount.labels` | `{[string]: string}` | `{}` | Labels added to the ServiceAccount |
| `serviceAccount.annotations` | `{[string]: string}` | `{}` | Annotations added to the ServiceAccount |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount the token by default in pods using this ServiceAccount (the operator pod mounts it through the pod-level setting) |

### Operator values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `containerRuntime` | `string` | `containerd` | Container runtime of the cluster nodes (`containerd`, `crio` or `docker`), determines the container log path configured for the Fluent Bit agents |
| `replicas` | `int` | `1` | Number of operator replicas |
| `leaderElection.enabled` | `bool` | `true` when `replicas` > 1 | Leader election for the controller manager |
| `disableComponentControllers` | `string` | `""` | Disable the `fluent-bit` or `fluentd` component controller; empty runs both |
| `watchNamespaces` | `[...string]` | `[]` | Namespaces watched for namespaced custom resources; empty means all |

### Pod scheduling values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `podLabels` | `{[string]: string}` | `{}` | Labels added to the pods |
| `podAnnotations` | `{[string]: string}` | `{}` | Annotations added to the pods |
| `securityContextPreset` | `hardened` or `platform` | `hardened` | Pod identity defaults: `hardened` pins UID/GID `65532`, `platform` leaves the identity to the cluster (e.g. OpenShift SCCs) |
| `podSecurityContext` | `PodSecurityContext` | per `securityContextPreset` | Pod security context |
| `nodeSelector` | `{[string]: string}` | `kubernetes.io/os: linux` | Node selector for pod scheduling |
| `tolerations` | `[...Toleration]` | `[]` | Pod tolerations |
| `affinity.podAntiAffinity` | `soft`, `hard`, `none` or raw rules | `soft` | Spread the replicas across nodes; raw rules replace the preset |
| `affinity.nodeAffinity` / `affinity.podAffinity` | raw rules | unset | Node and pod affinity rules |
| `topologySpreadConstraints` | `[...TopologySpreadConstraint]` | `[]` | Pod topology spread constraints |
| `dnsConfig` | `PodDNSConfig` | `{}` | Pod DNS configuration |
| `dnsPolicy` | `string` | `ClusterFirst` | Pod DNS policy |
| `priorityClassName` | `string` | `""` | Priority class of the pods |
| `schedulerName` | `string` | unset | Alternate scheduler |
| `terminationGracePeriodSeconds` | `int` | `30` | Pod termination grace period |
| `automountServiceAccountToken` | `bool` | `true` | Mount the service account token into the pod |
| `strategy` | `DeploymentStrategy` | `RollingUpdate` | Deployment update strategy |
| `revisionHistoryLimit` | `int` | `10` | Number of old ReplicaSets to retain |
| `deploymentAnnotations` | `{[string]: string}` | `{}` | Annotations added to the Deployment |
| `podDisruptionBudget.enabled` | `bool` | `true` when `replicas` > 1 | Create a PodDisruptionBudget for the operator pods |
| `podDisruptionBudget.minAvailable` | `int or %` | `1` | Minimum available pods, mutually exclusive with `maxUnavailable` |
| `podDisruptionBudget.maxUnavailable` | `int or %` | unset | Maximum unavailable pods |
| `podDisruptionBudget.unhealthyPodEvictionPolicy` | `string` | unset | `IfHealthyBudget` or `AlwaysAllow` (Kubernetes 1.27+) |

### Service values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `service.enabled` | `bool` | `true` | Create the Service for the operator metrics endpoint |
| `service.type` | `string` | `ClusterIP` | Service type: `ClusterIP`, `NodePort` or `LoadBalancer` |
| `service.port` | `int` | `8080` | Service port; the operator serves its metrics on this port |
| `service.portName` | `string` | `metrics` | Name of the Service and container port |
| `service.clusterIP` | `string` | `""` | Static cluster IP, or `None` for a headless Service |
| `service.annotations` | `{[string]: string}` | `{}` | Annotations added to the Service |
| `service.labels` | `{[string]: string}` | `{}` | Labels added to the Service |
| `service.ipFamilies` | `[...string]` | `[]` | IP families: `IPv4` and/or `IPv6` |
| `service.ipFamilyPolicy` | `string` | `""` | `SingleStack`, `PreferDualStack` or `RequireDualStack` |
| `service.externalIPs` | `[...string]` | `[]` | External IPs accepted by the Service |
| `service.nodePort` | `int` | `0` (auto) | Node port with `type: NodePort` |
| `service.loadBalancerIP` | `string` | `""` | Load balancer IP with `type: LoadBalancer` |
| `service.loadBalancerClass` | `string` | unset | Load balancer implementation class with `type: LoadBalancer` |
| `service.loadBalancerSourceRanges` | `[...string]` | `[]` | CIDRs allowed to reach the load balancer |
| `service.externalTrafficPolicy` | `string` | `Cluster` | External traffic policy for `NodePort` and `LoadBalancer` |

### Monitoring values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor scraping the operator metrics, in the instance namespace |
| `serviceMonitor.additionalLabels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata, e.g. labels for Prometheus discovery |
| `serviceMonitor.jobLabel` | `string` | `app.kubernetes.io/name` | Service label used as the Prometheus job name |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | unset | Scrape cadence; defaults to the Prometheus settings |
| `serviceMonitor.honorLabels` | `bool` | `false` | Keep scraped label values on collision |
| `serviceMonitor.enableHttp2` | `bool` | unset | Enable HTTP2 for scraping |
| `serviceMonitor.scheme` / `tlsConfig` / `bearerTokenFile` / `bearerTokenSecret` / `proxyUrl` | | unset | Scrape scheme, TLS, authentication and proxy settings |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules for the samples and the targets |
| `serviceMonitor.sampleLimit` / `targetLimit` / `labelLimit` / `labelNameLengthLimit` / `labelValueLengthLimit` | `int` | unset | Scrape limits |
| `serviceMonitor.targetLabels` / `podTargetLabels` | `[...string]` | unset | Service/pod labels copied onto the metrics |
