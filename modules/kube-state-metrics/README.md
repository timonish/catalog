# kube-state-metrics

A [Timoni](https://timoni.sh) module for deploying [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics), an agent that generates Prometheus metrics about the state of Kubernetes objects.

## Version

<!-- versions:start -->
Latest module version is `2.19.1-1`, packaging the upstream release
[v2.19.1](https://github.com/kubernetes/kube-state-metrics/releases/tag/v2.19.1)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `registry.k8s.io/kube-state-metrics/kube-state-metrics` | v2.19.1 | `sha256:85108987d044b18a098126732f98602df408888c0f7d456241f5abefb9744bc1` |
<!-- versions:end -->

## Prerequisites

- Kubernetes 1.25+
- [Timoni](https://timoni.sh/install/) 0.31+

## Install

The module deploys kube-state-metrics, a service that listens to the
Kubernetes API and exposes Prometheus metrics about the state of the
objects in the cluster (deployment status, pod phases, node capacity,
job completion and so on).

To create an instance using the default values:

```shell
timoni -n monitoring apply kube-state-metrics \
  oci://ghcr.io/timonish/modules/kube-state-metrics
```

To change the [configuration](#configuration), create a `values.cue` file:

```cue
values: {
	collectors: ["deployments", "nodes", "pods"]
	metricLabelsAllowlist: ["pods=[app.kubernetes.io/name]"]
}
```

And apply the values with:

```shell
timoni -n monitoring apply kube-state-metrics \
  oci://ghcr.io/timonish/modules/kube-state-metrics \
  --values ./values.cue
```

The metrics are exposed on the headless Service at
`kube-state-metrics.monitoring.svc:8080/metrics`, annotated for
Prometheus annotation-based discovery. With a Prometheus Operator
running in the cluster, set `serviceMonitor: enabled: true` to scrape
the instance through a ServiceMonitor instead.

## Custom resource metrics

Besides the built-in collectors, kube-state-metrics can expose metrics
from the fields of custom resources. The configuration follows the
upstream
[CustomResourceStateMetrics](https://github.com/kubernetes/kube-state-metrics/blob/main/docs/metrics/extend/customresourcestate-metrics.md)
format and is rendered into an immutable ConfigMap whose name carries
the config hash, so configuration changes roll the pods automatically.

The module grants kube-state-metrics access to read the custom
resource definitions, while the access to the custom resources
themselves must be granted with `rbac: extraRules:`. For example, to
expose the readiness of cert-manager
certificates as a `kube_customresource_certificate_status` gauge:

```cue
values: {
	customResourceState: {
		enabled: true
		config: spec: resources: [{
			groupVersionKind: {
				group:   "cert-manager.io"
				version: "v1"
				kind:    "Certificate"
			}
			metricNamePrefix: "kube_customresource"
			labelsFromPath: {
				name: ["metadata", "name"]
				exported_namespace: ["metadata", "namespace"]
			}
			metrics: [{
				name: "certificate_status"
				help: "Certificate Ready condition"
				each: {
					type: "Gauge"
					gauge: {
						path: ["status", "conditions"]
						labelsFromPath: condition: ["type"]
						valueFrom: ["status"]
					}
				}
			}]
		}]
	}
	rbac: extraRules: [{
		apiGroups: ["cert-manager.io"]
		resources: ["certificates"]
		verbs: ["list", "watch"]
	}]
}
```

To expose only the custom resource metrics and disable all built-in
collectors, set `customResourceState: only: true`.

## Metrics endpoint protection

By default the metrics endpoints are served over plain HTTP without
authentication. To require Kubernetes API authentication and
authorization on them, enable the auth filter:

```cue
values: {
	authFilter: enabled: true
}
```

With the filter enabled, scrapers must send a service account token
and be authorized (via TokenReview and SubjectAccessReview) to access
the endpoints; the RBAC permissions the filter needs are added to the
module role automatically. The health probes remain unauthenticated.

## Sharding

For large clusters where a single instance cannot hold all objects in
memory, the module can shard the metrics horizontally across multiple
pods:

```cue
values: {
	autosharding: enabled: true
	replicas: 3
}
```

With autosharding enabled the module deploys a StatefulSet instead of
a Deployment: each pod derives its shard number from its ordinal and
exposes only its share of the metrics. All shards must be scraped
individually through the headless Service — with
`serviceMonitor: enabled: true` this happens automatically.

## Bundle

An example [bundle](https://timoni.sh/bundle/) for deploying
kube-state-metrics along with the Prometheus Operator, scraped through
a ServiceMonitor and monitoring itself over the telemetry endpoint:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "monitoring-stack"
	instances: {
		"prometheus-operator": {
			module: url: "oci://ghcr.io/timonish/modules/prometheus-operator"
			namespace: "monitoring"
		}
		"kube-state-metrics": {
			module: url: "oci://ghcr.io/timonish/modules/kube-state-metrics"
			namespace: "monitoring"
			values: {
				selfMonitor: enabled:    true
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
| `image: repository:` | `string` | `registry.k8s.io/kube-state-metrics/kube-state-metrics` | Container image repository |
| `image: tag:` | `string` | `<latest version>` | Container image tag |
| `image: digest:` | `string` | `""` | Container image digest, takes precedence over `tag` when specified |
| `image: pullPolicy:` | `string` | `IfNotPresent` | Container image pull policy |
| `imagePullSecrets:` | `[...ObjectReference]` | `[]` | References to secrets for pulling images from private registries |
| `metadata: labels:` | `{[string]: string}` | `{}` | Labels added to all resources |
| `metadata: annotations:` | `{[string]: string}` | `{}` | Annotations added to all resources |
| `commonLabels:` | `{[string]: string}` | `{}` | Extra labels added to all resources |
| `replicas:` | `int` | `1` | Number of pods; with `autosharding` each pod exposes one shard of the metrics |
| `autosharding: enabled:` | `bool` | `false` | Deploy a StatefulSet whose pods shard the metrics by ordinal |
| `env:` | `[...EnvVar]` | `[]` | Environment variables for the container |
| `extraArgs:` | `[...string]` | `[]` | Extra command line arguments appended after the generated ones |
| `extraVolumes:` | `[...Volume]` | `[]` | Extra volumes added to the pod |
| `extraVolumeMounts:` | `[...VolumeMount]` | `[]` | Extra volume mounts for the container |
| `extraContainers:` | `[...Container]` | `[]` | Extra containers added to the pod |
| `initContainers:` | `[...Container]` | `[]` | Init containers added to the pod |
| `resources:` | `ResourceRequirements` | `10m/190Mi (requests), 100m/250Mi (limits)` | Container resource requirements |
| `securityContext:` | `SecurityContext` | hardened | Container security context |
| `livenessProbe:` | `Probe` | `/livez` on the metrics port | Liveness probe of the container |
| `readinessProbe:` | `Probe` | `/readyz` on the telemetry port | Readiness probe of the container |
| `startupProbe:` | `Probe` | unset | Startup probe (optional), `startupProbe: {}` enables it with `/healthz` defaults |
| `kubeconfigSecret: name:` | `string` | unset | Existing Secret with a `config` key holding a kubeconfig, for collecting another cluster |
| `serviceAccount: create:` | `bool` | `true` | Create the ServiceAccount, or reference an existing one via `name` |
| `serviceAccount: name:` | `string` | instance name (`default` when `create: false`) | Name of the ServiceAccount the pods run under |
| `serviceAccount: annotations:` | `{[string]: string}` | `{}` | Annotations added to the ServiceAccount |
| `serviceAccount: imagePullSecrets:` | `[...ObjectReference]` | `[]` | References to secrets set on the ServiceAccount for pulling images |
| `serviceAccount: automountServiceAccountToken:` | `bool` | `false` | Mount the token by default in pods using this ServiceAccount (the kube-state-metrics pod mounts it through the pod-level setting) |

### Collection values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `collectors:` | `[...string]` | 28 resource kinds | Resource kinds to collect metrics for (35 valid names); the list is set wholesale and an empty list falls back to the built-in defaults |
| `metricAllowlist:` | `[...string]` | `[]` | Metrics to expose, as names and/or regex patterns; mutually exclusive with `metricDenylist` |
| `metricDenylist:` | `[...string]` | `[]` | Metrics not to expose, as names and/or regex patterns |
| `metricLabelsAllowlist:` | `[...string]` | `[]` | Kubernetes label keys used in the labels metrics, e.g. `pods=[app.kubernetes.io/name]` |
| `metricAnnotationsAllowList:` | `[...string]` | `[]` | Kubernetes annotation keys used in the annotations metrics |
| `namespaces:` | `[...string]` | `[]` | Namespaces to collect resources from; empty means all |
| `namespacesDenylist:` | `[...string]` | `[]` | Namespaces excluded from collecting |
| `authFilter: enabled:` | `bool` | `false` | Require Kubernetes API authentication and authorization on the metrics endpoints |
| `customResourceState: enabled:` | `bool` | `false` | Expose metrics from custom resource fields per the config |
| `customResourceState: only:` | `bool` | `false` | Expose only the custom resource metrics, disabling the built-in collectors |
| `customResourceState: config:` | `CustomResourceStateMetrics` | `{}` | The custom resource metrics definitions (`spec: resources:`) |
| `customResourceState: existingConfigMap: name:` | `string` | unset | Use an externally managed ConfigMap holding the configuration instead of generating one |
| `customResourceState: existingConfigMap: key:` | `string` | `config.yaml` | The key of the externally managed ConfigMap holding the configuration |
| `selfMonitor: enabled:` | `bool` | `false` | Expose the telemetry (self-metrics) endpoint on the Service |
| `selfMonitor: telemetryHost:` | `string` | `""` | Telemetry listen host |
| `selfMonitor: telemetryPort:` | `int` | `8081` | Telemetry listen port |
| `rbac: create:` | `bool` | `true` | Create the role and binding granting access to the collected resources |
| `rbac: useClusterRole:` | `bool` | `true` | Use a ClusterRole; when `false`, namespaced Roles are created in each of the `namespaces` (plus a supplemental ClusterRole for the `authFilter` and `customResourceState` permissions) |
| `rbac: extraRules:` | `[...PolicyRule]` | `[]` | Extra policy rules, e.g. for the `customResourceState` resources |

### Pod scheduling values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `podLabels:` | `{[string]: string}` | `{}` | Labels added to the pods |
| `podAnnotations:` | `{[string]: string}` | `{}` | Annotations added to the pods |
| `securityProfile:` | `hardened` or `platform` | `hardened` | Pod identity defaults: `hardened` pins UID/GID `65534`, `platform` leaves the identity to the cluster (e.g. OpenShift SCCs) |
| `podSecurityContext:` | `PodSecurityContext` | per `securityProfile` | Pod security context |
| `nodeSelector:` | `{[string]: string}` | `kubernetes.io/os: linux` | Node selector for pod scheduling |
| `tolerations:` | `[...Toleration]` | `[]` | Pod tolerations |
| `affinity:` | `Affinity` | `{}` | Pod affinity rules |
| `topologySpreadConstraints:` | `[...TopologySpreadConstraint]` | `[]` | Pod topology spread constraints |
| `dnsConfig:` | `PodDNSConfig` | `{}` | Pod DNS configuration |
| `dnsPolicy:` | `string` | `ClusterFirst` | Pod DNS policy, defaults to `ClusterFirstWithHostNet` with `hostNetwork` |
| `hostNetwork:` | `bool` | `false` | Run the pods in the host network namespace |
| `hostUsers:` | `bool` | unset | Run the pods in the host user namespace |
| `priorityClassName:` | `string` | unset | Priority class of the pods |
| `terminationGracePeriodSeconds:` | `int` | `30` | Pod termination grace period |
| `automountServiceAccountToken:` | `bool` | `true` | Mount the service account token into the pod |
| `strategy:` | `DeploymentStrategy` | `RollingUpdate` | Deployment update strategy (Deployment mode only) |
| `revisionHistoryLimit:` | `int` | `10` | Number of old ReplicaSets or StatefulSet revisions to retain |
| `workloadLabels:` | `{[string]: string}` | `{}` | Labels added to the Deployment or StatefulSet |
| `workloadAnnotations:` | `{[string]: string}` | `{}` | Annotations added to the Deployment or StatefulSet |
| `podDisruptionBudget: enabled:` | `bool` | `false` | Create a PodDisruptionBudget for the pods |
| `podDisruptionBudget: minAvailable:` | `int or %` | unset | Minimum available pods, mutually exclusive with `maxUnavailable` |
| `podDisruptionBudget: maxUnavailable:` | `int or %` | unset | Maximum unavailable pods |
| `podDisruptionBudget: unhealthyPodEvictionPolicy:` | `string` | unset | `IfHealthyBudget` or `AlwaysAllow` (Kubernetes 1.27+) |

### Service values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `service: type:` | `string` | `ClusterIP` | Service type: `ClusterIP`, `NodePort` or `LoadBalancer` |
| `service: port:` | `int` | `8080` | Port of the metrics endpoint, also the container listen port |
| `service: clusterIP:` | `string` | `None` | The Service is headless by default; set to an empty string for an auto-assigned virtual IP |
| `service: annotations:` | `{[string]: string}` | `{}` | Annotations added to the Service |
| `service: labels:` | `{[string]: string}` | `{}` | Labels added to the Service |
| `service: prometheusScrape:` | `bool` | `true` | Annotate the Service with `prometheus.io/scrape` for annotation-based discovery |
| `service: ipFamilies:` | `[...string]` | `[]` | IP families: `IPv4` and/or `IPv6` |
| `service: ipFamilyPolicy:` | `string` | unset | `SingleStack`, `PreferDualStack` or `RequireDualStack` |
| `service: externalIPs:` | `[...string]` | `[]` | External IPs accepted by the Service |
| `service: nodePort:` | `int` | `0` | Node port of the metrics endpoint with `type: NodePort`; zero assigns one |
| `service: telemetryNodePort:` | `int` | `0` | Node port of the telemetry endpoint with `type: NodePort` |
| `service: loadBalancerIP:` | `string` | unset | Load balancer IP with `type: LoadBalancer` |
| `service: loadBalancerSourceRanges:` | `[...string]` | `[]` | CIDRs allowed to reach the load balancer |
| `service: externalTrafficPolicy:` | `string` | unset | External traffic policy for `NodePort` and `LoadBalancer` |

### Monitoring and network values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `serviceMonitor: enabled:` | `bool` | `false` | Create a ServiceMonitor scraping the metrics endpoint (and the telemetry endpoint with `selfMonitor`) |
| `serviceMonitor: additionalLabels:` | `{[string]: string}` | `{}` | Labels added to the ServiceMonitor, e.g. for Prometheus selectors |
| `serviceMonitor: annotations:` | `{[string]: string}` | `{}` | Annotations added to the ServiceMonitor |
| `serviceMonitor: namespace:` | `string` | instance namespace | The namespace the ServiceMonitor is created in |
| `serviceMonitor: selectorOverride:` | `{[string]: string}` | instance selector | Override the label selector matching the Service |
| `serviceMonitor: jobLabel:` | `string` | `app.kubernetes.io/name` | Label used as the Prometheus job name |
| `serviceMonitor: targetLabels:` | `[...string]` | `[]` | Service labels transferred to the metrics |
| `serviceMonitor: podTargetLabels:` | `[...string]` | `[]` | Pod labels transferred to the metrics |
| `serviceMonitor: namespaceSelector:` | `[...string]` | `[]` | Namespaces the Service is selected from; empty means its own |
| `serviceMonitor: sampleLimit:` | `int` | unset | Per-scrape sample limit |
| `serviceMonitor: targetLimit:` | `int` | unset | Scraped target limit |
| `serviceMonitor: labelLimit:` | `int` | unset | Per-scrape label limit |
| `serviceMonitor: labelNameLengthLimit:` | `int` | unset | Label name length limit |
| `serviceMonitor: labelValueLengthLimit:` | `int` | unset | Label value length limit |
| `serviceMonitor: http:` | `ScrapeEndpoint` | Prometheus defaults | Scrape settings of the metrics endpoint: `interval`, `scrapeTimeout`, `proxyUrl`, `enableHttp2`, `honorLabels`, `scheme`, `bearerTokenSecret`, `tlsConfig`, `metricRelabelings`, `relabelings` |
| `serviceMonitor: metrics:` | `ScrapeEndpoint` | Prometheus defaults | Scrape settings of the telemetry endpoint |
| `networkPolicy: enabled:` | `bool` | `false` | Create ingress and egress NetworkPolicies for the pods |
| `networkPolicy: ingress:` / `egress:` | `netv1` rules | serving ports in; DNS and Kubernetes API out | The policy rules |
