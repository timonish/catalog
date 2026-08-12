# external-dns

A [Timoni](https://timoni.sh) module for deploying [ExternalDNS](https://github.com/kubernetes-sigs/external-dns), a controller that synchronizes Kubernetes Services, Ingresses and other sources with DNS providers.

## Version

<!-- versions:start -->
Latest module version is `0.21.0-3`, packaging the upstream release
[v0.21.0](https://github.com/kubernetes-sigs/external-dns/releases/tag/v0.21.0)
with the following container images:

| Image | Tag | Digest |
|---|---|---|
| `registry.k8s.io/external-dns/external-dns` | v0.21.0 | `sha256:f53faaf71cb270d1ca9dce6ea0c94bfebf1a18696263487f0fbc74b9bf2bd7ff` |
<!-- versions:end -->

To list all available versions and their digests:

```shell
timoni mod list oci://ghcr.io/timonish/modules/external-dns
```

## Prerequisites

- Kubernetes 1.25+
- [Timoni](https://timoni.sh/install/) 0.31+

## Install

ExternalDNS needs a DNS provider to manage records in; the provider name
and its credentials are part of the instance values. Place the
configuration in a `values.cue` file, for example for
[Cloudflare](https://kubernetes-sigs.github.io/external-dns/latest/docs/tutorials/cloudflare/):

```cue
values: {
	provider: name: "cloudflare"
	env: [{
		name: "CF_API_TOKEN"
		valueFrom: secretKeyRef: {
			name: "cloudflare-api-token"
			key:  "token"
		}
	}]
	txtOwnerId: "my-cluster"
	domainFilters: ["example.com"]
}
```

And apply it with:

```shell
timoni -n external-dns apply external-dns \
  oci://ghcr.io/timonish/modules/external-dns \
  --values values.cue
```

Keep provider credentials out of the instance values: reference an
existing Secret with `env` (as above) or mount one as a file with
`extraVolumes` and `extraVolumeMounts`, matching what the chosen
provider expects.

To uninstall an instance and delete all the Kubernetes resources
including the DNSEndpoint CRD:

```shell
timoni -n external-dns delete external-dns
```

## Bundle

For production deployments it is recommended to use a Timoni
[bundle](https://timoni.sh/bundle/) that offers a declarative way of
managing the lifecycle of applications and their infra dependencies.

The following bundle deploys ExternalDNS on Amazon EKS managing
[Route53](https://kubernetes-sigs.github.io/external-dns/latest/docs/tutorials/aws/)
records, with the records of both cluster workloads and `DNSEndpoint`
custom resources kept in full sync, and metrics scraped by
prometheus-operator:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "external-dns"
	instances: {
		"external-dns": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/external-dns"
				version: "latest"
			}
			namespace: "external-dns"
			values: {
				provider: name: "aws"
				serviceAccount: annotations: {
					"eks.amazonaws.com/role-arn": "arn:aws:iam::111122223333:role/external-dns"
				}
				env: [{
					name:  "AWS_DEFAULT_REGION"
					value: "us-east-1"
				}]
				sources: ["service", "ingress", "crd"]
				policy:     "sync"
				txtOwnerId: "my-cluster"
				domainFilters: ["example.com"]
				serviceMonitor: enabled: true
			}
		}
	}
}
```

With `policy: sync`, records are removed when their source objects are
deleted; the `txt` registry with `txtOwnerId` guards the records owned
by this instance. The `crd` source enables managing arbitrary records
through `DNSEndpoint` custom resources.

Save the bundle as `external-dns.cue` and apply the stack with:

```shell
timoni bundle apply -f external-dns.cue
```

## Configuration

All values are optional.

### General values

| Key | Type | Default | Description |
|---|---|---|---|
| `provider.name` | `string` | `aws` | DNS provider, e.g. `aws`, `azure`, `cloudflare`, `google`, `webhook` — see the [provider docs](https://kubernetes-sigs.github.io/external-dns/) |
| `image` | `timoniv1.#Image` | upstream release | Container image repository, tag, digest and pull policy |
| `replicas` | `int` | `1` | Number of pod replicas; at most `1` (no leader election support), `0` suspends DNS synchronization |
| `revisionHistoryLimit` | `int` | unset | Number of old ReplicaSets to retain |
| `strategy` | `appsv1.#DeploymentStrategy` | `Recreate` | Rollout strategy; `Recreate` prevents concurrent record updates during a rollout |
| `env` | `[...corev1.#EnvVar]` | unset | Environment variables, typically the provider credentials referenced from an existing Secret |
| `resources` | `timoniv1.#ResourceRequirements` | unset | Container resource requirements |
| `securityContext` | `corev1.#SecurityContext` | hardened | Container security context; defaults: no privilege escalation, read-only rootfs, all capabilities dropped (the pod identity comes from `podSecurityContext`) |
| `livenessProbe` / `readinessProbe` | `corev1.#Probe` | `/healthz` | Container probes |
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |
| `rbac.create` | `bool` | `true` | Create the roles and bindings derived from `sources` |
| `rbac.extraRules` | `[...rbacv1.#PolicyRule]` | unset | Extra rules appended to the source-derived ones |
| `serviceAccount.create` | `bool` | `true` | Create the service account; set to `false` to use an existing one |
| `serviceAccount.name` | `string` | instance name, or `default` when `create: false` | Service account name |
| `serviceAccount.labels` / `annotations` | `{[string]: string}` | unset | Extra service account metadata (e.g. IRSA role annotations) |
| `serviceAccount.automountServiceAccountToken` | `bool` | `false` | Mount the token through the service account (the pod setting mounts it by default) |
| `crds.install` | `bool` | `true` | Install the DNSEndpoint CRD; disable on secondary instances so a single one owns it |
| `crds.keep` | `bool` | `false` | Keep the CRD (and all DNSEndpoints) when the instance is deleted |

### DNS synchronization values

| Key | Type | Default | Description |
|---|---|---|---|
| `sources` | `[...string]` | `["service", "ingress"]` | Kubernetes resources monitored for DNS entries; the RBAC rules are derived from this list |
| `policy` | `string` | `upsert-only` | `upsert-only` never deletes records, `sync` propagates deletions, `create-only` never touches existing records |
| `registry` | `string` | `txt` | Record ownership registry: `txt`, `aws-sd`, `dynamodb` or `noop` |
| `txtOwnerId` | `string` | unset | Identifier of this instance in the registry, guarding the records it owns |
| `txtPrefix` / `txtSuffix` | `string` | unset | Affix for the domain names of `txt` registry records; mutually exclusive (schema-enforced) |
| `interval` | `string` | `1m` | Interval between DNS reconciliations |
| `triggerLoopOnEvent` | `bool` | `false` | Also reconcile on source create/update/delete events |
| `domainFilters` / `excludeDomains` | `[...string]` | `[]` | Limit or exclude the managed zones by domain suffix |
| `labelFilter` / `annotationFilter` | `string` | unset | Filter the source resources by label or annotation selector |
| `annotationPrefix` | `string` | unset | Alternate annotation prefix, useful for split-horizon DNS with multiple instances |
| `managedRecordTypes` | `[...string]` | `[]` (upstream defaults to A, AAAA, CNAME) | DNS record types to manage |
| `namespaced` | `bool` | `false` | Watch a single namespace; RBAC becomes Role/RoleBinding |
| `sourceNamespace` | `string` | instance namespace | The namespace watched for sources when `namespaced` is enabled |
| `gatewayNamespace` | `string` | unset | Namespace watched for Gateway API gateways; with `namespaced`, setting it avoids all cluster-scoped RBAC |
| `enableGatewayListenerSets` | `bool` | `false` | Enable the Gateway API ListenerSet support |
| `logLevel` | `string` | `info` | One of `panic`, `debug`, `info`, `warning`, `error`, `fatal` |
| `logFormat` | `string` | `text` | `text` or `json` |
| `extraArgs` | `[...string]` | `[]` | Extra command line arguments appended after the generated ones |

### Provider webhook values

Setting `provider.name: webhook` runs a provider webhook sidecar
container next to external-dns; its image is required.

| Key | Type | Default | Description |
|---|---|---|---|
| `provider.webhook.image.repository` / `tag` / `digest` | `string` | required (digest optional) | Webhook container image, pinnable by digest |
| `provider.webhook.image.pullPolicy` | `string` | `IfNotPresent` | Webhook image pull policy |
| `provider.webhook.env` / `args` | `[...]` | unset | Webhook container environment and arguments |
| `provider.webhook.extraVolumeMounts` | `[...corev1.#VolumeMount]` | unset | Extra webhook volume mounts |
| `provider.webhook.resources` | `timoniv1.#ResourceRequirements` | unset | Webhook resource requirements |
| `provider.webhook.securityContext` | `corev1.#SecurityContext` | hardened | Webhook security context; same hardened defaults as the main container |
| `provider.webhook.livenessProbe` / `readinessProbe` | `corev1.#Probe` | `/healthz` | Webhook probes |
| `provider.webhook.service.port` | `int` | `8080` | Service port exposing the webhook |
| `provider.webhook.serviceMonitor` | | unset | Scrape overrides for the webhook metrics endpoint |

### Pod scheduling values

| Key | Type | Default | Description |
|---|---|---|---|
| `podLabels` / `podAnnotations` | `{[string]: string}` | unset | Extra pod metadata |
| `securityProfile` | `hardened` or `platform` | `hardened` | Pod identity defaults: `hardened` pins UID/GID `65532` and fsGroup `65534`, `platform` leaves the identity to the cluster (e.g. OpenShift SCCs) |
| `podSecurityContext` | `corev1.#PodSecurityContext` | per `securityProfile` | Pod security context |
| `imagePullSecrets` | `[...]` | unset | Secrets for pulling from private registries |
| `priorityClassName` | `string` | unset | Pod priority class |
| `affinity` | `corev1.#Affinity` | unset | Pod affinity; terms without a label selector match the instance pods |
| `nodeSelector` | `{[string]: string}` | Linux nodes | Node selection; a supplied value replaces the default |
| `tolerations` / `topologySpreadConstraints` | | unset | Standard scheduling controls; spread constraints without a label selector match the instance pods |
| `schedulerName` | `string` | unset | Alternate scheduler |
| `dnsPolicy` / `dnsConfig` | | unset | Pod DNS settings |
| `terminationGracePeriodSeconds` | `int` | unset | Pod termination grace period |
| `automountServiceAccountToken` | `bool` | `true` | Automount the API credentials in the pod |
| `shareProcessNamespace` | `bool` | `false` | Share a single process namespace between the pod containers |
| `initContainers` / `extraContainers` | `[...corev1.#Container]` | unset | Additional containers |
| `extraVolumes` / `extraVolumeMounts` | `[...]` | unset | Additional volumes, e.g. provider credential files from an existing Secret |
| `deploymentAnnotations` | `{[string]: string}` | unset | Annotations on the Deployment |

### Service and monitoring values

| Key | Type | Default | Description |
|---|---|---|---|
| `service.enabled` | `bool` | `true` | Create the metrics Service |
| `service.port` | `int` | `7979` | Service port |
| `service.type` | `string` | `ClusterIP` | Service type |
| `service.annotations` / `labels` | `{[string]: string}` | unset | Extra Service metadata |
| `service.clusterIP` / `externalIPs` / `nodePort` / `loadBalancerIP` / `loadBalancerClass` / `loadBalancerSourceRanges` / `externalTrafficPolicy` | | unset (`nodePort` 0=auto) | Service networking settings per type |
| `service.ipFamilies` / `ipFamilyPolicy` | | unset | Service IP family settings |
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor |
| `serviceMonitor.jobLabel` | `string` | `app.kubernetes.io/name` | Service label used as the Prometheus job name |
| `serviceMonitor.additionalLabels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata |
| `serviceMonitor.interval` / `scrapeTimeout` / `honorLabels` / `scheme` / `tlsConfig` / `bearerTokenFile` / `bearerTokenSecret` / `proxyUrl` | | unset | Scrape settings; unset values fall back to the Prometheus defaults |
| `serviceMonitor.sampleLimit` / `targetLimit` / `labelLimit` / `labelNameLengthLimit` / `labelValueLengthLimit` | `int` | unset | Scrape limits |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules |
| `serviceMonitor.targetLabels` / `podTargetLabels` | `[...string]` | unset | Service/pod labels copied onto the metrics |
