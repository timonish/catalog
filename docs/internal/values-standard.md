# Values API standard

The values API is the user-facing product of the catalog and its most
important aspect. This document is the authority on how module values
are designed; the upstream chart never dictates the API shape.

## Goals

The catalog balances four goals that operate on different layers of a
module and therefore do not conflict:

1. **Zero-downtime takeover** (rendered output): at onboarding, the
   upstream chart — or plain manifests when there is no chart — is the
   migration baseline. The module's rendered objects keep the upstream
   kinds, names, immutable selectors and ports so Timoni can adopt an
   existing upstream install without deleting workloads.
2. **Catalog standards override upstream** (defaults): hardened and
   sane defaults are non-negotiable even where upstream is weaker; see
   the standards below.
3. **Unified UX** (values shape): common settings look identical across
   all modules — users must never relearn how to configure a Kubernetes
   Service per module. The API shape is catalog-designed, never
   chart-mirrored.
4. **Upstream drift review** (maintenance): the upstream parity target
   is periodically re-read for new config surface, new APIs and better
   hardening; see [maintenance.md](maintenance.md).

## The golden rule, restated

Upstream coverage is a **floor**, this standard is the **shape**:

- Every config option offered by the upstream parity target must be
  achievable through the module values (capability coverage).
- The API surface does not stop where upstream stops: common settings
  follow the unified surface below even when the upstream chart lacks
  them (e.g. dual-stack Service fields).
- Helm-only mechanics (lookup, generated certs, PSP) are excluded;
  each exclusion is recorded as a comment on the module's `sources.ts`
  entry — never in the module README, which is user-facing.

## Catalog standards

- **Hardened security defaults**: containers run with the
  `timoniv1.#ContainerSecurityContext` restrictions; the pod identity
  follows `securityContextPreset` (`hardened` pins the image's non-root
  UID, `platform` defers to an admission controller).
- **Images pinned by digest**: defaults come from the generated
  `versions.cue` (`#defaultImages`), maintained by the sync engine.
  Hand-written CUE never hardcodes tags.
- **No Helm-generated certificates**: TLS is served by the addon's own
  generation, cert-manager, or an existing Secret — never a
  render-time-generated cert.
- **No extra manifests**: the module renders what the addon needs and
  nothing else.
- **Monitors are optional**: a Service/PodMonitor is offered when the
  addon has a metrics endpoint, always disabled by default.

## Unified common surface

The canonical shapes for settings shared by all modules, decided from
the 2026-08 cross-module audit. A module must not express one of these
concepts with a different field name, type or structure; addon-specific
fields may extend a block but never replace or rename its canonical
fields. Multi-component modules apply the same shapes per component.
Converging a module is a build-suffix bump (see
[maintenance.md](maintenance.md)).

### Shared value types

`timoniv1.#PromDuration` (Prometheus duration, bare `0` allowed, empty
string rejected) comes from the shared `timoni.sh/core` schemas — never
redefine it locally. The Go duration remains module-local:

```cue
// Go duration, e.g. "15s", "1h30m".
#Duration: string & =~"^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"
```

Ports are `int & >0 & <=65535`; node ports are `int & >=0 & <=32767`
with `0` meaning cluster-assigned — never a concrete pinned default.
Percent-or-count fields are `int & >=0 | string & =~"^[0-9]+%$"`.

### `service`

```cue
service: {
	type: *"ClusterIP" | "NodePort" | "LoadBalancer"
	port: *<module-default> | int & >0 & <=65535
	clusterIP?: string & =~".+"
	ipFamilies?: [..."IPv4" | "IPv6"]
	ipFamilyPolicy?: "SingleStack" | "PreferDualStack" | "RequireDualStack"
	externalIPs?: [...string]
	if type == "NodePort" {
		nodePort: *0 | int & >=0 & <=32767
	}
	if type == "LoadBalancer" {
		loadBalancerIP?:    string & =~".+"
		loadBalancerClass?: string & =~".+"
		loadBalancerSourceRanges?: [...string]
	}
	if type != "ClusterIP" {
		externalTrafficPolicy?: "Cluster" | "Local"
	}
	annotations?: timoniv1.#Annotations
	labels?:      timoniv1.#Labels
}
```

Every Service the module renders — primary, metrics, webhook,
per-component — carries this surface (webhook/metrics services may
omit `externalIPs`/LoadBalancer fields when exposing them makes no
sense, but never omit the dual-stack fields). An `enabled` toggle is
allowed only on auxiliary services that are genuinely optional.
Addon-specific extras (`trafficDistribution`, `httpsPort`,
`prometheusScrape`, headless `clusterIP: "None"` defaults) extend the
block.

### `serviceMonitor`

One schema, one set of defaults, from the shared `timoni.sh/core`
package:

```cue
serviceMonitor: timoniv1.#MonitorValues
```

