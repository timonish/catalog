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
| `modules/<name>/templates/versions.cue` | **Generated:** image repos/tags                                                                                                    |
| `modules/<name>/templates/crds.cue`     | **Generated:** cue-imported upstream CRDs                                                                                          |
| `schemas/`                              | Shared CUE module: single copy of the vendored `timoni.sh/core` and `k8s.io` schemas ([schemas/README.md](schemas/README.md))      |
| `upengine/`                             | Bun/TypeScript automation engine; `upengine/config/sources.ts` declares each module's upstream and e2e test                        |
| `upengine/history/`                     | **Generated:** per-module provenance manifests                                                                                     |
| `test/`                                 | kind cluster config and e2e fixtures                                                                                               |
| `.github/workflows/`                    | `test.yaml` (fmt+vet+lint), `e2e.yaml` (kind), `push.yaml` (idempotent GHCR publish), `update-catalog.yaml` (daily sync)           |
| `Makefile`                              | Entrypoints for all of the above. `Brewfile` — required CLIs                                                                       |

## Conventions

- **Never hand-edit generated files**: `templates/versions.cue`,
  `templates/crds.cue`, `modules/<name>/cue.mod/gen/<group>` CRD schemas,
  `schemas/cue.mod/gen/**`, `upengine/history/` and the README modules table
  are owned by the sync engine / vendoring targets. Hand-written CUE
  references `versions.cue` for image tags so routine bumps never touch
  curated files.
- **Shared schemas are symlinked, never copied**: each module's
  `cue.mod/gen/k8s.io`, `cue.mod/gen/monitoring.coreos.com`,
  `cue.mod/gen/cert-manager.io` and `cue.mod/pkg/timoni.sh` are relative
  symlinks into `schemas/`. Pushes use `--resolve-symlinks` (set in
  `make push-mod`). Addon-specific CRD schemas are the opposite: vendored by
  the sync engine as regular files into the module that needs them — never
  into `schemas/`.
- **VERSION file**: format `^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$`, excluded from
  the pushed artifact via `timoni.ignore`. The OCI registry is the release
  record — no git tags.
- **Module README**: H1 title, blank line, then a one-sentence description.
  That line becomes the OCI description annotation; it must not contain
  double quotes.
- **No Bash**: all automation logic lives in upengine as TypeScript
  commands; the Makefile and the GitHub workflows are single-command
  entrypoints only. External tools are invoked by argv (never through a
  shell), so upstream-controlled data can never become shell syntax.
- Tabs for indentation in CUE/Makefile (`make fmt` enforces it).
- Commit messages: short imperative summary, signed off (`git commit -s`).
- GitHub Actions are pinned to commit SHAs (with a `# vX.Y.Z` comment).
- Always run `make fmt` and `make vet` before committing.

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
conventions when onboarding a new addon:

1. Create `modules/<name>` following the blueprint: `cue.mod/module.cue`
   (`timoni.sh/<name>`), relative symlinks for `cue.mod/gen/k8s.io`,
   `cue.mod/gen/monitoring.coreos.com`, `cue.mod/gen/cert-manager.io` and
   `cue.mod/pkg/timoni.sh` (see [schemas/README.md](schemas/README.md));
   addon-specific CRD schemas vendored into the module with
   `timoni mod vendor crd` and pruned to the kinds the templates import.
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
   full values documentation. The README is user-facing: never mention the
   upstream Helm chart or differences from it, avoid shell heredocs in the
   examples (show a `values.cue` file instead), and include a Timoni bundle
   example that has been applied on a real cluster.
6. Enable the Timoni core health checks
   (`timoni: healthChecks: timoniv1.#HealthCheckLibrary.all` in
   `healthchecks.cue`) and add condition-based checks for any custom
   resources the module creates (e.g. cert-manager Certificate).
7. Add the module's entry to `upengine/config/sources.ts`: the upstream
   repo, release tag glob, manifests input, image tracking, and the `e2e`
   config (namespace, install values, verify check). The e2e workflow runs
   install/verify/uninstall per changed module against a kind cluster, and
   the uninstall sweep fails on any leftover resources.
8. Run `make fmt lint-modules vet`, `make build MODULE=<name>`, and
   `make e2e MODULE=<name>` against a local kind cluster.
9. After the first publish: on ghcr.io, flip the new `modules/<name>`
   package to **Public** and confirm it is linked to this repository
   (one-time, needs package admin).

## Releasing a module-only fix

Upstream bumps are fully automated. For a change to the module itself
(new values, templates, docs), bump the build suffix and refresh the
provenance so the next sync run stays idempotent:

1. Edit the module, then set `modules/<name>/VERSION` to `<upstream>-<n+1>`.
2. Run `make sync MODULE=<name> FORCE=1` — the forced re-sync keeps the
   build suffix, regenerates the history manifest and the README table.
3. Open a PR; after the merge, `push.yaml` publishes the new version.
