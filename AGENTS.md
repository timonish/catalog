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
| `upengine/`                             | Bun/TypeScript sync engine; `upengine/config/sources.yaml` declares each module's upstream                                         |
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
  `cue.mod/gen/k8s.io` and `cue.mod/pkg/timoni.sh` are relative symlinks
  into `schemas/`. Pushes use `--resolve-symlinks` (set in `make push-mod`).
  CRD schemas are the opposite: per-addon, vendored by the sync engine as
  regular files into the module that needs them — never into `schemas/`.
- **VERSION file**: format `^[0-9]+\.[0-9]+\.[0-9]+-[0-9]+$`, excluded from
  the pushed artifact via `timoni.ignore`. The OCI registry is the release
  record — no git tags.
- **Module README**: H1 title, blank line, then a one-sentence description.
  That line becomes the OCI description annotation; it must not contain
  double quotes.
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
| `make vet` | Vet every module (validates rendered resources) |
| `make build MODULE=<m>` | Render a module's manifests for inspection |
| `make status` | Local VERSION vs published GHCR versions, all modules |
| `make list-mod MODULE=<m>` | List a module's published versions |
| `make push-mod MODULE=<m>` | Push one module to GHCR (CI does this) |
| `make update-shared-schemas` | Refresh the shared Timoni and Kubernetes API schemas |

## Publishing model

`push.yaml` runs on every merge to `main`: it loops over all modules,
compares each `VERSION` against the module's GHCR tags (`timoni mod list`)
and publishes only missing versions — idempotent, safe to rerun, failures
in one module don't block the others. GHCR answers `DENIED` for
not-yet-created packages, so first publishes log a warning then push.

## Adding a new module

1. Create `modules/<name>` following an existing module's structure; symlink
   the schemas (see [schemas/README.md](schemas/README.md)); write `VERSION`
   and the README description line.
2. Add the upstream entry to `upengine/config/sources.yaml`.
3. Run `make fmt vet` and `make build MODULE=<name>`.
4. After the first publish: on ghcr.io, flip the new `modules/<name>`
   package to **Public** and confirm it is linked to this repository
   (one-time, needs package admin).
