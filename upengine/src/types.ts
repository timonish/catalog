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
 * - `url` + `releaseTag`: tracked from another GitHub repository's releases,
 *   with the tag glob's literal prefix stripped from the release tag
 *   (`addon-resizer-1.8.24` with glob `addon-resizer-*` yields tag `1.8.24`);
 *   `repository` pins the OCI repository.
 */
export type ImageSource =
  | { kind: "container"; container: string }
  | { kind: "tracked"; url: string; releaseTag: string; repository: string };

/** Where a module source's release manifests are fetched from. */
export type ManifestsInput =
  | { kind: "releaseAsset"; asset: string }
  | { kind: "file"; path: string };

/** One entry of upengine/config/sources.yaml — a module's upstream declaration. */
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
  /** versions.cue image key -> tag resolution, in rendering order. */
  images: Map<string, ImageSource>;
}

export interface EngineConfig {
  sources: ModuleSource[];
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
