# AGENTS.md

Guidance for AI agents working in the **timonish/catalog** repository.

## Project overview

A catalog of [Timoni](https://timoni.sh) modules written in
[CUE](https://cuelang.org) for popular Kubernetes addons, published to
`oci://ghcr.io/timonish/modules/<name>`. Upstream releases are tracked daily
and fully automated: the sync engine bumps modules, CI gates the changes, and
merged bumps publish themselves.

Module versioning mirrors the upstream addon plus a catalog build number,
e.g. metrics-server `0.9.0-0`; a module-only fix bumps the suffix
(`0.9.0-1`), a new upstream release resets it to `-0`.

## Repository layout

| Path                                    | What it is                                                                                                                         |
|-----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| `modules/<name>/`                       | One Timoni module per addon                                                                                                        |
| `modules/<name>/VERSION`                | Version source of truth (`<upstream>-<build>`)                                                                                     |
| `modules/<name>/templates/versions.cue` | **Generated:** image repos/tags (`templates/config/versions.cue` in the packages layout)                                           |
| `modules/<name>/templates/crds.cue`     | **Generated:** cue-imported upstream CRDs                                                                                          |
| `schemas/`                              | Shared CUE module: single copy of the vendored `timoni.sh/core` and `k8s.io` schemas ([schemas/README.md](schemas/README.md))      |
| `upengine/`                             | Bun/TypeScript automation engine; `upengine/config/sources.ts` declares each module's upstream and e2e test                        |
| `upengine/history/`                     | **Generated:** per-module provenance manifests                                                                                     |
| `test/`                                 | kind cluster config; `test/bundles/<name>/bundle.cue` — per-module e2e install bundle                                              |
| `.github/workflows/`                    | `test.yaml` (fmt+vet+lint), `e2e.yaml` (kind), `push.yaml` (idempotent GHCR publish), `update-catalog.yaml` (daily sync)           |
| `Makefile`                              | Entrypoints for all of the above. `Brewfile` — required CLIs                                                                       |

## Conventions

- **Never hand-edit generated files**: `templates/versions.cue`,
  `templates/crds.cue`, `schemas/cue.mod/gen/**`, `upengine/history/`, the
  catalog README modules table and the version section between the
  `<!-- versions:start -->` markers in each module README are owned by the
  sync engine / vendoring targets. Hand-written CUE references
  `versions.cue` for image tags so routine bumps never touch curated files.
- **Shared schemas are symlinked, never copied**: each module's
  `cue.mod/pkg/timoni.sh`, `cue.mod/gen/k8s.io` and the CRD schema groups
  its templates import (`monitoring.coreos.com`, `cert-manager.io`) are
  relative symlinks into `schemas/`. Pushes use `--resolve-symlinks` (set
  in `make push-mod`).
- **Upstream CRDs ship in the generated `templates/crds.cue`**: a module
  that installs CRDs declares the upstream manifest as `crds` in
  `sources.ts` — either a repo `file` fetched at the pinned commit
  (`modules/external-dns`) or a `releaseAsset` of the resolved release
  (`modules/cert-manager`); every sync normalizes it (packaging labels
  and annotations stripped) and re-imports it with `cue import`. When
  the upstream publishes one manifest per release channel, `crds`
  declares `channels` instead and each channel is generated into
  `templates/crds_<channel>.cue` under `crds: <channel>:`, selected by
  an instance value (`modules/gateway-api`). Normalization is tunable
  per source: `keepKinds` retains extra document kinds shipped with the
  CRDs, `keepLabels` preserves semantic upstream labels. CRD *schemas*
  are a separate concern, only needed when templates create typed
  custom resources — universal ones live in the shared `schemas/`, and
  nothing is vendored per module so far.
- **CRDs-only modules omit `images`** (`modules/gateway-api`): no
  versions.cue is generated and the README version section renders
  without an image table. Such a module can opt out of the GitHub
  Actions e2e matrix with `e2e: ci: false` in `sources.ts` (vet still
  gates it in CI; `make e2e` still runs it locally).
- **Multi-deployment addons use the multi-package layout** (see
  `modules/cert-manager`): one CUE package per component under
  `templates/<component>`, plus `templates/config` holding the values
  schema; component object names and labels come from the Timoni
  `#MetaComponent` convention. The module declares `layout: "packages"`
  in `sources.ts`, which moves the generated image defaults to
  `templates/config/versions.cue`.
- **Prefer upstream component configuration APIs over flag mapping**:
  when the addon supports a `--config` file (e.g. cert-manager's
  ControllerConfiguration), expose it as a typed CUE schema rendered
  into a hash-named immutable ConfigMap so config changes roll the
  pods; the containers get only `--config`, and `extraArgs` remains the
  escape hatch (flags override the file).
- **VERSION file**: format `^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$`, excluded from
  the pushed artifact via `timoni.ignore`. The OCI registry is the release
  record — no git tags.
- **Module README**: H1 title, blank line, then a one-sentence description
  that links Timoni (https://timoni.sh) and the addon's upstream repository.
  That line becomes the OCI description annotation with the markdown links
  stripped to their text; it must not contain double quotes.
- **No Bash**: all automation logic lives in upengine as TypeScript
  commands; the Makefile and the GitHub workflows are single-command
  entrypoints only. External tools are invoked by argv (never through a
  shell), so upstream-controlled data can never become shell syntax.
- Tabs for indentation in CUE/Makefile (`make fmt` enforces it).
- Commit messages: short imperative summary, signed off (`git commit -s`).
- GitHub Actions are pinned to commit SHAs (with a `# vX.Y.Z` comment).
- Always run `make fmt` and `make vet` before committing.

## CUE pitfalls

Recurring template-authoring traps; the error usually appears far
from its cause:

- **`#MetaComponent` names are concrete, not defaults.** Unifying the
  metadata with a different concrete name is "conflicting values", and
  unifying two name fields that each carry a *different default* is an
  "incomplete value" that only plain `build` reports — vet with debug
  values can pass. Objects with user-overridable names
  (ServiceAccounts, Services, Secrets) need hand-built metadata, or
  defaults that resolve to the same string.
- **Embedded-struct fields are invisible to sibling comprehensions.**
  Inside `#X: {#Workload, _guard: [...]}` the guard cannot reference
  the embedded `extraArgs` ("reference not found") — alias the struct
  (`#X: A={...}`) and use `A.extraArgs`.
- **k8s gen schemas type `[]byte` fields as CUE `bytes`.** For
  `Secret.data` use `stringData` instead; for fields with no string
  alternative (webhook `caBundle`) wrap the base64 *text* as a bytes
  literal — `'\(base64.Encode(null, s))'` — since raw bytes render
  verbatim and the API server rejects them.
- **Top-level embedded disjunctions in `#Config` break cross-field
  references** — model variants as optional fields plus a `_guard`
  list that yields an error string for invalid combinations.
- **`{_config: _config}` is a self-cycle** — use `let cfg = _config`
  when passing config into composed objects.
- **CUE package names cannot contain dashes**: a component named
  `admission-controller` lives in `templates/admission` with
  `package admission`; the dashed name stays in labels and object
  names.

## Prerequisites

Install the toolchain with `make tools` (uses `Brewfile`): `cue`, `kubectl`,
`kind`, `timoni`, `bun`.

If the local Docker credential helper blocks anonymous registry pulls (e.g.
`make update-shared-schemas` failing with `error getting credentials`), point
`DOCKER_CONFIG` at a directory without a Docker config, such as the repo
root:

```bash
DOCKER_CONFIG=$PWD make update-shared-schemas
```

Never do this for push operations (`make push-mod`) — those need the real
credentials.

## Common commands

| Command | Purpose |
|---|---|
| `make fmt` / `make fmt-check` | Format CUE / verify formatting (CI) |
| `make lint-modules` | Validate module metadata against sources.ts |
| `make vet` | Vet every module (validates rendered resources) |
| `make build MODULE=<m>` | Render a module's manifests for inspection |
| `make cluster-up` / `make cluster-down` | Create / delete the local `timoni-test` kind cluster for e2e |
| `make e2e MODULE=<m>` | Install, verify and uninstall a module on the current cluster |
| `make status` | Local VERSION vs published GHCR versions, all modules |
| `make list-mod MODULE=<m>` | List a module's published versions |
| `make push-mod MODULE=<m>` | Publish one module to GHCR (CI does this) |
| `make update-shared-schemas` | Refresh the shared Timoni, Kubernetes and CRD schemas |
| `make sync [MODULE=<m>] [FORCE=1]` | Sync modules with their upstream releases |
| `make deps` / `make lint` / `make test` | Install, typecheck and test the upengine |

## Publishing model

`push.yaml` runs on every merge to `main`: it loops over all modules,
compares each `VERSION` against the module's GHCR tags (`timoni mod list`)
and publishes only missing versions — idempotent, safe to rerun, failures
in one module don't block the others. GHCR answers `DENIED` for
not-yet-created packages, so first publishes log a warning then push.

## Adding a new module

`modules/metrics-server` is the blueprint — copy its structure and
conventions when onboarding a new addon (`modules/cert-manager` is the
blueprint for multi-deployment addons):

1. Create `modules/<name>` following the blueprint: `cue.mod/module.cue`
   (`timoni.sh/<name>`), relative symlinks for `cue.mod/pkg/timoni.sh`,
   `cue.mod/gen/k8s.io` and the shared CRD schema groups the templates
   import (see [schemas/README.md](schemas/README.md)). When the addon
   ships CRDs, declare the upstream manifest path as `crds` in the
   `sources.ts` entry added in step 7 — the sync engine generates
   `templates/crds.cue`, and the
   curated `#Instance` includes its objects behind a `crds.install` value
   (see `modules/external-dns`).
2. **Golden rule: the values API must cover every config option offered by
   the upstream chart/manifests.** Clone the upstream repo, read the chart's
   `values.yaml` and every template, and map each option to a typed CUE
   field. Helm-only mechanics (lookup, generated certs, PSP) become
   documented deviations in the module README.
3. Image defaults live in the generated `templates/versions.cue`
   (`#defaultImages`), referenced as defaults from `#Config` — never
   hardcode tags in hand-written CUE. `values.cue` stays empty.
4. `debug_values.cue` must enable every optional object so
   `timoni mod vet --debug` validates all templates against their schemas.
5. Write `VERSION` (`<upstream>-0`), the README description line, and the
   full values documentation. `make lint-modules` enforces the README
   shape (`upengine/src/readme.ts` is the authoritative rule set):
   the description must match
   `A [Timoni](https://timoni.sh) module for deploying [<name>](<url>), <clause>.`
   (extra words may sit between the link and the comma), and the
   `## Prerequisites` section must start with the bullets
   `- Kubernetes <major>.<minor>+` and
   `- [Timoni](https://timoni.sh/install/) 0.31+`, in that order.
   Place a `## Version` heading with `<!-- versions:start -->` /
   `<!-- versions:end -->` markers after the description — the sync in
   step 8 renders the module version and container images between the
   markers and fails without them; lint checks the markers once the
   module has a history manifest. The
   README is user-facing: never mention the upstream Helm chart or
   differences from it, avoid shell heredocs in the examples (show a
   `values.cue` file instead), and include a Timoni bundle example that
   has been applied on a real cluster.
6. Enable the Timoni core health checks
   (`timoni: healthChecks: timoniv1.#HealthCheckLibrary.all` in
   `healthchecks.cue`) and add condition-based checks for any custom
   resources the module creates (e.g. cert-manager Certificate).
7. Add the module's entry to `upengine/config/sources.ts` (the upstream
   repo, release tag glob, manifests input or release image, optional
   `crds` manifest path, and the `e2e` namespace and verify check) plus a
   `test/bundles/<name>/bundle.cue` with the e2e install values — the
   bundle reads the module url and version from `E2E_MODULE_URL` /
   `E2E_MODULE_VERSION` runtime env vars set by the engine. An optional
   `test/bundles/<name>/fixtures.yaml` is applied after install and
   deleted before uninstall, for resources the verify check depends on
   (e.g. a custom resource the addon must reconcile). When the module
   has a runtime dependency (e.g. cert-manager for a webhook
   certificate), the bundle installs the published dependency modules
   first from `oci://ghcr.io/timonish/modules/<dep>` at `latest` —
   Timoni applies the instances in order — and `e2e.sweepMatch` lists
   substrings covering the dependencies' leftovers (see
   `test/bundles/trust-manager` and
   `test/bundles/vertical-pod-autoscaler`). The e2e workflow
   runs install/verify/uninstall per changed module against a kind
   cluster; the uninstall sweep fails on leftovers among the
   cluster-scoped kinds (ClusterRoles/Bindings, APIServices, CRDs,
   webhook configurations, admission policies) plus Roles and
   RoleBindings, matched by the module name, its dash-stripped form
   and `sweepMatch` (`upengine/src/e2e.ts` is the authoritative list).
8. Run `make sync MODULE=<name>` — the first sync resolves the upstream
   release, writes the generated files for the module's layout plus
   `VERSION`, vets and builds the module, then renders the module
   README version section, writes the history manifest and updates the
   catalog README row. The README markers from step 5 must exist
   before this runs. A vet/build failure rolls back the generated
   files — deleting them, `VERSION` included, when git does not track
   them yet, so recreate `VERSION` before retrying; failures after
   that point (e.g. missing README markers) leave the files in place.
9. `git add` the new files (`make lint-modules` reads the module list
   from `git ls-files`), then run `make fmt lint-modules vet`,
   `make build MODULE=<name>`, and `make e2e MODULE=<name>` against a
   local kind cluster (`make cluster-up` creates one from
   `test/cluster/kind.yaml`).
10. After the first publish: confirm the new `modules/<name>` package is
    publicly listable (`timoni mod list`) and linked to this repository —
    GHCR packages inherit the repo visibility, no manual flip is needed.

## Releasing a module-only fix

Upstream bumps are fully automated. For a change to the module itself
(new values, templates, docs), bump the build suffix and refresh the
provenance so the next sync run stays idempotent:

1. Edit the module, then set `modules/<name>/VERSION` to `<upstream>-<n+1>`.
2. Run `make sync MODULE=<name> FORCE=1` — the forced re-sync keeps the
   build suffix (while the upstream release is unchanged; a newer
   release resets it to `-0`) and regenerates the generated files
   (`versions.cue`, `crds.cue`), the history manifest, the module
   README version section and the catalog README table.
3. Open a PR; after the merge, `push.yaml` publishes the new version.

## Self improving

This file is the durable channel between work sessions — agent memory
is not. When a session surfaces new durable guidance, fold it in as
part of that session's PR:

- new CUE traps go to [CUE pitfalls](#cue-pitfalls);
- new or changed rules go to [Conventions](#conventions);
- workflow corrections (a step that was missing, wrong or
  order-sensitive) amend the step they belong to;
- new engine capabilities used by a module (a `sources.ts` input, an
  e2e mechanism) get mentioned where a future onboarding would need
  them.

Write generalized guidance, not session narrative — state the rule and
the symptom of breaking it, never the story of discovering it. Do not
record what git history, the code or the blueprints already show, and
prune entries that stopped being true rather than stacking updates.
When a rule is enforced by code, point at the enforcing file instead
of restating its logic — prose copies of code are where this file
drifts.
