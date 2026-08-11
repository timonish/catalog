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
  follows `securityProfile` (`hardened` pins the image's non-root UID,
  `platform` defers to an admission controller).
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

The canonical shapes for settings shared by all modules. To be defined
by the cross-module consistency audit; converging a module is a
build-suffix bump (see [maintenance.md](maintenance.md)).

Sections to be filled by the audit:

- **`service`**: type/port/annotations/labels plus the full networking
  surface (`clusterIP`, `ipFamilies`, `ipFamilyPolicy`, load-balancer
  fields, `nodePort`) regardless of upstream chart support.
- **`serviceMonitor`**: one schema and one set of scrape defaults
  (today they diverge four ways across modules).
- **Duration fields**: one regex shape for intervals/timeouts.
- **Pod scheduling and metadata**: `podLabels`, `podAnnotations`,
  `nodeSelector`, `tolerations`, `affinity`,
  `topologySpreadConstraints`, `priorityClassName`.

Known drift to resolve (recorded 2026-08-11): metrics-server Service
lacks the dual-stack fields; serviceMonitor defaults split four ways
(1m/10s, 60s/30s, 10s/5s, unset); external-dns lacks `scrapeTimeout`;
three different duration regex shapes exist.
