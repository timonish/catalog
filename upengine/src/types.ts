// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

/** An OCI image reference split into its parts, as rendered in images.cue. */
export interface ImageRef {
  repository: string;
  tag: string;
  digest: string;
}

/**
 * How the tag of one image in a module's images.cue is resolved:
 * - `container`: extracted from the module source's release manifests by
 *   container name;
 * - `url` + `releaseTag` + `repository`: tracked from another GitHub
 *   repository's releases, with the tag glob's literal prefix stripped from
 *   the release tag (`addon-resizer-1.8.24` with glob `addon-resizer-*`
 *   yields tag `1.8.24`); `repository` pins the OCI repository.
 * - `file` + `variable` + `repository`: read from a Makefile-style
 *   `VARIABLE := value` assignment in a repo file fetched at the pinned
 *   release commit, for images versioned independently of the releases and
 *   without tags of their own (the trust-manager Debian trust package);
 *   `+` and `~` are mapped to `-` as in the upstream release tooling.
 * - `repository` alone: a release image — the upstream publishes it tagged
 *   with the release tag verbatim (`v0.21.0` release -> `:v0.21.0` image).
 */
export type ImageSource =
  | { container: string }
  | { url: string; releaseTag: string; repository: string }
  | { file: string; variable: string; repository: string }
  | { repository: string };

/** One image declaration: its tag resolution plus where the generated
 * defaults land in the module's values. */
export type ImageDecl = ImageSource & {
  /** Dotted values path of the image object the defaults are written to
   * in the generated images.cue (e.g. `controller.image`). Defaults to
   * `image`; multi-image modules must declare distinct paths. */
  path?: string;
};

/** Where a module source's release manifests are fetched from. */
export type ManifestsInput = { releaseAsset: string } | { file: string };

/** One upstream CRD manifest location — a repo file fetched at the pinned
 * commit, or an asset of the resolved release. */
export type CrdInput = { file: string } | { releaseAsset: string };

/**
 * The upstream CRD manifests of a module: a single input rendered into the
 * generated templates/crds.cue, or one input per release channel rendered
 * into templates/crds_<channel>.cue each (the module then selects a channel
 * through a value). Every manifest is normalized before import; by default
 * only CustomResourceDefinition documents are kept and packaging labels are
 * stripped:
 * - `keepKinds`: additional document kinds to retain (e.g. the Gateway API
 *   ValidatingAdmissionPolicy shipped with the CRDs);
 * - `keepLabels`: preserve `metadata.labels` — for upstreams whose CRD
 *   labels are semantic rather than packaging noise.
 */
export type CrdsConfig = ({ channels: Record<string, CrdInput> } | CrdInput) & {
  keepKinds?: string[];
  keepLabels?: boolean;
};

/** An argv command retried until it exits 0. Never interpreted by a shell. */
export interface RetriedCheck {
  argv: string[];
  /** Attempts before giving up; defaults to 30. */
  attempts?: number;
  /** Delay between attempts in seconds; defaults to 10. */
  delaySeconds?: number;
}

/** The end-to-end test of a module, run against a kind cluster. The
 * install values live in the module's test/bundles/<name>/bundle.cue. */
export interface E2eConfig {
  /** Namespace the instance is applied to; must match the test bundle. */
  namespace: string;
  /** Readiness check proving the addon works (timoni already waits for
   * resource health; this checks the addon's actual function). */
  verify: RetriedCheck;
  /** Extra substrings the uninstall leftover sweep matches resource names
   * against, for modules whose cluster-scoped objects do not carry the
   * module name (e.g. `gateway.networking` for the Gateway API CRDs). */
  sweepMatch?: string[];
  /** `false` excludes the module from the GitHub Actions e2e matrix; the
   * test stays runnable locally via `make e2e MODULE=<name>`. */
  ci?: false;
}

/** One upengine/config/sources/<name>.ts file — a module's upstream declaration. */
export interface ModuleSource {
  /** Module name; must match a modules/<name> directory. */
  name: string;
  /** GitHub repository URL of the upstream project. */
  url: string;
  /** URL of the upstream config surface — a Helm chart directory or the
   * plain manifests — the module holds parity with. Informational only,
   * never consumed by the engine: read it when onboarding (rendered-output
   * parity) and when reviewing upstream drift for new config surface
   * (see docs/internal/maintenance.md). */
  parityTarget: string;
  /** Release tag glob constraining version resolution (e.g. `v*`). */
  releaseTag?: string;
  /** Pin the upstream version instead of resolving the latest release. */
  version?: string;
  /** Release manifests location, required by `container` image sources. */
  manifests?: ManifestsInput;
  /** The upstream CRD manifests rendered into the generated crds files. */
  crds?: CrdsConfig;
  /** images.cue image key -> declaration, in rendering order. Absent
   * for CRDs-only modules, which generate no images.cue at all. */
  images?: Record<string, ImageDecl>;
  /** The module's end-to-end test definition. */
  e2e: E2eConfig;
}

/** One catalog release of a module. */
export interface ModuleRelease {
  version: string;
  releasedAt: string;
}

/** Per-module provenance manifest written to upengine/history/<name>.json. */
export interface HistoryEntry {
  name: string;
  /** Upstream repository (owner/name). */
  repo: string;
  /** Resolved upstream release tag (the git ref manifests were fetched at). */
  tag: string;
  /** Commit SHA the tag pointed at during the sync. */
  commit: string;
  /** Module version written to the VERSION file. */
  moduleVersion: string;
  /** Every version released by the catalog and when, newest first — the
   * release record, listing tags without querying the registry. Full
   * details are kept for the latest version only. Publication happens
   * post-merge, so a failed publish is behind this record until the
   * idempotent push workflow retries it. */
  moduleReleases: ModuleRelease[];
  /** Images written to images.cue. */
  images: Record<string, ImageRef>;
  /** Digest of the raw upstream CRD manifest consumed by the sync;
   * release assets are mutable, so this identifies the exact input. */
  crdsDigest?: string;
  /** Per-channel digests of the raw upstream CRD manifests, for modules
   * declaring `crds.channels`. */
  crdsDigests?: Record<string, string>;
  /** Digest of the generated files (images.cue, VERSION and crds.cue
   * when present), used to detect hand edits and corruption so the sync
   * self-heals instead of skipping. */
  generatedDigest: string;
  updatedAt: string;
}

/** A module bumped during this run, for the PR body. */
export interface SyncChange {
  name: string;
  repo: string;
  tag: string;
  prevModuleVersion: string;
  moduleVersion: string;
  images: Record<string, ImageRef>;
}

/** A module that failed during this run. */
export interface SyncFailure {
  name: string;
  message: string;
}
