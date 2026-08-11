# vertical-pod-autoscaler

A [Timoni](https://timoni.sh) module for deploying the [Vertical Pod Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler), the Kubernetes autoscaler that rightsizes pod CPU and memory requests from observed usage.

## Version

<!-- versions:start -->
Latest module version is `1.7.1-0`, packaging the upstream release
[vertical-pod-autoscaler-1.7.1](https://github.com/kubernetes/autoscaler/releases/tag/vertical-pod-autoscaler-1.7.1)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `registry.k8s.io/autoscaling/vpa-recommender` | 1.7.1 | `sha256:89cea705535f9d8df6e62d5084916ec447e85d64369cfff2f7c6ac9d1cc5cd1e` |
| `registry.k8s.io/autoscaling/vpa-updater` | 1.7.1 | `sha256:feb42a5269708d065d5a43c5379d0e4700c3eca333231723d6a7c24f222ab446` |
| `registry.k8s.io/autoscaling/vpa-admission-controller` | 1.7.1 | `sha256:be29624f7f12a0b6f7fe18e2e042195eb6e39ae37d4490000f2643a480873572` |
<!-- versions:end -->

To list all available versions and their digests:

```shell
timoni mod list oci://ghcr.io/timonish/modules/vertical-pod-autoscaler
```

## Prerequisites

- Kubernetes 1.25+
- [Timoni](https://timoni.sh/install/) 0.31+
- [cert-manager](https://github.com/timonish/catalog/tree/main/modules/cert-manager) running in the cluster
- The resource Metrics API, e.g. from the
  [metrics-server](https://github.com/timonish/catalog/tree/main/modules/metrics-server) module

The module deploys the three autoscaler components: the recommender
computes the recommended resource requests from the metrics history,
the updater evicts (or resizes in place) the pods that diverge from
the recommendation, and the admission controller mutates pod creation
requests with the recommended resources. In the default configuration
the admission webhook certificate is issued and rotated by
cert-manager, and its CA is injected into the webhook configuration
by the cert-manager cainjector — cert-manager must be running before
this module is installed. The alternative webhook TLS modes described
under [Webhook TLS values](#webhook-tls-values) work without
cert-manager.

For the `VerticalPodAutoscaler` custom resource usage, see the
[upstream documentation](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler/docs).

## Install

To install the Vertical Pod Autoscaler in a dedicated namespace run:

```shell
timoni -n vertical-pod-autoscaler apply vertical-pod-autoscaler \
  oci://ghcr.io/timonish/modules/vertical-pod-autoscaler
```

To uninstall the instance and delete all its Kubernetes resources
including the CRDs:

```shell
timoni -n vertical-pod-autoscaler delete vertical-pod-autoscaler
```

Set `crds.keep: true` to leave the CRDs in place when the instance is deleted.

## Bundle

For production deployments it is recommended to use a Timoni
[bundle](https://timoni.sh/bundle/) that offers a declarative way of
managing the lifecycle of applications and their infra dependencies.

The following bundle deploys cert-manager and the Vertical Pod
Autoscaler together:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "vpa"
	instances: {
		"cert-manager": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/cert-manager"
				version: "latest"
			}
			namespace: "cert-manager"
		}
		"vertical-pod-autoscaler": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/vertical-pod-autoscaler"
				version: "latest"
			}
			namespace: "vertical-pod-autoscaler"
		}
	}
}
```

Save the bundle as `vpa.cue` and apply the stack with:

```shell
timoni bundle apply -f vpa.cue
```

Timoni applies the instances in order, waiting for cert-manager to
become ready before installing the autoscaler. On clusters without the
resource Metrics API, add a
[metrics-server](https://github.com/timonish/catalog/tree/main/modules/metrics-server)
instance at the top of the bundle.

## Configuration

All values are optional.

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |
| `crds.install` | `bool` | `true` | Install the VerticalPodAutoscaler CRDs; disable when the CRDs are managed outside of this module |
| `crds.keep` | `bool` | `false` | Keep the CRDs (and thus all VerticalPodAutoscaler resources) around when the instance is deleted |
| `imagePullSecrets` | `[...]` | unset | Secrets for pulling from private registries, attached to the service accounts |
| `rbac.create` | `bool` | `true` | Create the roles and bindings |
| `rbac.extraRules` | `[...rbacv1.#PolicyRule]` | unset | Extra rules appended to the recommender metrics-reader ClusterRole, e.g. for custom metrics |
| `securityProfile` | `hardened` or `platform` | `hardened` | Pod identity defaults: `hardened` pins the upstream image's non-root UID `65534`, `platform` leaves the identity to the cluster (e.g. OpenShift SCCs) |
| `serviceMonitor.enabled` | `bool` | `false` | Create a metrics Service and a Prometheus Operator ServiceMonitor for every deployed component |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | `60s` / `30s` | Scrape settings |
| `serviceMonitor.labels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata |
| `serviceMonitor.endpointAdditionalProperties` | `{...}` | unset | Extra properties merged into the scrape endpoints, e.g. `honorLabels` or `relabelings` |

### Component values

The three components are configured through the `recommender`,
`updater` and `admissionController` blocks, sharing these settings
(shown for `recommender`):

| Key | Type | Default | Description |
|---|---|---|---|
| `recommender.enabled` | `bool` | `true` | Deploy the component |
| `recommender.replicas` | `int` | `1` | Number of pod replicas; leader election and the PodDisruptionBudget default to enabled when greater than 1 |
| `recommender.image` | `timoniv1.#Image` | upstream release | Container image repository, tag, digest and pull policy |
| `recommender.revisionHistoryLimit` | `int` | `10` | Number of old ReplicaSets to retain |
| `recommender.strategy` | `appsv1.#DeploymentStrategy` | unset | Deployment update strategy |
| `recommender.resources` | `timoniv1.#ResourceRequirements` | unset | Container resource requirements |
| `recommender.securityContext` | `corev1.#SecurityContext` | hardened | Container security context; defaults: no privilege escalation, read-only rootfs, all capabilities dropped |
| `recommender.podSecurityContext` | `corev1.#PodSecurityContext` | per `securityProfile` | Pod security context |
| `recommender.extraArgs` | `[...string]` | `[]` | Extra command line arguments appended after the generated ones |
| `recommender.env` | `[...corev1.#EnvVar]` | unset | Extra environment variables |
| `recommender.nodeSelector` | `{[string]: string}` | Linux nodes | Node selection |
| `recommender.affinity` | `corev1.#Affinity` | soft anti-affinity | Scheduling affinity; defaults to preferring nodes not running the same component |
| `recommender.tolerations` / `topologySpreadConstraints` | | unset | Standard scheduling controls |
| `recommender.podLabels` / `podAnnotations` | `{[string]: string}` | unset | Extra pod metadata |
| `recommender.dnsPolicy` | `string` | cluster default | Pod DNS policy |
| `recommender.priorityClassName` | `string` | unset | Pod priority class |
| `recommender.deploymentAnnotations` | `{[string]: string}` | unset | Extra Deployment annotations |
| `recommender.serviceAccount.create` | `bool` | `true` | Create the service account; set to `false` to use an existing one |
| `recommender.serviceAccount.name` | `string` | `<instance>-recommender` | Service account name |
| `recommender.serviceAccount.labels` / `annotations` | `{[string]: string}` | unset | Extra service account metadata (e.g. IRSA role annotations) |
| `recommender.serviceAccount.automountServiceAccountToken` | `bool` | `true` | Automount the API credentials for the service account |
| `recommender.podDisruptionBudget.enabled` | `bool` | `replicas > 1` | Create a PodDisruptionBudget for the component pods |
| `recommender.podDisruptionBudget.minAvailable` / `maxUnavailable` | `int` or percent | `minAvailable: 1` | Disruption budget; the two are mutually exclusive (schema-enforced) |

### Leader election values

The recommender and updater elect a leader when running multiple
replicas; the extra replicas are hot standbys (shown for
`recommender`):

| Key | Type | Default | Description |
|---|---|---|---|
| `recommender.leaderElection.enabled` | `bool` | `replicas > 1` | Elect a leader among the replicas |
| `recommender.leaderElection.resourceNamespace` | `string` | instance namespace | Namespace of the lease resource |
| `recommender.leaderElection.resourceName` | `string` | `vpa-recommender-lease` | Name of the lease resource (`vpa-updater-lease` for the updater) |
| `recommender.leaderElection.leaseDuration` / `renewDeadline` / `retryPeriod` | `string` | `15s` / `10s` / `2s` | Leader election timing; raise on clusters with an overloaded API server |

### Updater values

| Key | Type | Default | Description |
|---|---|---|---|
| `updater.inPlaceSkipDisruptionBudget` | `bool` | `true` | Skip the PodDisruptionBudget check when applying in-place updates, which are non-disruptive by design |

### Admission controller values

| Key | Type | Default | Description |
|---|---|---|---|
| `admissionController.service.name` | `string` | `vpa-webhook` | Name of the webhook Service, passed to the admission controller with `--webhook-service` and set as the serving certificate DNS name |
| `admissionController.service.annotations` | `{[string]: string}` | unset | Extra webhook Service annotations |
| `admissionController.service.ports` | `[...corev1.#ServicePort]` | `443 -> 8000` | Webhook Service ports; the first port is referenced by the webhook configuration |
| `admissionController.hostNetwork` | `bool` | `false` | Run the pod in the host network namespace, for managed clusters with a custom CNI where the control plane cannot reach the pod network |
| `admissionController.mutatingWebhookConfiguration.failurePolicy` | `Ignore` or `Fail` | `Ignore` | `Ignore` admits pods unmutated when the webhook is unavailable; `Fail` guarantees resource updates at the cost of blocking pod creation during webhook downtime |
| `admissionController.mutatingWebhookConfiguration.namespaceSelector` / `objectSelector` | `metav1.#LabelSelector` | unset | Restrict the namespaces and objects the webhook mutates |
| `admissionController.mutatingWebhookConfiguration.timeoutSeconds` | `int` | `5` | Admission review request timeout |
| `admissionController.mutatingWebhookConfiguration.annotations` | `{[string]: string}` | unset | Extra webhook configuration annotations |

### Webhook TLS values

By default the webhook serving certificate is issued by cert-manager
from a self-signed issuer chain created by this module and rotated
automatically; the cainjector keeps the webhook configuration CA in
sync. The certificate can instead be issued by an existing
cert-manager issuer (`certManager.issuerRef`), provided as PEM values
(`tls.create`, with `caCert` set as the webhook CA bundle), or
pre-provisioned in a Secret with the admission controller registering
the webhook itself (`registerWebhook`) — the last two modes need no
cert-manager. One of the three modes must be enabled
(schema-enforced).

| Key | Type | Default | Description |
|---|---|---|---|
| `admissionController.certManager.enabled` | `bool` | `true` | Manage the webhook certificate lifecycle with cert-manager; mutually exclusive with `registerWebhook` and `tls.create` (schema-enforced) |
| `admissionController.certManager.createSelfSignedIssuer.enabled` | `bool` | `true` | Create the self-signed issuer chain signing the serving certificate |
| `admissionController.certManager.createSelfSignedIssuer.duration` / `renewBefore` | `string` | `8760h` / `720h` | Lifetime and renewal window of the intermediate CA certificate |
| `admissionController.certManager.issuerRef.name` | `string` | unset | Existing issuer signing the serving certificate; required when `createSelfSignedIssuer.enabled` is `false` |
| `admissionController.certManager.issuerRef.kind` / `group` | `string` | `ClusterIssuer` / `cert-manager.io` | Issuer reference kind and API group |
| `admissionController.certManager.duration` / `renewBefore` | `string` | `168h` / `24h` | Lifetime and renewal window of the serving certificate |
| `admissionController.certManager.privateKey.algorithm` | `RSA`, `ECDSA` or `Ed25519` | `RSA` | Certificate key algorithm |
| `admissionController.certManager.privateKey.size` | `int` | `2048` | Key size for RSA or ECDSA; ignored for Ed25519 |
| `admissionController.certManager.annotations` | `{[string]: string}` | unset | Extra annotations on the cert-manager resources |
| `admissionController.registerWebhook` | `bool` | `false` | Let the admission controller register (and remove) the webhook configuration itself, reading the serving certificate from the `tls.secretName` Secret |
| `admissionController.tls.create` | `bool` | `false` | Render the serving certificate Secret from the PEM values below |
| `admissionController.tls.secretName` | `string` | `vpa-tls-certs` | Name of the serving certificate Secret |
| `admissionController.tls.caCert` / `cert` / `key` | `string` | `""` | PEM-encoded CA certificate, serving certificate and private key for `tls.create` |
| `admissionController.volumes` / `volumeMounts` | `[...]` | serving certificate Secret | Override the pod volumes and mounts when the certificate is not managed by cert-manager |
