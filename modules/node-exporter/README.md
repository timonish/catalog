# node-exporter

A [Timoni](https://timoni.sh) module for deploying [node-exporter](https://github.com/prometheus/node_exporter), the Prometheus exporter for hardware and OS metrics exposed by *NIX kernels.

## Version

<!-- versions:start -->
Latest module version is `1.12.1-0`, packaging the upstream release
[v1.12.1](https://github.com/prometheus/node_exporter/releases/tag/v1.12.1)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `quay.io/prometheus/node-exporter` | v1.12.1 | `sha256:1b4e4438faca4dd7e001dd445d161a4a2091b0fededa84093b3a8dfeae1f1be0` |
<!-- versions:end -->

## Prerequisites

- Kubernetes 1.25+
- [Timoni](https://timoni.sh/install/) 0.31+

## Install

The module deploys node-exporter as a DaemonSet that runs on every
schedulable node, tainted ones included, and exposes node-level
metrics (CPU, memory, disk, filesystem, network and so on) on port
`9100`.

To create an instance using the default values:

```shell
timoni -n monitoring apply node-exporter \
  oci://ghcr.io/timonish/modules/node-exporter
```

To change the [configuration](#configuration), create a `values.cue` file:

```cue
values: {
	extraArgs: [
		"--collector.textfile.directory=/run/prometheus",
		"--no-collector.wifi",
	]
}
```

And apply the values with:

```shell
timoni -n monitoring apply node-exporter \
  oci://ghcr.io/timonish/modules/node-exporter \
  --values ./values.cue
```

The metrics are exposed on the Service at
`node-exporter.monitoring.svc:9100/metrics`, annotated for Prometheus
annotation-based discovery. With a Prometheus Operator running in the
cluster, set `serviceMonitor: enabled: true` to scrape the instance
through a ServiceMonitor instead.

## Host access

By default the pods run in the host network and PID namespaces and
mount the node's `/proc`, `/sys` and root filesystems read-only —
this is what lets the exporter observe the node instead of its own
container. On clusters where the host network is restricted, set
`hostNetwork: false` to serve the metrics on the pod address instead;
individual collectors can be turned on and off through `extraArgs`
per the [node-exporter collector
documentation](https://github.com/prometheus/node_exporter#collectors).

Collectors that read root-only host files (e.g. the `rapl` power
metrics under `/sys/devices/virtual/powercap`) can be unlocked with an
init container that grants the exporter group (`65534`) read access;
the `proc` and `sys` host volumes are available to init containers by
name (and `root` while `hostRootFsMount` is enabled):

```cue
values: {
	initContainers: [{
		name:  "permission-fix"
		image: "busybox:1.37.0"
		securityContext: {
			runAsNonRoot: false
			runAsUser:    0
		}
		command: ["/bin/sh", "-c", "chown -R root:65534 /host/sys/devices/virtual/powercap && chmod -R g+r /host/sys/devices/virtual/powercap"]
		volumeMounts: [{
			name:      "sys"
			mountPath: "/host/sys"
		}]
	}]
}
```

## Scraping at scale

For very large clusters where thousands of exporter endpoints behind a
single Service become a bottleneck, the pods can be scraped directly
through a PodMonitor:

```cue
values: {
	service: enabled: false
	podMonitor: enabled: true
}
```

Note that the time series discovered through a PodMonitor lack the
`service` label, which may affect existing PromQL queries.

Nodes running outside the cluster can be scraped through the same
Service by listing their addresses in `endpoints`:

```cue
values: {
	endpoints: ["192.168.1.10", "192.168.1.11"]
}
```

## Bundle

An example [bundle](https://timoni.sh/bundle/) for deploying
node-exporter along with the Prometheus Operator, registering the
metrics endpoint for scraping through a ServiceMonitor:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "monitoring-stack"
	instances: {
		"prometheus-operator": {
			module: url: "oci://ghcr.io/timonish/modules/prometheus-operator"
			namespace: "monitoring"
		}
		"node-exporter": {
			module: url: "oci://ghcr.io/timonish/modules/node-exporter"
			namespace: "monitoring"
			values: {
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
| `image.repository` | `string` | `quay.io/prometheus/node-exporter` | Container image repository |
| `image.tag` | `string` | `<latest version>` | Container image tag |
| `image.digest` | `string` | `<latest digest>` | Container image digest, takes precedence over `tag` when specified |
| `image.pullPolicy` | `string` | `IfNotPresent` | Container image pull policy |
| `imagePullSecrets` | `[...ObjectReference]` | `[]` | References to secrets for pulling images from private registries |
| `metadata.labels` | `{[string]: string}` | `{}` | Labels added to all resources |
| `metadata.annotations` | `{[string]: string}` | `{}` | Annotations added to all resources |
| `commonLabels` | `{[string]: string}` | `{}` | Extra labels added to all resources |
| `extraArgs` | `[...string]` | `[]` | Extra command line arguments appended after the generated ones, e.g. collector toggles |
| `env` | `[...EnvVar]` | `[]` | Environment variables for the container |
| `extraVolumes` | `[...Volume]` | `[]` | Extra volumes added to the pod |
| `extraVolumeMounts` | `[...VolumeMount]` | `[]` | Extra volume mounts for the container |
| `extraContainers` | `[...Container]` | `[]` | Extra containers added to the pod, e.g. sidecars writing textfile collector metrics |
| `initContainers` | `[...Container]` | `[]` | Init containers added to the pod; the `proc` and `sys` host volumes (and `root` while `hostRootFsMount` is enabled) can be mounted by name |
| `resources` | `ResourceRequirements` | unset | Container resource requirements |
| `securityContext` | `SecurityContext` | hardened | Container security context |
| `livenessProbe` | `Probe` | `/` on the metrics port | Liveness probe of the container |
| `readinessProbe` | `Probe` | `/` on the metrics port | Readiness probe of the container |
| `terminationMessagePath` | `string` | unset | Container termination message path |
| `terminationMessagePolicy` | `string` | unset | `File` or `FallbackToLogsOnError` |
| `serviceAccount.create` | `bool` | `true` | Create the ServiceAccount, or reference an existing one via `name` |
| `serviceAccount.name` | `string` | instance name (`default` when `create: false`) | Name of the ServiceAccount the pods run under |
| `serviceAccount.labels` | `{[string]: string}` | `{}` | Labels added to the ServiceAccount |
| `serviceAccount.annotations` | `{[string]: string}` | `{}` | Annotations added to the ServiceAccount |
| `serviceAccount.imagePullSecrets` | `[...ObjectReference]` | `[]` | References to secrets set on the ServiceAccount for pulling images |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount the token by default in pods using this ServiceAccount |

### Host access values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `hostNetwork` | `bool` | `true` | Run the pods in the host network namespace, exposing the metrics on the node address |
| `hostPID` | `bool` | `true` | Share the host process ID namespace, required by the process related collectors |
| `hostIPC` | `bool` | `false` | Share the host IPC namespace |
| `hostUsers` | `bool` | unset | Run the pods in the host user namespace |
| `hostRootFsMount.enabled` | `bool` | `true` | Mount the node root filesystem at `/host/root` read-only, enabling the filesystem and udev collectors |
| `hostRootFsMount.mountPropagation` | `string` | `HostToContainer` | Mount propagation of the root filesystem mount |
| `hostProcFsMount.mountPropagation` | `string` | unset | Mount propagation of the `/host/proc` mount |
| `hostSysFsMount.mountPropagation` | `string` | unset | Mount propagation of the `/host/sys` mount |
| `listenOnAllInterfaces` | `bool` | `true` | Listen on all interfaces; when `false` the exporter binds to the node address only |

### Pod scheduling values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `podLabels` | `{[string]: string}` | `{}` | Labels added to the pods |
| `podAnnotations` | `{[string]: string}` | safe-to-evict | Annotations added to the pods; the default marks them safe to evict for the cluster autoscaler |
| `securityContextPreset` | `hardened` or `platform` | `hardened` | Pod identity defaults: `hardened` pins UID/GID `65534`, `platform` leaves the identity to the cluster (e.g. OpenShift SCCs) |
| `podSecurityContext` | `PodSecurityContext` | per `securityContextPreset` | Pod security context |
| `nodeSelector` | `{[string]: string}` | `kubernetes.io/os: linux` | Node selector for pod scheduling |
| `tolerations` | `[...Toleration]` | tolerate `NoSchedule` | Pod tolerations; by default the exporter runs on tainted nodes too |
| `affinity` | `Affinity` | exclude Fargate and virtual kubelets | Pod affinity rules; a user-supplied value replaces the default |
| `topologySpreadConstraints` | `[...TopologySpreadConstraint]` | `[]` | Pod topology spread constraints |
| `dnsConfig` | `PodDNSConfig` | `{}` | Pod DNS configuration |
| `dnsPolicy` | `string` | `ClusterFirstWithHostNet` | Pod DNS policy, defaults to `ClusterFirst` without `hostNetwork` |
| `priorityClassName` | `string` | unset | Priority class of the pods |
| `schedulerName` | `string` | unset | Alternate scheduler |
| `terminationGracePeriodSeconds` | `int` | `30` | Pod termination grace period |
| `automountServiceAccountToken` | `bool` | `false` | Mount the service account token into the pod; node-exporter does not use the Kubernetes API |
| `strategy` | `DaemonSetUpdateStrategy` | `RollingUpdate` | DaemonSet update strategy |
| `revisionHistoryLimit` | `int` | `10` | Number of old ControllerRevisions to retain |
| `daemonsetLabels` | `{[string]: string}` | `{}` | Labels added to the DaemonSet |
| `daemonsetAnnotations` | `{[string]: string}` | `{}` | Annotations added to the DaemonSet |

### Service values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `service.enabled` | `bool` | `true` | Create the Service; can be disabled for setups scraping the pods through the `podMonitor` |
| `service.type` | `string` | `ClusterIP` | Service type: `ClusterIP`, `NodePort` or `LoadBalancer` |
| `service.port` | `int` | `9100` | Port of the metrics endpoint on the Service |
| `service.targetPort` | `int` | `service.port` | Port the exporter listens on; with `hostNetwork` this is the port claimed on every node |
| `service.portName` | `string` | `metrics` | Name of the metrics port on the Service and the container |
| `service.clusterIP` | `string` | unset | IP address with `type: ClusterIP` |
| `service.annotations` | `{[string]: string}` | `{}` | Annotations added to the Service |
| `service.labels` | `{[string]: string}` | `{}` | Labels added to the Service |
| `service.prometheusScrape` | `bool` | `true` | Annotate the Service with `prometheus.io/scrape` for annotation-based discovery |
| `service.ipFamilies` | `[...string]` | `[]` | IP families: `IPv4` and/or `IPv6` |
| `service.ipFamilyPolicy` | `string` | unset | `SingleStack`, `PreferDualStack` or `RequireDualStack` |
| `service.externalIPs` | `[...string]` | `[]` | External IPs accepted by the Service |
| `service.nodePort` | `int` | `0` | Node port of the metrics endpoint with `type: NodePort`; zero assigns one |
| `service.loadBalancerIP` | `string` | unset | Load balancer IP with `type: LoadBalancer` |
| `service.loadBalancerClass` | `string` | unset | Load balancer class with `type: LoadBalancer` |
| `service.loadBalancerSourceRanges` | `[...string]` | `[]` | CIDRs allowed to reach the load balancer |
| `service.externalTrafficPolicy` | `string` | unset | External traffic policy for `NodePort` and `LoadBalancer` |
| `service.internalTrafficPolicy` | `string` | unset | `Cluster` or `Local` in-cluster traffic routing |
| `endpoints` | `[...string]` | `[]` | Addresses of node exporters running outside the cluster, added to the Service as static Endpoints on port `9100` |
| `networkPolicy.enabled` | `bool` | `false` | Create ingress and egress NetworkPolicies for the pods |
| `networkPolicy.ingress` / `egress` | `netv1` rules | metrics port in; all egress denied | The policy rules |

### Monitoring values

| Key | Type | Default | Description |
|---|---|---|---|
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor scraping the metrics endpoint, in the instance namespace |
| `serviceMonitor.additionalLabels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata, e.g. labels for Prometheus discovery |
| `serviceMonitor.jobLabel` | `string` | `app.kubernetes.io/name` | Service label used as the Prometheus job name |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | unset | Scrape cadence; defaults to the Prometheus settings |
| `serviceMonitor.honorLabels` | `bool` | `false` | Keep scraped label values on collision |
| `serviceMonitor.enableHttp2` | `bool` | unset | Enable HTTP2 for scraping |
| `serviceMonitor.scheme` / `tlsConfig` / `bearerTokenFile` / `bearerTokenSecret` / `proxyUrl` | | unset | Scrape scheme, TLS, authentication and proxy settings |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules for the samples and the targets |
| `serviceMonitor.sampleLimit` / `targetLimit` / `labelLimit` / `labelNameLengthLimit` / `labelValueLengthLimit` | `int` | unset | Scrape limits |
| `serviceMonitor.targetLabels` / `podTargetLabels` | `[...string]` | unset | Service/pod labels copied onto the metrics |
| `serviceMonitor.selectorOverride` | `{[string]: string}` | instance selector | Override the label selector matching the Service |
| `serviceMonitor.attachMetadata.node` | `bool` | unset | Attach node metadata to the discovered targets (Prometheus 2.35+) |
| `serviceMonitor.basicAuth` | `{...}` | unset | Basic authentication credentials of the scrape requests |
| `podMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator PodMonitor scraping the pods directly, for very large clusters |
| `podMonitor.path` | `string` | `/metrics` | The HTTP path to scrape metrics from |
| `podMonitor.honorTimestamps` | `bool` | `true` | Keep the timestamps present in the scraped data |
| `podMonitor.filterRunning` | `bool` | `true` | Drop pods not in the Running phase |
| `podMonitor.followRedirects` | `bool` | `false` | Follow HTTP 3xx redirects |
| `podMonitor.basicAuth` | `{...}` | unset | Basic authentication credentials of the scrape requests |
| `podMonitor.params` | `{[string]: [...string]}` | unset | Optional HTTP URL parameters |
| `podMonitor.oauth2` / `authorization` | `{...}` | unset | OAuth2 and Authorization header settings of the scrape requests |
| `podMonitor.attachMetadata.node` / `selectorOverride` | | unset | Node metadata attachment and pod selector override |
| `podMonitor.*` | | | The shared metadata, scrape and limit settings shown for `serviceMonitor` |

### Vertical Pod Autoscaler values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `verticalPodAutoscaler.enabled` | `bool` | `false` | Create a VerticalPodAutoscaler for the DaemonSet; requires the autoscaling.k8s.io CRDs |
| `verticalPodAutoscaler.recommenders` | `[...{name}]` | `[]` | The recommender generating the recommendations; empty selects the default one |
| `verticalPodAutoscaler.controlledResources` | `[...string]` | `[]` | The resources the autoscaler controls; empty means CPU and memory |
| `verticalPodAutoscaler.controlledValues` | `string` | unset | `RequestsOnly` or `RequestsAndLimits` |
| `verticalPodAutoscaler.maxAllowed` / `minAllowed` | `{cpu, memory}` | unset | The maximum and minimum resources allowed per pod |
| `verticalPodAutoscaler.updatePolicy` | `{minReplicas, updateMode}` | unset | How the recommendations are applied to the pods |
