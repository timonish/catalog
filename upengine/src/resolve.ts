// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { latestReleaseTag, listReleases, matchGlob, type Release } from "./github.ts";
import type { ImageRef } from "./types.ts";

/**
 * Resolves the upstream release tag a module should track: the explicit pin
 * when set, the highest-semver release matching the tag glob when one is
 * declared, otherwise the repo's latest release.
 */
export async function resolveTag(
  repo: string,
  releaseTag: string | undefined,
  pin: string | undefined,
): Promise<string> {
  if (pin !== undefined) {
    return pin;
  }
  if (releaseTag !== undefined) {
    return pickLatestRelease(await listReleases(repo), releaseTag);
  }
  return latestReleaseTag(repo);
}

/**
 * Picks the highest-semver release tag matching a glob, skipping drafts and
 * prereleases. Used when a repo interleaves unrelated release tags that
 * /releases/latest can surface (metrics-server ships
 * `metrics-server-helm-chart-*` next to `v*`; kubernetes/autoscaler ships
 * several component lines).
 *
 * The glob's wildcard must expand to a version: the character right after the
 * literal prefix has to be a digit, which rejects sibling tags whose wildcard
 * would instead start with another word (`…-chart-0.10.0`). Tags are ordered
 * by the semver embedded in the tag; highest semver, not most-recent, so a
 * backported patch of an older line never wins.
 */
export function pickLatestRelease(releases: Release[], pattern: string): string {
  const prefix = pattern.includes("*") ? pattern.slice(0, pattern.indexOf("*")) : pattern;
  const tags = releases
    .filter((r) => !r.draft && !r.prerelease && matchGlob(pattern, r.tag_name))
    .filter((r) => /^\d/.test(r.tag_name.slice(prefix.length)))
    // A tag whose embedded semver carries a prerelease suffix is skipped
    // even when the release is not flagged as such (an rc of a newer minor
    // with the flag forgotten would otherwise win and block updates).
    .filter((r) => /^\d+\.\d+\.\d+$/.test(semverOf(r.tag_name)))
    .map((r) => r.tag_name);
  if (tags.length === 0) {
    throw new Error(`no release tag matches '${pattern}'`);
  }
  tags.sort((a, b) => Bun.semver.order(semverOf(a), semverOf(b)));
  return tags.at(-1)!;
}

/** The semver embedded in a release tag (`addon-resizer-1.8.24` → `1.8.24`). */
export function semverOf(tag: string): string {
  return tag.match(/\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?/)?.[0] ?? tag;
}

/**
 * The tag of an image tracked from another repo's releases: the release tag
 * with the glob's literal prefix stripped (`addon-resizer-1.8.24` with glob
 * `addon-resizer-*` → `1.8.24`, `v1.2.3` with glob `v*` → `1.2.3` — the
 * OCI tag convention is declared by the glob itself).
 */
export function trackedImageTag(tag: string, pattern: string): string {
  const prefix = pattern.includes("*") ? pattern.slice(0, pattern.indexOf("*")) : "";
  return tag.startsWith(prefix) ? tag.slice(prefix.length) : tag;
}

/**
 * The module version parts of a VERSION file value: `0.8.0-0` →
 * { upstream: "0.8.0", build: 0 }.
 */
export function parseModuleVersion(value: string): { upstream: string; build: number } {
  const match = value.trim().match(/^(\d+\.\d+\.\d+)-(\d+)$/);
  if (!match) {
    throw new Error(`invalid module version '${value.trim()}', expected <major.minor.patch>-<build>`);
  }
  return { upstream: match[1]!, build: Number(match[2]!) };
}

/**
 * The argv resolving an image tag to its registry digest. The tag filter is
 * regex-escaped and anchored so an exact tag can never match its siblings
 * (`v1.2.3` must not match `v1.2.30`).
 */
export function artifactListArgv(ref: ImageRef): string[] {
  const filter = `^${ref.tag.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`;
  return ["timoni", "artifact", "list", `oci://${ref.repository}`, "--filter-regex", filter, "-o", "json"];
}

/** The digest of an image tag in a `timoni artifact list -o json` document. */
export function parseArtifactDigest(stdout: string, ref: ImageRef): string {
  const entries: unknown = JSON.parse(stdout);
  if (!Array.isArray(entries)) {
    throw new Error(`timoni artifact list of ${ref.repository} did not print a JSON array`);
  }
  const digests = entries
    .filter((entry) => entry?.tag === ref.tag)
    .map((entry): unknown => entry.digest);
  if (digests.length !== 1) {
    throw new Error(`tag '${ref.tag}' not found on ${ref.repository}`);
  }
  const digest = digests[0];
  if (typeof digest !== "string" || digest === "") {
    throw new Error(`no digest resolved for ${ref.repository}:${ref.tag}`);
  }
  return digest;
}
