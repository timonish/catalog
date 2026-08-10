# cert-manager

A [Timoni](https://timoni.sh) module for deploying [cert-manager](https://github.com/cert-manager/cert-manager), the Kubernetes certificate controller that automates the issuance and renewal of TLS certificates.

## Version

<!-- versions:start -->
Latest module version is `1.21.1-0`, packaging the upstream release
[v1.21.1](https://github.com/cert-manager/cert-manager/releases/tag/v1.21.1)
with the following container images:

| Image | Tag |
|---|---|
| `quay.io/jetstack/cert-manager-controller` | v1.21.1 |
| `quay.io/jetstack/cert-manager-webhook` | v1.21.1 |
| `quay.io/jetstack/cert-manager-cainjector` | v1.21.1 |
| `quay.io/jetstack/cert-manager-acmesolver` | v1.21.1 |
<!-- versions:end -->

To list all available versions and their digests:

```shell
timoni mod list oci://ghcr.io/timonish/modules/cert-manager
```

## Prerequisites

- Kubernetes 1.22+
- Timoni 0.30+

## Install

The module deploys the three cert-manager components — controller,
webhook and cainjector — together with the cert-manager CRDs
(Certificate, Issuer, ClusterIssuer, CertificateRequest, Order,
Challenge):

```shell
timoni -n cert-manager apply cert-manager \
  oci://ghcr.io/timonish/modules/cert-manager
```

Once the instance is ready, certificates can be requested through
Issuer and ClusterIssuer resources, for example a self-signed CA:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned
spec:
  selfSigned: {}
```

To uninstall and prune all the Kubernetes resources:

```shell
timoni -n cert-manager delete cert-manager
```

Deleting the instance also removes the CRDs and thereby **every
cert-manager custom resource in the cluster**. Set `crds: keep: true`
to preserve the CRDs and the certificate data on uninstall.

## Bundle

For production deployments it is recommended to use a Timoni
[bundle](https://timoni.sh/bundle/) that offers a declarative way of
managing the lifecycle of applications and their infra dependencies.

The following bundle deploys a highly-available cert-manager tuned for
ACME issuers, with certificates requested through Ingress annotations
defaulting to a `letsencrypt` ClusterIssuer, orphaned TLS secrets
cleaned up with the certificates, and metrics scraped by
prometheus-operator:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "cert-manager"
	instances: {
		"cert-manager": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/cert-manager"
				version: "latest"
			}
			namespace: "cert-manager"
			values: {
				controller: {
					replicas: 2
					config: {
						enableCertificateOwnerRef: true
						ingressShimConfig: {
							defaultIssuerName: "letsencrypt"
							defaultIssuerKind: "ClusterIssuer"
						}
						acmeDNS01Config: recursiveNameservers: ["1.1.1.1:53"]
					}
					podDisruptionBudget: enabled: true
				}
				webhook: {
					replicas: 2
					podDisruptionBudget: enabled: true
				}
				cainjector: {
					replicas: 2
					podDisruptionBudget: enabled: true
				}
				prometheus: serviceMonitor: enabled: true
			}
		}
	}
}
```

Save the bundle as `cert-manager.cue` and apply the stack with:

```shell
timoni bundle apply -f cert-manager.cue
```

After the install, create the ClusterIssuer referenced by the ingress
shim, e.g. for Let's Encrypt:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-account
    solvers:
      - http01:
          ingress:
            ingressClassName: nginx
```

## Configuration

### Component configuration files

Each component is configured through its upstream
[configuration file API](https://cert-manager.io/docs/installation/configuring-components/)
exposed as typed values: `controller.config`, `webhook.config` and
`cainjector.config`. The module renders each one into an immutable
ConfigMap passed to the component via `--config`; configuration changes
roll the pods automatically.

Command line flags override the configuration file, so `extraArgs` can
set options ahead of them being added to the typed schemas.

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `crds.install` | `bool` | `true` | Install the cert-manager CRDs; disable on secondary instances so a single one owns them |
| `crds.keep` | `bool` | `false` | Keep the CRDs (and all cert-manager custom resources) when the instance is deleted |
| `rbac.create` | `bool` | `true` | Create the cluster roles, roles and bindings |
| `rbac.aggregateClusterRoles` | `bool` | `true` | Aggregate the cert-manager view/edit roles into the Kubernetes user-facing roles |
| `approveSignerNames` | `[...string]` | cert-manager issuers | Signer names the approver controller may approve for |
| `disableAutoApproval` | `bool` | `false` | Disable the automatic approval of CertificateRequests and skip the approval RBAC |
| `imagePullSecrets` | `[...timoniv1.#ObjectReference]` | unset | Registry credentials added to all service accounts |
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |

### Common component values

The following values are available for each component under
`controller`, `webhook` and `cainjector`:

| Key | Type | Default | Description |
|---|---|---|---|
| `image` | `timoniv1.#Image` | upstream release | Container image repository, tag, digest and pull policy |
| `replicas` | `int` | `1` | Number of pod replicas |
| `revisionHistoryLimit` | `int` | unset | Number of old ReplicaSets to retain |
| `strategy` | `appsv1.#DeploymentStrategy` | unset | Deployment rollout strategy |
| `resources` | `timoniv1.#ResourceRequirements` | unset | Container resource requirements |
| `securityContext` | `corev1.#SecurityContext` | hardened | Container security context; defaults: no privilege escalation, read-only rootfs, all capabilities dropped |
| `podSecurityContext` | `corev1.#PodSecurityContext` | hardened | Pod security context; defaults: runAsNonRoot, RuntimeDefault seccomp profile |
| `extraArgs` | `[...string]` | `[]` | Extra command line arguments appended after `--config`; flags override the configuration file |
| `env` | `[...corev1.#EnvVar]` | unset | Environment variables |
| `volumes` / `volumeMounts` | `corev1` | unset | Extra pod volumes and container mounts |
| `extraContainers` | `[...corev1.#Container]` | unset | Extra containers added to the pod |
| `nodeSelector` | `{[string]: string}` | Linux nodes | Node selection constraints |
| `affinity` / `tolerations` / `topologySpreadConstraints` | `corev1` | unset | Pod scheduling settings |
| `podLabels` / `podAnnotations` | `{[string]: string}` | unset | Extra pod metadata |
| `deploymentAnnotations` | `{[string]: string}` | unset | Annotations added to the Deployment |
| `dnsPolicy` / `dnsConfig` | `corev1` | unset | Pod DNS settings |
| `hostAliases` | `[...corev1.#HostAlias]` | unset | Entries added to the pod hosts file |
| `hostUsers` | `bool` | unset | Run the pod in a user namespace |
| `priorityClassName` / `runtimeClassName` | `string` | unset | Pod runtime settings |
| `automountServiceAccountToken` | `bool` | unset | Mount the service account token into the pod |
| `enableServiceLinks` | `bool` | `false` | Inject service information into the pod environment |
| `serviceAccount.create` | `bool` | `true` | Create the service account; set to `false` to use an existing one |
| `serviceAccount.name` | `string` | component name | Service account name |
| `serviceAccount.labels` / `annotations` | `{[string]: string}` | unset | Extra service account metadata (e.g. IRSA role annotations for the Route53 solver) |
| `serviceAccount.automountServiceAccountToken` | `bool` | `true` | Automount the API credentials for the service account |
| `podDisruptionBudget.enabled` | `bool` | `false` | Create a PodDisruptionBudget for the component |
| `podDisruptionBudget.minAvailable` / `maxUnavailable` | `int \| string` | `minAvailable: 1` | Disruption budget; mutually exclusive (schema-enforced) |
| `networkPolicy.enabled` | `bool` | `false` | Create ingress and egress NetworkPolicies for the component pods |
| `networkPolicy.ingress` / `egress` | `netv1` rules | serving ports in; DNS, HTTP(S) and Kubernetes API out | The policy rules |

### Controller values

| Key | Type | Default | Description |
|---|---|---|---|
| `controller.config.namespace` | `string` | unset | Limit cert-manager to a single namespace; ClusterIssuers are disabled |
| `controller.config.clusterResourceNamespace` | `string` | instance namespace | Namespace storing resources owned by cluster-scoped resources such as ClusterIssuer |
| `controller.config.leaderElectionConfig` | object | `kube-system` | Leader election lease namespace and timings; the module grants lease RBAC in the configured namespace |
| `controller.config.controllers` | `[...string]` | all | Controllers to enable, e.g. `["*", "-certificaterequests-approver"]` |
| `controller.config.issuerAmbientCredentials` | `bool` | unset | Let Issuers use ambient credentials (e.g. EC2 IAM roles) |
| `controller.config.clusterIssuerAmbientCredentials` | `bool` | unset | Let ClusterIssuers use ambient credentials |
| `controller.config.enableCertificateOwnerRef` | `bool` | unset | Make Certificates own their TLS Secrets so the Secrets are removed with them |
| `controller.config.copiedAnnotationPrefixes` | `[...string]` | unset | Annotation key prefixes copied from Certificate to CertificateRequest and Order |
| `controller.config.numberOfConcurrentWorkers` | `int` | unset | Concurrent workers per controller |
| `controller.config.maxConcurrentChallenges` | `int` | `60` | Maximum ACME challenges scheduled as processing at once |
| `controller.config.metricsListenAddress` | `string` | `0.0.0.0:9402` | Metrics endpoint; `0` disables it (default follows `prometheus.enabled`) |
| `controller.config.metricsTLSConfig` | `#TLSConfig` | unset | Metrics endpoint TLS, from certificate files or a dynamic self-signed CA |
| `controller.config.healthzListenAddress` | `string` | `0.0.0.0:9403` | Healthz endpoint |
| `controller.config.logging` | object | `text`, verbosity `2` | Log format (`text`/`json`) and verbosity (0-6) |
| `controller.config.featureGates` | `{[string]: bool}` | unset | Experimental feature gates |
| `controller.config.ingressShimConfig` | object | unset | Default issuer and annotations for certificates requested through Ingress resources |
| `controller.config.acmeHTTP01Config` | object | upstream release solver image | ACME HTTP01 solver image, resources, nameservers and labels |
| `controller.config.acmeDNS01Config` | object | unset | ACME DNS01 recursive nameservers and check period |
| `controller.config.pemSizeLimitsConfig` | object | unset | Maximum sizes for PEM-encoded data |
| `controller.config.gatewayAPI` | object | unset | Gateway API integration: `enabled`, `enableListenerSet`, `extraProtocols` |
| `controller.config.certificateRequestMinimumBackoffDuration` / `MaximumBackoffDuration` | `string` | `1h` / `32h` upstream | Backoff window for failing certificate requests |
| `controller.livenessProbe` | `corev1.#Probe` | `/livez` | Controller liveness probe |
| `controller.service.annotations` / `labels` / `ipFamilies` / `ipFamilyPolicy` | — | unset | Metrics Service settings |

### Webhook values

| Key | Type | Default | Description |
|---|---|---|---|
| `webhook.config.securePort` | `int` | `10250` | TLS port serving the admission endpoints; `10250` avoids conflicts and is open in GKE private cluster firewalls |
| `webhook.config.healthzPort` | `int` | `6080` | Plaintext healthz port |
| `webhook.config.tlsConfig` | `#TLSConfig` | dynamic self-signed CA | Serving certificates: a generated CA in the `<instance>-webhook-ca` Secret, or certificate files provided via `volumes` |
| `webhook.config.enableClientVerification` | `bool` | unset | Verify the API server client certificates (with `clientCAPath` and `clientCertificateSubjects`) |
| `webhook.config.logging` / `featureGates` / `metricsListenAddress` / `metricsTLSConfig` | — | as controller | Observability settings |
| `webhook.hostNetwork` | `bool` | `false` | Run on the host network, for clusters where the control plane cannot reach the pod network |
| `webhook.timeoutSeconds` | `int` | `30` | Admission request timeout of the webhook configurations |
| `webhook.url.host` | `string` | unset | Reach the webhook at an external host instead of the in-cluster Service |
| `webhook.service.type` | `string` | `ClusterIP` | Webhook Service type (`ClusterIP`, `NodePort`, `LoadBalancer`) |
| `webhook.service.loadBalancerIP` / `annotations` / `labels` / `ipFamilies` / `ipFamilyPolicy` | — | unset | Webhook Service settings |
| `webhook.validatingWebhookConfiguration.namespaceSelector` | `metav1.#LabelSelector` | skip namespaces labeled `cert-manager.io/disable-validation: "true"` | Namespaces subject to resource validation |
| `webhook.validatingWebhookConfiguration.annotations` | `{[string]: string}` | unset | Extra ValidatingWebhookConfiguration annotations |
| `webhook.mutatingWebhookConfiguration.namespaceSelector` / `annotations` | — | unset | MutatingWebhookConfiguration settings |
| `webhook.livenessProbe` / `readinessProbe` | `corev1.#Probe` | `/livez`, `/healthz` | Webhook container probes |

### CAInjector values

| Key | Type | Default | Description |
|---|---|---|---|
| `cainjector.enabled` | `bool` | `true` | Deploy the cainjector; it is required by the webhook, only disable it when another instance runs in the cluster |
| `cainjector.config.namespace` | `string` | unset | Limit the cainjector to a single namespace |
| `cainjector.config.ignoreNamespaces` | `[...string]` | unset | Namespaces ignored by the cainjector |
| `cainjector.config.leaderElectionConfig` | object | `kube-system` | Leader election lease namespace and timings |
| `cainjector.config.enableDataSourceConfig.certificates` | `bool` | unset | Watch Certificate resources as a CA source |
| `cainjector.config.enableInjectableConfig` | object | unset | Resource kinds the CA data is injected into |
| `cainjector.config.logging` / `featureGates` / `metricsListenAddress` / `metricsTLSConfig` | — | as controller | Observability settings |
| `cainjector.service.annotations` / `labels` | `{[string]: string}` | unset | Metrics Service settings |

### Monitoring values

| Key | Type | Default | Description |
|---|---|---|---|
| `prometheus.enabled` | `bool` | `true` | Serve metrics on all components and create their metrics Services; without a monitor enabled, the pods carry `prometheus.io` scrape annotations |
| `prometheus.serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor scraping all components |
| `prometheus.podMonitor.enabled` | `bool` | `false` | Create a PodMonitor instead of the ServiceMonitor; mutually exclusive (schema-enforced) |
| `prometheus.serviceMonitor.*` / `prometheus.podMonitor.*` | — | `60s` / `30s` | `namespace`, `prometheusInstance`, `interval`, `scrapeTimeout`, `honorLabels`, `labels`, `annotations`, `endpointAdditionalProperties` |
