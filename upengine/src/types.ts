// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

/** An OCI image reference split into its parts, as rendered in versions.cue. */
export interface ImageRef {
  repository: string;
  tag: string;
  digest: string;
}

/**
 * How the tag of one image in a module's versions.cue is resolved:
 * - `container`: extracted from the module source's release manifests by
 *   container name;
 * - `url` + `releaseTag` + `repository`: tracked from another GitHub
 *   repository's releases, with the tag glob's literal prefix stripped from
 *   the release tag (`addon-resizer-1.8.24` with glob `addon-resizer-*`
 *   yields tag `1.8.24`); `repository` pins the OCI repository.
 * - `repository` alone: a release image — the upstream publishes it tagged
 *   with the release tag verbatim (`v0.21.0` release -> `:v0.21.0` image).
 */
export type ImageSource =
  | { container: string }
  | { url: string; releaseTag: string; repository: string }
  | { repository: string };

/** Where a module source's release manifests are fetched from. */
export type ManifestsInput = { releaseAsset: string } | { file: string };

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
}

/** One entry of upengine/config/sources.ts — a module's upstream declaration. */
export interface ModuleSource {
  /** Module name; must match a modules/<name> directory. */
  name: string;
  /** GitHub repository URL of the upstream project. */
  url: string;
  /** Release tag glob constraining version resolution (e.g. `v*`). */
  releaseTag?: string;
  /** Pin the upstream version instead of resolving the latest release. */
  version?: string;
  /** Release manifests location, required by `container` image sources. */
  manifests?: ManifestsInput;
  /** Path of the CRD manifest in the upstream repo, fetched at the pinned
   * commit and rendered into the generated templates/crds.cue. */
  crds?: { file: string };
  /** versions.cue image key -> tag resolution, in rendering order. */
  images: Record<string, ImageSource>;
  /** The module's end-to-end test definition. */
  e2e: E2eConfig;
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
  /** Images written to versions.cue. */
  images: Record<string, ImageRef>;
  /** Digest of the generated files (versions.cue + VERSION), used to detect
   * hand edits and corruption so the sync self-heals instead of skipping. */
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
