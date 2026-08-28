# external-secrets

A [Timoni](https://timoni.sh) module for deploying [External Secrets Operator](https://github.com/external-secrets/external-secrets), the Kubernetes operator that syncs secrets from external secret management systems into Kubernetes Secrets.

## Version

<!-- versions:start -->
Latest module version is `2.10.0-0`, packaging the upstream release
[v2.10.0](https://github.com/external-secrets/external-secrets/releases/tag/v2.10.0)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `ghcr.io/external-secrets/external-secrets` | v2.10.0 | `sha256:814117b0fd6d121b03e8ba3b6db1cecbe7449a354fc0fc9c4faf73a37aa221b1` |
<!-- versions:end -->

To list all available versions and their digests:

```shell
timoni mod list oci://ghcr.io/timonish/modules/external-secrets
```

## Prerequisites

- Kubernetes 1.25+
- [Timoni](https://timoni.sh/install/) 0.31+

## Install

The module deploys the three External Secrets components — the
controller, the validating webhook and the cert-controller issuing the
webhook certificate — together with the External Secrets CRDs
(SecretStore, ClusterSecretStore, ExternalSecret,
ClusterExternalSecret, PushSecret, ClusterPushSecret and the
generators):

```shell
timoni -n external-secrets apply external-secrets \
  oci://ghcr.io/timonish/modules/external-secrets
```

Once the instance is ready, secrets can be synced from a provider
through SecretStore and ExternalSecret custom resources — see the
External Secrets [provider docs](https://external-secrets.io/latest/provider/aws-secrets-manager/)
for the supported secret backends.

To uninstall and prune all the Kubernetes resources:

```shell
timoni -n external-secrets delete external-secrets
```

Deleting the instance also removes the CRDs and thereby **every
External Secrets custom resource in the cluster**; the synced
Kubernetes Secrets are left in place. Set `crds: keep: true` to
preserve the CRDs and the custom resources on uninstall.

## Bundle

For production deployments it is recommended to use a Timoni
[bundle](https://timoni.sh/bundle/) that offers a declarative way of
managing the lifecycle of applications and their infra dependencies.

The following bundle deploys cert-manager and a highly-available
External Secrets instance with leader election and
PodDisruptionBudgets enabled for each replicated component, the
webhook certificate issued by cert-manager and metrics scraped by
prometheus-operator:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "external-secrets"
	instances: {
		"cert-manager": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/cert-manager"
				version: "latest"
			}
			namespace: "cert-manager"
		}
		"external-secrets": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/external-secrets"
				version: "latest"
			}
			namespace: "external-secrets"
			values: {
				controller: {
					replicas:   2
					concurrent: 4
				}
				webhook: {
					replicas: 2
					tls: type: "cert-manager"
				}
				serviceMonitor: enabled: true
			}
		}
	}
}
```

Save the bundle as `external-secrets.cue` and apply the stack with:

```shell
timoni bundle apply -f external-secrets.cue
```

## Configuration

### Webhook certificate

The webhook serving certificate is selected by `webhook.tls.type`:

- `cert-controller` (default): the cert-controller component
  generates a self-signed certificate into the `webhook.tls.secretName`
  Secret, renews it and injects its CA into the webhook
  configurations.
- `cert-manager`: the certificate is requested through a cert-manager
  Certificate and the CA is injected by the cert-manager cainjector;
  the cert-controller is not deployed. By default the module creates a
  self-signed Issuer; set `webhook.tls.certManager.existingIssuer` to
  use an existing Issuer or ClusterIssuer.
- `existingSecret`: the `webhook.tls.secretName` Secret holds a
  user-provided certificate (`tls.crt`, `tls.key`) and
  `webhook.tls.caBundle` its PEM-encoded CA; the cert-controller is not
  deployed.

Switching away from `cert-manager` leaves the cert-manager issued
Secret in place; delete it so the new certificate source can take
over without waiting for `webhook.certCheckInterval`.

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `crds.install` | `bool` | `true` | Install the External Secrets CRDs; disable on secondary instances so a single one owns them |
| `crds.keep` | `bool` | `false` | Keep the CRDs (and all External Secrets custom resources) when the instance is deleted |
| `rbac.create` | `bool` | `true` | Create the cluster roles, roles and bindings |
| `rbac.aggregateClusterRoles` | `bool` | `true` | Aggregate the External Secrets view/edit roles into the Kubernetes user-facing roles |
| `rbac.serviceAccountTokenCreate` | `bool` | `true` | Let the controller create service account tokens for stores authenticating with them |
| `rbac.serviceBindings` | `bool` | `true` | Create the ClusterRole granting Service Binding controllers read access to ExternalSecrets and PushSecrets |
| `rbac.openshiftFinalizers` | `bool` | `true` | Grant the controller the `finalizers` subresources required by OpenShift |
| `rbac.systemAuthDelegator` | `bool` | `false` | Bind the controller to the `system:auth-delegator` ClusterRole |
| `rbac.extraRules` | `[...rbacv1.#PolicyRule]` | unset | Extra rules added to the controller role |
| `scopedNamespace` | `string` | unset | Reconcile the custom resources of a single namespace only |
| `scopedRBAC` | `bool` | `false` | Grant the controller a namespaced Role in `scopedNamespace` (or the instance namespace) instead of cluster-wide permissions; disables the cluster-scoped reconcilers |
| `enableHTTP2` | `bool` | `false` | Enable HTTP/2 on the metrics and webhook listeners |
| `securityContextPreset` | `hardened` or `platform` | `hardened` | Pod identity defaults of all components: `hardened` pins the image's UID 65534, `platform` leaves the identity to an admission controller |
| `image` | `timoniv1.#Image` | upstream release | Container image repository, tag, digest and pull policy, shared by all components |
| `imagePullSecrets` | `[...timoniv1.#ObjectReference]` | unset | Registry credentials added to all service accounts |
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |

### Common component values

The following values are available for each component under
`controller`, `webhook` and `certController`:

| Key | Type | Default | Description |
|---|---|---|---|
| `replicas` | `int` | `1` | Number of pod replicas |
| `revisionHistoryLimit` | `int` | unset | Number of old ReplicaSets to retain |
| `strategy` | `appsv1.#DeploymentStrategy` | unset | Deployment rollout strategy |
| `resources` | `timoniv1.#ResourceRequirements` | unset | Container resource requirements |
| `securityContext` | `corev1.#SecurityContext` | hardened | Container security context; defaults: no privilege escalation, read-only rootfs, all capabilities dropped |
| `podSecurityContext` | `corev1.#PodSecurityContext` | per `securityContextPreset` | Pod security context; defaults: runAsNonRoot, RuntimeDefault seccomp profile |
| `logLevel` | `string` | `info` | Log level: `debug`, `info`, `warn`, `error`, `dpanic`, `panic` or `fatal` |
| `logTimeEncoding` | `string` | `epoch` | Log timestamp encoding: `epoch`, `millis`, `nano`, `iso8601`, `rfc3339` or `rfc3339nano` |
| `healthPort` | `int` | `8082` controller, `8081` others | Port of the health endpoint serving the probes |
| `livenessProbe` / `readinessProbe` | `corev1.#Probe` | `/healthz`, `/readyz` | Container probes |
| `extraArgs` | `[...string]` | `[]` | Extra command line arguments appended after the generated ones |
| `env` | `[...corev1.#EnvVar]` | unset | Environment variables |
| `extraVolumes` / `extraVolumeMounts` | `corev1` | unset | Extra pod volumes and container mounts |
| `initContainers` / `extraContainers` | `[...corev1.#Container]` | unset | Init containers and extra containers added to the pod |
| `nodeSelector` | `{[string]: string}` | Linux nodes | Node selection constraints |
| `affinity.podAntiAffinity` | `soft`, `hard`, `none` or raw rules | `soft` | Spread the component replicas across nodes; raw rules replace the preset |
| `affinity.nodeAffinity` / `affinity.podAffinity` | raw rules | unset | Node and pod affinity rules |
| `tolerations` / `topologySpreadConstraints` | `corev1` | unset | Pod scheduling settings |
| `podLabels` / `podAnnotations` | `{[string]: string}` | unset | Extra pod metadata |
| `deploymentAnnotations` | `{[string]: string}` | unset | Annotations added to the Deployment |
| `dnsPolicy` / `dnsConfig` | `corev1` | unset | Pod DNS settings |
| `hostAliases` | `[...corev1.#HostAlias]` | unset | Entries added to the pod hosts file |
| `hostNetwork` | `bool` | `false` | Run the pod on the host network; the dnsPolicy defaults to `ClusterFirstWithHostNet` |
| `hostUsers` | `bool` | unset | Run the pod in a user namespace (Kubernetes 1.33+) |
| `priorityClassName` / `schedulerName` / `runtimeClassName` | `string` | unset | Pod runtime settings |
| `terminationGracePeriodSeconds` | `int` | unset | Pod termination grace period |
| `automountServiceAccountToken` | `bool` | `true` | Mount the service account token into the pod |
| `enableServiceLinks` | `bool` | `false` | Inject service information into the pod environment |
| `serviceAccount.create` | `bool` | `true` | Create the service account; set to `false` to use an existing one |
| `serviceAccount.name` | `string` | component name, `default` when not created | Service account name |
| `serviceAccount.labels` / `annotations` | `{[string]: string}` | unset | Extra service account metadata (e.g. IRSA or Workload Identity annotations) |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount the token through the service account (the pod setting mounts it by default) |
| `podDisruptionBudget.enabled` | `bool` | `replicas > 1` | Create a PodDisruptionBudget for the component |
| `podDisruptionBudget.minAvailable` / `maxUnavailable` | `int or %` | `minAvailable: 1` | Disruption budget; mutually exclusive (schema-enforced) |
| `podDisruptionBudget.unhealthyPodEvictionPolicy` | `string` | unset | `IfHealthyBudget` or `AlwaysAllow` (Kubernetes 1.27+) |
| `networkPolicy.enabled` | `bool` | `false` | Create ingress and egress NetworkPolicies for the component pods |
| `networkPolicy.ingress` / `egress` | `netv1` rules | serving ports in; DNS, HTTP(S) and Kubernetes API out | The policy rules |

### Controller values

| Key | Type | Default | Description |
|---|---|---|---|
| `controller.leaderElection.enabled` | `bool` | `replicas > 1` | Leader election between the controller replicas |
| `controller.leaderElection.id` | `string` | `external-secrets-controller` | Lease name; set a unique value for independent instances sharing a namespace |
| `controller.leaderElection.leaseDuration` / `renewDeadline` / `retryPeriod` | `string` | unset | Leader election timings |
| `controller.controllerClass` | `string` | unset | Reconcile only the stores with this `spec.controller` class |
| `controller.concurrent` | `int` | `1` | Concurrent ExternalSecret reconciles |
| `controller.storeRequeueInterval` | `string` | unset | Default interval between (Cluster)SecretStore reconciles |
| `controller.extendedMetricLabels` | `bool` | `false` | Add the recommended Kubernetes annotations as metric labels |
| `controller.reconcilers.clusterStore` / `clusterExternalSecret` / `clusterPushSecret` / `secretStore` / `pushSecret` / `clusterGenerator` | `bool` | `true` | Reconcilers to run; disabling one drops its RBAC permissions |
| `controller.genericTargets.enabled` | `bool` | `false` | Sync into ConfigMaps and custom resources instead of Secrets; grants ConfigMap write access |
| `controller.genericTargets.resources` | `[...{apiGroup, resources, verbs}]` | unset | Extra target resource types the controller is granted access to |
| `controller.vault.enableTokenCache` | `bool` | `false` | Reuse HashiCorp Vault tokens across reconciles |
| `controller.vault.tokenCacheSize` | `int` | `262144` | Maximum Vault token cache size |

### Webhook values

| Key | Type | Default | Description |
|---|---|---|---|
| `webhook.enabled` | `bool` | `true` | Deploy the validating webhook and its admission configurations; disabling it also skips the cert-controller |
| `webhook.port` | `int` | `10250` | TLS port serving the admission endpoint; `10250` avoids conflicts and is open in GKE private cluster firewalls |
| `webhook.tls.type` | `string` | `cert-controller` | Serving certificate source: `cert-controller`, `cert-manager` or `existingSecret` |
| `webhook.tls.secretName` | `string` | `<instance>-webhook` | Secret holding the serving certificate |
| `webhook.tls.caBundle` | `string` | unset | PEM-encoded CA of the existing certificate (`existingSecret` type) |
| `webhook.tls.certManager.createCertificate` | `bool` | `true` | Create the Certificate; disable when a separately managed Certificate writes the Secret |
| `webhook.tls.certManager.existingIssuer.enabled` | `bool` | `false` | Use an existing issuer instead of the self-signed Issuer created by the module |
| `webhook.tls.certManager.existingIssuer.kind` / `name` / `group` | `string` | `Issuer`, `cert-manager.io` | Existing issuer reference, including external issuer kinds and groups |
| `webhook.tls.certManager.duration` / `renewBefore` | `string` | `8760h` / unset | Certificate lifetime and renewal window |
| `webhook.tls.certManager.privateKey` / `signatureAlgorithm` / `revisionHistoryLimit` | — | unset | Certificate key and signing settings |
| `webhook.tls.certManager.addInjectorAnnotations` | `bool` | `true` | Annotate the webhook configurations for cainjector CA injection |
| `webhook.tls.certManager.annotations` / `labels` | `{[string]: string}` | unset | Extra cert-manager resource metadata |
| `webhook.certCheckInterval` / `lookaheadInterval` | `string` | `5m` / unset | Serving certificate renewal check interval and lookahead |
| `webhook.failurePolicy` | `string` | `Fail` | `Fail` rejects SecretStore and ExternalSecret changes while the webhook is unavailable, `Ignore` admits them unvalidated |
| `webhook.timeoutSeconds` | `int` | `5` | Admission request timeout of the webhook configurations |
| `webhook.annotations` | `{[string]: string}` | unset | Extra ValidatingWebhookConfiguration annotations |
| `webhook.service.type` | `string` | `ClusterIP` | Webhook Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `webhook.service.port` | `int` | `443` | Webhook Service port |
| `webhook.service.clusterIP` / `ipFamilies` / `ipFamilyPolicy` | — | unset | Service network settings |
| `webhook.service.nodePort` / `loadBalancerIP` / `loadBalancerClass` / `loadBalancerSourceRanges` / `externalTrafficPolicy` | — | unset | Settings of the non-ClusterIP Service types |
| `webhook.service.annotations` / `labels` | `{[string]: string}` | unset | Extra Service metadata |
| `webhook.startupProbe` | `corev1.#Probe` | unset | Webhook container startup probe |

### Cert-controller values

| Key | Type | Default | Description |
|---|---|---|---|
| `certController.leaderElection.enabled` | `bool` | `replicas > 1` | Leader election between the cert-controller replicas |
| `certController.requeueInterval` | `string` | `5m` | Interval between webhook certificate reconciles |
| `certController.enablePartialCache` | `bool` | `true` | Cache only the Secrets labeled `external-secrets.io/component` |
| `certController.startupProbe` | `corev1.#Probe` | unset | Cert-controller container startup probe |

### Monitoring values

The metrics endpoint of each component is exposed through a Service
under `controller.metrics`, `webhook.metrics` and
`certController.metrics`:

| Key | Type | Default | Description |
|---|---|---|---|
| `metrics.port` | `int` | `8080` | Metrics listener port |
| `metrics.secure.enabled` | `bool` | `false` | Serve the metrics over HTTPS from the certificate at `certDir` (mounted through `extraVolumes`) |
| `metrics.secure.certDir` / `certName` / `keyName` | `string` | `/etc/tls`, `tls.crt`, `tls.key` | Metrics serving certificate location |
| `metrics.auth.enabled` | `bool` | `false` | Protect the metrics endpoint with Kubernetes RBAC authentication; requires `secure.enabled` |
| `metrics.service.enabled` | `bool` | `false` | Create the metrics Service (always created when the ServiceMonitor is enabled) |
| `metrics.service.port` | `int` | `8080` | Metrics Service port |
| `metrics.service.clusterIP` / `ipFamilies` / `ipFamilyPolicy` / `annotations` / `labels` | — | unset | Metrics Service settings; the webhook exposes its metrics on the webhook Service, which takes the network settings from `webhook.service` |

| Key | Type | Default | Description |
|---|---|---|---|
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor scraping all deployed components, in the instance namespace |
| `serviceMonitor.additionalLabels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata, e.g. labels for Prometheus discovery |
| `serviceMonitor.jobLabel` | `string` | `app.kubernetes.io/name` | Service label used as the Prometheus job name |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | unset | Scrape cadence; defaults to the Prometheus settings |
| `serviceMonitor.honorLabels` | `bool` | `false` | Keep scraped label values on collision |
| `serviceMonitor.enableHttp2` | `bool` | unset | Enable HTTP2 for scraping |
| `serviceMonitor.scheme` / `tlsConfig` / `bearerTokenFile` / `bearerTokenSecret` / `proxyUrl` | | unset | Scrape scheme, TLS, authentication and proxy settings |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules for the samples and the targets |
| `serviceMonitor.sampleLimit` / `targetLimit` / `labelLimit` / `labelNameLengthLimit` / `labelValueLengthLimit` | `int` | unset | Scrape limits |
| `serviceMonitor.targetLabels` / `podTargetLabels` | `[...string]` | unset | Service/pod labels copied onto the metrics |