The scrape settings use the `""` sentinel meaning "omit the field,
defer to the Prometheus defaults" — and that is the default: the
Prometheus administrator owns the scrape cadence, modules do not
override it. Module-specific defaults refine the block (metrics-server
`scheme: *"https" | "http"` with `tlsConfig` defaults,
prometheus-operator's webhook-conditional scheme).

The templates render the monitor through the core generators:
`spec: timoniv1.#MonitorSpec & {#Values: _config.serviceMonitor}` for
the shared spec fields, `timoniv1.#MonitorEndpointSpec` per endpoint —
the selector, namespace selector, port and path stay module-written.
Note `#MonitorSpec` emits `targetLabels` when set even into a
PodMonitor, which fails CRD validation loudly — intended, being a
Service concept.

The ServiceMonitor is always created in the instance namespace — a
module never writes resources outside the namespace it owns; Prometheus
selects monitors across namespaces (`serviceMonitorNamespaceSelector`),
and label-based filtering is served by `additionalLabels`. The upstream
charts' detached-namespace option is a recorded deviation.

Modules scraping several endpoints use `timoniv1.#Monitor` plus one
`timoniv1.#MonitorEndpoint` per endpoint (the kube-state-metrics
pattern) under the same top-level metadata. The sanctioned deviation:
the VPA `jobLabel` defaults to the component label, which conflicts
with the `#Monitor` jobLabel default under CUE unification — that
module keeps a local metadata block embedding `#MonitorEndpoint` and
hand-writes the spec fields (no `#MonitorSpec`). No untyped
`endpointAdditionalProperties` escape hatch — the typed surface covers
the ServiceMonitor endpoint API. No `prometheusInstance` convenience
field — that label is set through `additionalLabels`. The upstream
`prometheus.serviceMonitor` nesting (cert-manager) flattens to the
canonical top-level block; `podMonitor` remains addon-specific where
upstream offers it.

#### Documenting the monitoring values

Every module README with a monitor documents it in a dedicated
`### Monitoring values` section — never merged with Service or network
settings — containing this exact table (dot-style keys, grouped rows;
the READMEs use dot-style key references everywhere outside CUE
snippets):

```markdown
| Key | Type | Default | Description |
|---|---|---|---|
| `serviceMonitor.enabled` | `bool` | `false` | Create a Prometheus Operator ServiceMonitor <what it scrapes>, in the instance namespace |
| `serviceMonitor.additionalLabels` / `annotations` | `{[string]: string}` | unset | Extra ServiceMonitor metadata, e.g. labels for Prometheus discovery |
| `serviceMonitor.jobLabel` | `string` | `app.kubernetes.io/name` | Service label used as the Prometheus job name |
| `serviceMonitor.interval` / `scrapeTimeout` | `string` | unset | Scrape cadence; defaults to the Prometheus settings |
| `serviceMonitor.honorLabels` | `bool` | `false` | Keep scraped label values on collision |
| `serviceMonitor.enableHttp2` | `bool` | unset | Enable HTTP2 for scraping |
| `serviceMonitor.scheme` / `tlsConfig` / `bearerTokenFile` / `bearerTokenSecret` / `proxyUrl` | | unset | Scrape scheme, TLS, authentication and proxy settings |
| `serviceMonitor.metricRelabelings` / `relabelings` | `[...]` | unset | Relabeling rules for the samples and the targets |
| `serviceMonitor.sampleLimit` / `targetLimit` / `labelLimit` / `labelNameLengthLimit` / `labelValueLengthLimit` | `int` | unset | Scrape limits |
| `serviceMonitor.targetLabels` / `podTargetLabels` | `[...string]` | unset | Service/pod labels copied onto the metrics |
```

Module differences must read as differences, not as a restyled table:
a module-specific default edits the Default cell in place (VPA
`jobLabel`); a field whose default or description diverges from its
grouped row gets its own row in the same position (metrics-server and
prometheus-operator `scheme`/`tlsConfig`); rows that gate or plumb the
metrics exposure itself lead the section (cert-manager
`prometheus.enabled` and the monitor toggles, metrics-server
`metrics.enabled`, trust-manager `metrics.*`); other module-specific
fields append rows at the bottom (kube-state-metrics
`selectorOverride`, `namespaceSelector`), with per-endpoint blocks
last. The multi-endpoint form keeps the shared metadata rows, drops
the per-endpoint rows and documents one row per endpoint block
enumerating the standard endpoint fields (kube-state-metrics
`http`/`metrics`). cert-manager documents the shared scrape settings
once, "shown for `serviceMonitor`". A monitor nested in a component
block (external-dns `provider.webhook.serviceMonitor`) stays
documented with its component, pointing at the canonical endpoint
fields.

### `podDisruptionBudget`

```cue
podDisruptionBudget: {
	enabled:                     *false | bool
	unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
	*{minAvailable: *1 | int & >=0 | string & =~"^[0-9]+%$"} |
	{maxUnavailable: int & >=0 | string & =~"^[0-9]+%$"}
}
```

`minAvailable: 1` is the default of the default branch, so an enabled
PDB always constrains disruptions — a rendered PDB with neither field
is a bug. Modules may couple `enabled` to `replicas > 1` (the VPA
pattern) but keep the shape.

### Workload settings

- `replicas: *1 | int & >=0` — scale-to-zero suspends the addon;
  tighter upper bounds only for addons that cannot run replicated
  (external-dns `<=1`).
- `strategy?: appsv1.#DeploymentStrategy` — never `updateStrategy`.
- `revisionHistoryLimit?: int & >=0` — optional, no default.
- `deploymentAnnotations?` for Deployment metadata
  (kube-state-metrics' `workloadLabels`/`workloadAnnotations` is the
  sanctioned exception for its StatefulSet mode).
- `extraArgs: *[] | [...string]` — args appended after the generated
  ones; never plain `args` for the append hook.
- `env?: [...corev1.#EnvVar]` — never `extraEnv`; module-specific
  defaults (prometheus-operator GOGC) use `env: *[...] | [...]`.
- `extraVolumes?` / `extraVolumeMounts?` — never bare
  `volumes`/`volumeMounts`.
- `extraContainers?` / `initContainers?` where sidecars make sense.
- Probes: every long-running container exposes `livenessProbe` and
  `readinessProbe` as full `corev1.#Probe` values with defaults
  (plus `startupProbe` where the addon needs one); never a bespoke
  `{port, path}` sub-shape.
- `resources: timoniv1.#ResourceRequirements` with upstream request
  defaults when upstream defines them, otherwise `resources?`.
- Token mounting: pod-level `automountServiceAccountToken: *true |
  bool` plus ServiceAccount-level `*false | bool` (the token reaches
  the pod through the pod spec, not the SA).

### Pod scheduling and metadata

Present in every workload block:

```cue
podLabels?:      timoniv1.#Labels
podAnnotations?: timoniv1.#Annotations
nodeSelector: *{"kubernetes.io/os": "linux"} | {[string]: string}
tolerations?: [...corev1.#Toleration]
affinity: timoniv1.#AffinityValues & {
	podAntiAffinity: timoniv1.#AffinityPreset | corev1.#PodAntiAffinity
	nodeAffinity?:   corev1.#NodeAffinity
	podAffinity?:    corev1.#PodAffinity
}
topologySpreadConstraints?: [...corev1.#TopologySpreadConstraint]
dnsPolicy?:  "ClusterFirst" | "ClusterFirstWithHostNet" | "Default" | "None"
dnsConfig?:  corev1.#PodDNSConfig
priorityClassName?:             string & =~".+"
schedulerName?:                 string & =~".+"
terminationGracePeriodSeconds?: int & >=0
```

Linux placement is the `nodeSelector` default, not a default
`affinity` term. The `podAntiAffinity` preset defaults to `soft`:
every workload prefers spreading its replicas across nodes. The
workload template builds a hidden
`_affinity: timoniv1.#Affinity & {#Values: ..., #MatchLabels: ...}`
wired to the workload's own selector labels (per-component for
multi-component modules) and renders `affinity` behind
`if _affinity.#Enabled`. Raw anti-affinity rules replace the preset
and need explicit label selectors — there is no selector completion.
One-shot Jobs (envoy-gateway certgen) keep a raw
`affinity?: corev1.#Affinity`: with no replicas to spread, the presets
do not apply. `hostNetwork` (with the dnsPolicy default flip to
`ClusterFirstWithHostNet`) extends this. `priorityClassName` gets a
concrete default only when upstream sets one
(`system-cluster-critical` for metrics-server).

