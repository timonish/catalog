# Maintenance

How modules are published, fixed and kept in sync with their upstreams.
Routine upstream version bumps are fully automated and need none of
this; this document covers everything the automation does not do.

## Publishing model

`push.yaml` runs on every merge to `main`: it loops over all modules,
compares each `VERSION` against the module's GHCR tags
(`timoni mod list`) and publishes only missing versions — idempotent,
safe to rerun, failures in one module don't block the others. GHCR
answers `DENIED` for not-yet-created packages, so first publishes log a
warning then push.

## Releasing a module-only fix

For a change to the module itself (new values, templates, docs), bump
the build suffix and refresh the provenance so the next sync run stays
idempotent:

1. Edit the module, then set `modules/<name>/VERSION` to
   `<upstream>-<n+1>`.
2. Run `make sync MODULE=<name> FORCE=1` — the forced re-sync keeps the
   build suffix (while the upstream release is unchanged; a newer
   release resets it to `-0`) and regenerates the generated files
   (`versions.cue`, `crds.cue`), the history manifest, the module
   README version section and the catalog README table.
3. Open a PR; after the merge, `push.yaml` publishes the new version.

## Upstream parity review

Every module source (`upengine/config/sources/<name>.ts`) declares a
`parityTarget`: the URL of the
upstream config surface — a Helm chart directory, or the plain
manifests when there is no chart — the module holds parity with. The
field is informational and never consumed by the engine; it exists so
onboarding and periodic reviews know what to read.

The sync engine only tracks *versions*. When upstream *adds* surface —
a new chart value, a new field in a typed component Config API (e.g.
cert-manager's ControllerConfiguration), better hardening — nothing
fails and the module silently falls behind the golden rule. Catching
that requires a periodic manual review:

1. Read the `parityTarget` at its current state and compare against
   what the module was built for. For in-repo targets the commit in
   `upengine/history/<name>.json` pins what the last sync saw, and
   `https://github.com/<owner>/<repo>/compare/<oldTag>...<newTag>`
   scopes the diff. The cross-repo charts (kube-state-metrics,
   prometheus-operator) version independently of the tracked upstream —
   diff by the chart's own release tags instead.
2. Triage every addition into one of three buckets:
   - absorb into the unified common surface
     ([values-standard.md](values-standard.md)) when it is a common
     concern;
   - add as an addon-specific value when it is not;
   - reject when it contradicts the catalog standards, recording why.
3. Ship the changes as a module-only fix (above).

For modules whose parity surface spans more than the chart (cert-manager
Config APIs), review those sources too — the entry's comment in
the module source says what else to read. Automating the review nudge
(per-sync content digests of watched upstream paths, changed paths
flagged in bump PR bodies) is deferred engine work.
