# Onboarding a new module

How to add a Kubernetes addon to the catalog. `modules/metrics-server`
is the structural blueprint — copy its structure and conventions
(`modules/cert-manager` is the blueprint for multi-deployment addons).
The blueprint governs *structure* only: the values API shape is governed
by [values-standard.md](values-standard.md), where upstream chart
coverage is the floor and the unified catalog surface is the shape.

## Module design rules

- **Upstream CRDs ship in the generated `templates/crds.cue`**: a module
  that installs CRDs declares the upstream manifest as `crds` in its
  module source — either a repo `file` fetched at the pinned commit
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
  Actions e2e matrix with `e2e: ci: false` in its module source (vet still
  gates it in CI; `make e2e` still runs it locally).
- **Multi-deployment addons use the multi-package layout** (see
  `modules/cert-manager`): one CUE package per component under
  `templates/<component>`, plus `templates/config` holding the values
  schema; component object names and labels come from the Timoni
  `#MetaComponent` convention. The module declares `layout: "packages"`
  in its module source, which moves the generated image defaults to
  `templates/config/versions.cue`.
- **Prefer upstream component configuration APIs over flag mapping**:
  when the addon supports a `--config` file (e.g. cert-manager's
  ControllerConfiguration), expose it as a typed CUE schema rendered
  into a hash-named immutable ConfigMap so config changes roll the
  pods; the containers get only `--config`, and `extraArgs` remains the
  escape hatch (flags override the file).
- **Module README**: H1 title, blank line, then a one-sentence
  description that links Timoni (https://timoni.sh) and the addon's
  upstream repository. That line becomes the OCI description annotation
  with the markdown links stripped to their text; it must not contain
  double quotes.

## Steps

1. Create `modules/<name>` following the blueprint: `cue.mod/module.cue`
   (`timoni.sh/<name>`), relative symlinks for `cue.mod/pkg/timoni.sh`,
   `cue.mod/gen/k8s.io` and the shared CRD schema groups the templates
   import (see [schemas/README.md](../../schemas/README.md)). When the
   addon ships CRDs, declare the upstream manifest path as `crds` in the
   module source added in step 7 — the sync engine generates
   `templates/crds.cue`, and the curated `#Instance` includes its
   objects behind a `crds.install` value (see `modules/external-dns`).
2. **Golden rule: the values API must cover every config option offered
   by the upstream parity target** (the `parityTarget` URL in the
   module source — the upstream chart, or the plain manifests when there
   is no chart). Clone the upstream repo, read the chart's `values.yaml`
   and every template, and map each option to a typed CUE field.
   Coverage is the floor, not the shape: common settings follow the
   unified surface in [values-standard.md](values-standard.md) even
   where the upstream lacks them, and Helm-only mechanics (lookup,
   generated certs, PSP) are excluded — record each exclusion as a
   comment in the module's source file, never in the
   user-facing README.
3. Image defaults live in the generated `templates/versions.cue`
   (`#defaultImages`), referenced as defaults from `#Config` — never
   hardcode tags in hand-written CUE. `values.cue` stays empty.
4. `debug_values.cue` must enable every optional object so
   `timoni mod vet --debug` validates all templates against their
   schemas.
5. Write `VERSION` (`<upstream>-0`), the README description line, and
   the full values documentation. `make lint-modules` enforces the
   README shape (`upengine/src/readme.ts` is the authoritative rule
   set): the description must match
   `A [Timoni](https://timoni.sh) module for deploying [<name>](<url>), <clause>.`
   (extra words may sit between the link and the comma), and the
   `## Prerequisites` section must start with the bullets
   `- Kubernetes <major>.<minor>+` and
   `- [Timoni](https://timoni.sh/install/) 0.31+`, in that order.
   Place a `## Version` heading with `<!-- versions:start -->` /
   `<!-- versions:end -->` markers after the description — the sync in
   step 8 renders the module version and container images between the
   markers and fails without them; lint checks the markers once the
   module has a history manifest. The README is user-facing: never
   mention the upstream Helm chart or differences from it, avoid shell
   heredocs in the examples (show a `values.cue` file instead), and
   include a Timoni bundle example that has been applied on a real
   cluster.
6. Enable the Timoni core health checks
   (`timoni: healthChecks: timoniv1.#HealthCheckLibrary.all` in
   `healthchecks.cue`) and add condition-based checks for any custom
   resources the module creates (e.g. cert-manager Certificate).
7. Add the module's source declaration as
   `upengine/config/sources/<name>.ts` exporting `source` — the loader
   picks up the file automatically, nothing else to edit (the upstream
   repo, `parityTarget` URL, release tag glob, manifests input or
   release image, optional `crds` manifest path, and the `e2e`
   namespace and verify check) plus a `test/bundles/<name>/bundle.cue`
   with the e2e install values — the bundle reads the module url and
   version from `E2E_MODULE_URL` / `E2E_MODULE_VERSION` runtime env
   vars set by the engine. An optional
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
