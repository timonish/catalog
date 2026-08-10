# prometheus-operator

A [Timoni](https://timoni.sh) module for deploying [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) to Kubernetes clusters.

## Version

<!-- versions:start -->
Latest module version is `0.93.0-0`, packaging the upstream release
[v0.93.0](https://github.com/prometheus-operator/prometheus-operator/releases/tag/v0.93.0)
with the following container images:

| Image | Tag |
|---|---|
| `quay.io/prometheus-operator/prometheus-operator` | v0.93.0 |
| `quay.io/prometheus-operator/prometheus-config-reloader` | v0.93.0 |
<!-- versions:end -->

## Prerequisites

- Kubernetes 1.25 or newer
- [Timoni](https://timoni.sh/install/) 0.25 or newer

## Install

The module installs the `monitoring.coreos.com` custom resource
definitions (Prometheus, PrometheusAgent, Alertmanager, AlertmanagerConfig,
ThanosRuler, ServiceMonitor, PodMonitor, Probe, PrometheusRule and
ScrapeConfig) and the operator that reconciles them. Prometheus and
Alertmanager instances are not part of the module: after installing it,
create `Prometheus`, `PrometheusAgent` or `Alertmanager` custom
resources and the operator builds the workloads from them.

To create an instance using the default values:

```shell
timoni -n monitoring apply prometheus-operator \
  oci://ghcr.io/timonish/modules/prometheus-operator
```

To change the [configuration](#configuration), create a `values.cue` file:

```cue
values: {
	logLevel: "debug"
	namespaces: ["monitoring", "apps"]
}
```

And apply the values with:

```shell
timoni -n monitoring apply prometheus-operator \
  oci://ghcr.io/timonish/modules/prometheus-operator \
  --values ./values.cue
```

### Uninstall

**Warning**: uninstalling the instance deletes the custom resource
definitions and with them **every** `monitoring.coreos.com` custom
resource in the cluster (Prometheus instances, ServiceMonitors,
alerting rules, and so on). To preserve them, apply
`crds: keep: true` before uninstalling:

```cue
values: {
	crds: keep: true
}
```

With `keep` enabled, uninstalling removes the operator but leaves the
CRDs and all custom resources in place:

```shell
timoni -n monitoring delete prometheus-operator
```

On clusters where the CRD lifecycle is managed out of band, the module
can skip installing them altogether with `crds: install: false`.

## Admission webhook

The operator can validate `PrometheusRule` and `AlertmanagerConfig`
resources at admission time, rejecting invalid rule expressions and
Alertmanager configurations before they reach the operator. The
webhook is disabled by default; enabling it switches the operator web
server to TLS with the certificate provisioned according to
`webhook: tls:`.

With [cert-manager](https://cert-manager.io) installed in the cluster,
the module requests the certificate from a self-signed issuer and lets
the cert-manager CA injector wire the webhook configurations:

```cue
values: {
	webhook: enabled: true
}
```

To issue the certificate from an existing cert-manager issuer instead:

```cue
values: {
	webhook: {
		enabled: true
		tls: certManager: existingIssuer: {
			enabled: true
			kind:    "ClusterIssuer"
			name:    "my-ca-issuer"
		}
	}
}
```

Without cert-manager, supply an existing TLS secret (with the standard
`tls.crt` and `tls.key` keys) and the PEM-encoded CA of the serving
certificate:

```cue
values: {
	webhook: {
		enabled: true
		tls: {
			type: "existingSecret"
			existingSecret: name: "prometheus-operator-tls"
			caBundle: """
				-----BEGIN CERTIFICATE-----
				...
				-----END CERTIFICATE-----
				"""
		}
	}
}
```

By default the webhook fails closed: while the operator is down,
creating or updating `PrometheusRule` and `AlertmanagerConfig`
resources is rejected. Set `webhook: failurePolicy: "Ignore"` to admit
them instead. When the operator watch scope is restricted with
`namespaces` or `denyNamespaces`, the webhook scope follows it
automatically.

## Bundle

An example [bundle](https://timoni.sh/bundle/) for deploying the
operator along with cert-manager (instances are applied in definition
order, so the webhook certificate can be issued right away):

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "monitoring-stack"
	instances: {
		"cert-manager": {
			module: url: "oci://ghcr.io/timonish/modules/cert-manager"
			namespace: "cert-manager"
		}
		"prometheus-operator": {
			module: url: "oci://ghcr.io/timonish/modules/prometheus-operator"
			namespace: "monitoring"
			values: {
				webhook: enabled: true
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
| `crds: install:` | `bool` | `true` | Install the `monitoring.coreos.com` custom resource definitions |
| `crds: keep:` | `bool` | `false` | Keep the CRDs and all custom resources when the instance is uninstalled |
| `image: repository:` | `string` | `quay.io/prometheus-operator/prometheus-operator` | Container image repository |
| `image: tag:` | `string` | `<latest version>` | Container image tag |
| `image: digest:` | `string` | `""` | Container image digest, takes precedence over `tag` when specified |
| `image: pullPolicy:` | `string` | `IfNotPresent` | Container image pull policy |
| `imagePullSecrets:` | `[...ObjectReference]` | `[]` | References to secrets for pulling images from private registries |
| `metadata: labels:` | `{[string]: string}` | `{}` | Labels added to all resources |
| `metadata: annotations:` | `{[string]: string}` | `{}` | Annotations added to all resources |
| `commonLabels:` | `{[string]: string}` | `{}` | Extra labels added to all resources |
| `logLevel:` | `string` | `info` | Log verbosity: `all`, `debug`, `info`, `warn`, `error` or `none` |
| `logFormat:` | `string` | `logfmt` | Log format: `logfmt` or `json` |
| `env:` | `[...EnvVar]` | `GOGC=30` | Environment variables for the operator container |
| `extraArgs:` | `[...string]` | `[]` | Extra command line arguments appended after the generated ones |
| `extraVolumes:` | `[...Volume]` | `[]` | Extra volumes added to the pod |
| `extraVolumeMounts:` | `[...VolumeMount]` | `[]` | Extra volume mounts for the operator container |
| `resources:` | `ResourceRequirements` | `100m/100Mi (requests), 200m/200Mi (limits)` | Container resource requirements |
| `securityContext:` | `SecurityContext` | hardened | Container security context |
| `livenessProbe:` | `Probe` | `/healthz` on the serving port | Liveness probe of the operator container |
| `readinessProbe:` | `Probe` | `/healthz` on the serving port | Readiness probe of the operator container |
| `rbac: create:` | `bool` | `true` | Create the ClusterRole and ClusterRoleBinding |
| `rbac: aggregateClusterRoles:` | `bool` | `false` | Create view/edit ClusterRoles for the monitoring custom resources, aggregated into the built-in user-facing roles |
| `serviceAccount: create:` | `bool` | `true` | Create the ServiceAccount, or reference an existing one via `name` |
| `serviceAccount: name:` | `string` | instance name | Name of the ServiceAccount the operator runs under |
| `serviceAccount: annotations:` | `{[string]: string}` | `{}` | Annotations added to the ServiceAccount |
| `serviceAccount: automountServiceAccountToken:` | `bool` | `false` | Mount the token by default in pods using this ServiceAccount (the operator pod mounts it through the pod-level setting) |

### Operator scope values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `namespaces:` | `[...string]` | `[]` | Namespaces watched for ServiceMonitor, PodMonitor, Probe, PrometheusRule and configuration resources; empty means all. Mutually exclusive with `denyNamespaces` |
| `denyNamespaces:` | `[...string]` | `[]` | Namespaces excluded from watching |
| `prometheusInstanceNamespaces:` | `[...string]` | `[]` | Namespaces watched for Prometheus and PrometheusAgent resources |
| `alertmanagerInstanceNamespaces:` | `[...string]` | `[]` | Namespaces watched for Alertmanager resources |
| `alertmanagerConfigNamespaces:` | `[...string]` | `[]` | Namespaces watched for AlertmanagerConfig resources |
| `thanosRulerInstanceNamespaces:` | `[...string]` | `[]` | Namespaces watched for ThanosRuler resources |
| `prometheusInstanceSelector:` | `string` | `""` | Label selector filtering the Prometheus resources this operator manages |
| `alertmanagerInstanceSelector:` | `string` | `""` | Label selector filtering the Alertmanager resources this operator manages |
| `thanosRulerInstanceSelector:` | `string` | `""` | Label selector filtering the ThanosRuler resources this operator manages |
| `secretFieldSelector:` | `string` | excludes dockercfg, SA token, Helm and Timoni secrets | Field selector filtering the Secrets the operator watches and caches |
| `watchReferencedObjectsInAllNamespaces:` | `bool` | `true` | Watch objects referenced from the custom resources in all namespaces |
| `disableUnmanagedPrometheusConfiguration:` | `bool` | `true` | Reject Prometheus instances with no resource selectors configured |
| `featureGates:` | `{[string]: bool}` | `{}` | Operator feature gates, e.g. `PrometheusAgentDaemonSet: true` |
| `kubeletService: enabled:` | `bool` | `true` | Maintain the kubelet Endpoints for scraping the kubelets |
| `kubeletService: namespace:` | `string` | `kube-system` | Namespace of the kubelet Service |
| `kubeletService: name:` | `string` | `kubelet` | Name of the kubelet Service |
| `kubeletService: selector:` | `string` | `""` | Label selector filtering the kubelet nodes |
| `kubeletEndpoints:` | `bool` | `true` | Maintain the kubelet Endpoints object |
| `kubeletEndpointSlice:` | `bool` | `false` | Maintain the kubelet EndpointSlice objects |
| `clusterDomain:` | `string` | `""` | Cluster domain used for the generated addresses |
| `configReloader: image: repository:` | `string` | `quay.io/prometheus-operator/prometheus-config-reloader` | Config-reloader image repository |
| `configReloader: image: tag:` | `string` | `<latest version>` | Config-reloader image tag |
| `configReloader: image: digest:` | `string` | `""` | Config-reloader image digest, takes precedence over `tag` when specified |
| `configReloader: resources:` | `ResourceRequirements` | operator defaults | Resource requirements of the config-reloader sidecars injected into the managed pods |
| `configReloader: enableProbe:` | `bool` | `false` | Enable the config-reloader sidecar probes |
| `prometheusDefaultBaseImage:` | `string` | operator default | Base image for Prometheus instances without an image |
| `alertmanagerDefaultBaseImage:` | `string` | operator default | Base image for Alertmanager instances without an image |
| `thanosDefaultBaseImage:` | `string` | operator default | Base image for Thanos instances without an image |
| `localhostAddress:` | `string` | operator default | Address on which the operator reaches its managed instances |

### Pod scheduling values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `podLabels:` | `{[string]: string}` | `{}` | Labels added to the pods |
| `podAnnotations:` | `{[string]: string}` | `{}` | Annotations added to the pods |
| `podSecurityContext:` | `PodSecurityContext` | hardened | Pod security context |
| `nodeSelector:` | `{[string]: string}` | `kubernetes.io/os: linux` | Node selector for pod scheduling |
| `tolerations:` | `[...Toleration]` | `[]` | Pod tolerations |
| `affinity:` | `Affinity` | `{}` | Pod affinity rules |
| `topologySpreadConstraints:` | `[...TopologySpreadConstraint]` | `[]` | Pod topology spread constraints |
| `dnsConfig:` | `PodDNSConfig` | `{}` | Pod DNS configuration |
| `dnsPolicy:` | `string` | `ClusterFirst` | Pod DNS policy, defaults to `ClusterFirstWithHostNet` with `hostNetwork` |
| `hostNetwork:` | `bool` | `false` | Run the pods in the host network namespace |
| `priorityClassName:` | `string` | `""` | Priority class of the pods |
| `terminationGracePeriodSeconds:` | `int` | `30` | Pod termination grace period |
| `automountServiceAccountToken:` | `bool` | `true` | Mount the service account token into the pod |
| `strategy:` | `DeploymentStrategy` | `RollingUpdate` | Deployment update strategy |
| `revisionHistoryLimit:` | `int` | `10` | Number of old ReplicaSets to retain |
| `deploymentAnnotations:` | `{[string]: string}` | `{}` | Annotations added to the Deployment |
| `podDisruptionBudget: enabled:` | `bool` | `false` | Create a PodDisruptionBudget for the operator pod |
| `podDisruptionBudget: minAvailable:` | `int or %` | unset | Minimum available pods, mutually exclusive with `maxUnavailable` |
| `podDisruptionBudget: maxUnavailable:` | `int or %` | unset | Maximum unavailable pods |
| `podDisruptionBudget: unhealthyPodEvictionPolicy:` | `string` | unset | `IfHealthyBudget` or `AlwaysAllow` (Kubernetes 1.27+) |

### Service values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `service: type:` | `string` | `ClusterIP` | Service type: `ClusterIP`, `NodePort` or `LoadBalancer` |
| `service: port:` | `int` | `8080` | Service port of the operator web server |
| `service: httpsPort:` | `int` | `443` | Service port of the TLS web server when the webhook is enabled |
| `service: clusterIP:` | `string` | `""` | Static cluster IP, or `None` for a headless Service |
| `service: annotations:` | `{[string]: string}` | `{}` | Annotations added to the Service |
| `service: labels:` | `{[string]: string}` | `{}` | Labels added to the Service |
| `service: ipFamilies:` | `[...string]` | `[]` | IP families: `IPv4` and/or `IPv6` |
| `service: ipFamilyPolicy:` | `string` | `""` | `SingleStack`, `PreferDualStack` or `RequireDualStack` |
| `service: externalIPs:` | `[...string]` | `[]` | External IPs accepted by the Service |
| `service: nodePort:` | `int` | `30080` | Node port of the web server with `type: NodePort` |
| `service: nodePortTls:` | `int` | `30443` | Node port of the TLS web server with `type: NodePort` |
| `service: loadBalancerIP:` | `string` | `""` | Load balancer IP with `type: LoadBalancer` |
| `service: loadBalancerSourceRanges:` | `[...string]` | `[]` | CIDRs allowed to reach the load balancer |
| `service: externalTrafficPolicy:` | `string` | `Cluster` | External traffic policy for `NodePort` and `LoadBalancer` |

### Monitoring and network values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `serviceMonitor: enabled:` | `bool` | `false` | Create a ServiceMonitor scraping the operator's own metrics |
| `serviceMonitor: additionalLabels:` | `{[string]: string}` | `{}` | Labels added to the ServiceMonitor, e.g. for Prometheus selectors |
| `serviceMonitor: interval:` | `string` | `1m` | Scrape interval; empty falls back to the Prometheus defaults |
| `serviceMonitor: scrapeTimeout:` | `string` | `10s` | Scrape timeout; empty falls back to the Prometheus defaults |
| `serviceMonitor: sampleLimit:` | `int` | unset | Per-scrape sample limit |
| `serviceMonitor: targetLimit:` | `int` | unset | Scraped target limit |
| `serviceMonitor: labelLimit:` | `int` | unset | Per-scrape label limit |
| `serviceMonitor: labelNameLengthLimit:` | `int` | unset | Label name length limit |
| `serviceMonitor: labelValueLengthLimit:` | `int` | unset | Label value length limit |
| `serviceMonitor: metricRelabelings:` | `[...RelabelConfig]` | `[]` | Relabeling rules applied to the samples |
| `serviceMonitor: relabelings:` | `[...RelabelConfig]` | `[]` | Relabeling rules applied to the targets |
| `networkPolicy: enabled:` | `bool` | `false` | Create ingress and egress NetworkPolicies for the operator pod |
| `networkPolicy: ingress:` / `egress:` | `netv1` rules | serving port in; DNS and Kubernetes API out | The policy rules |

### Admission webhook values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `webhook: enabled:` | `bool` | `false` | Enable the PrometheusRule and AlertmanagerConfig admission webhooks and switch the operator web server to TLS |
| `webhook: port:` | `int` | `10250` | Container port of the TLS web server |
| `webhook: failurePolicy:` | `string` | `Fail` | `Fail` rejects admission while the webhook is unreachable, `Ignore` admits |
| `webhook: timeoutSeconds:` | `int` | `10` | Webhook call timeout |
| `webhook: namespaceSelector:` | `LabelSelector` | derived from the watch scope | Namespaces subject to admission |
| `webhook: objectSelector:` | `LabelSelector` | `{}` | Objects subject to admission |
| `webhook: matchConditions:` | `[...MatchCondition]` | `[]` | CEL expressions gating admission (Kubernetes 1.28+, omitted on older clusters) |
| `webhook: tls: type:` | `string` | `cert-manager` | Certificate provisioning: `cert-manager` or `existingSecret` |
| `webhook: tls: minVersion:` | `string` | `VersionTLS13` | Minimum TLS version of the web server |
| `webhook: tls: cipherSuites:` | `[...string]` | Go defaults | TLS cipher suites (TLS 1.2 and below) |
| `webhook: tls: certManager: existingIssuer:` | `object` | self-signed issuer | Issue the certificate from an existing `Issuer` or `ClusterIssuer` |
| `webhook: tls: certManager: duration:` | `string` | cert-manager default | Certificate validity |
| `webhook: tls: certManager: renewBefore:` | `string` | cert-manager default | Renewal window |
| `webhook: tls: certManager: annotations:` / `labels:` | `{[string]: string}` | `{}` | Extra metadata for the Issuer and Certificate |
| `webhook: tls: existingSecret: name:` | `string` | `""` | Existing TLS secret with `tls.crt` and `tls.key` |
| `webhook: tls: caBundle:` | `string` | `""` | PEM-encoded CA of the serving certificate, required with `existingSecret` |
