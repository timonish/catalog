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
| `modules/<name>/images.cue`             | **Generated:** image defaults (repo/tag/digest) written into the values                                                            |
| `modules/<name>/templates/crds.cue`     | **Generated:** cue-imported upstream CRDs                                                                                          |
| `schemas/`                              | Shared CUE module: single copy of the vendored `timoni.sh/core` and `k8s.io` schemas ([schemas/README.md](schemas/README.md))      |
| `upengine/`                             | Bun/TypeScript automation engine; `upengine/config/sources/<name>.ts` declares each module's upstream, parity target and e2e test |
| `upengine/history/`                     | **Generated:** per-module provenance manifests                                                                                     |
| `test/`                                 | kind cluster config; `test/bundles/<name>/bundle.cue` — per-module e2e install bundle                                              |
| `docs/internal/`                        | Task-scoped guides for maintainers and agents (see [Guides](#guides)); not user-facing                                             |
| `.github/workflows/`                    | `test.yaml` (fmt+vet+lint), `e2e.yaml` (kind), `push.yaml` (idempotent GHCR publish), `update-catalog.yaml` (daily sync)           |
| `Makefile`                              | Entrypoints for all of the above. `Brewfile` — required CLIs                                                                       |

## Guides

Task-scoped guidance lives in `docs/internal/`. Before starting one of
these tasks, read the matching guide in full:

- Onboarding a new addon module →
  [docs/internal/onboarding.md](docs/internal/onboarding.md)
- Writing or editing CUE templates →
  [docs/internal/cue-authoring.md](docs/internal/cue-authoring.md)
- Designing or changing module values (goals, hardening standards,
  unified API surface) →
  [docs/internal/values-standard.md](docs/internal/values-standard.md)
- Releasing a module-only fix, the publishing model, reviewing upstream
  parity drift →
  [docs/internal/maintenance.md](docs/internal/maintenance.md)

## Conventions

- **Never hand-edit generated files**: `images.cue`,
  `templates/crds.cue`, `schemas/cue.mod/gen/**`, `upengine/history/`, the
  catalog README modules table and the version section between the
  `<!-- versions:start -->` markers in each module README are owned by the
  sync engine / vendoring targets. The generated `images.cue` writes the
  image defaults into the values at each image's declared path, so
  routine bumps never touch curated files and hand-written CUE never
  hardcodes tags.
- **Shared schemas are symlinked, never copied**: each module's
  `cue.mod/pkg/timoni.sh`, `cue.mod/gen/k8s.io` and the CRD schema groups
  its templates import (`monitoring.coreos.com`, `cert-manager.io`) are
  relative symlinks into `schemas/`. Pushes use `--resolve-symlinks` (set
  in `make push-mod`).
- **VERSION file**: format `^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$`, excluded from
  the pushed artifact via `timoni.ignore`. The OCI registry is the release
  record — no git tags.
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
| `make lint-modules` | Validate module metadata against the sources config |
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

## Self improving

This file and the guides in `docs/internal/` are the durable channel
between work sessions — agent memory is not. When a session surfaces
new durable guidance, fold it in as part of that session's PR, routed
by topic:

- a new CUE learning → `docs/internal/cue-authoring.md`;
- an onboarding step that was missing, wrong or order-sensitive →
  `docs/internal/onboarding.md`;
- a values API shape or hardening decision →
  `docs/internal/values-standard.md`;
- a release, publishing or parity-review correction →
  `docs/internal/maintenance.md`;
- a rule that applies to every session (layout, generated files,
  tooling, commit hygiene) → this file;
- new engine capabilities used by a module (a module source input, an
  e2e mechanism) get mentioned in the guide where a future onboarding
  would need them.

Write generalized guidance, not session narrative — state the rule and
the symptom of breaking it, never the story of discovering it. Do not
record what git history, the code or the blueprints already show, and
prune entries that stopped being true rather than stacking updates.
When a rule is enforced by code, point at the enforcing file instead
of restating its logic — prose copies of code are where this file
drifts.