### `serviceAccount`, `rbac`, `crds`

```cue
serviceAccount: {
	create: *true | bool
	if create {name: *metadata.name | string}
	if !create {name: *"default" | string}
	labels?:                      timoniv1.#Labels
	annotations?:                 timoniv1.#Annotations
	automountServiceAccountToken: *false | bool
}

rbac: {
	create: *true | bool
	// Optional per module:
	extraRules?: [...rbacv1.#PolicyRule]   // never `additionalPermissions`
	aggregateClusterRoles?: bool           // where upstream offers it
}

crds: {                                   // CRD-shipping modules
	install: *true | bool
	keep:    *false | bool
}
```

### Naming and hardening rules

- `logLevel` / `logFormat` are the field names; the value vocabulary
  follows the upstream component.
- TLS mode selectors are named `tls.type`; the `certManager` sub-block
  uses `existingIssuer {enabled, kind, name}`, `duration`,
  `renewBefore`, `annotations`, `labels`.
- Every container image block — including sidecars, init containers
  and third-party webhook providers — is a `timoniv1.#Image` with a
  `digest` field, and every container has a `securityContext` with the
  hardened `timoniv1.#ContainerSecurityContext` default. No container
  escapes the standards because it is auxiliary.

### Renaming or removing a value

When a module's values surface changes, grep `test/bundles/` for other
bundles that install that module as a dependency and update the values
they pass. Dependency instances pull the *published* module, so the
module's own PR goes green and the breakage only appears after merge,
once `push.yaml` publishes the new version — from then on every PR's
e2e job for the dependent bundle fails with `field not allowed`.
