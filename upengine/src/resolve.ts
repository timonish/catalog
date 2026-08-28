// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { latestReleaseTag, listReleases, matchGlob, type Release } from "./github.ts";
import { parseImageRef } from "./manifests.ts";
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
 * The tag of an image versioned by an assignment in a repo file: a
 * Makefile-style `VARIABLE := value` or a Go-style `Variable = "value"`
 * constant. The value is either a bare version or a full image reference —
 * the reference's repository must then equal the declared one, so an
 * upstream registry move fails the sync instead of silently retagging a
 * different image. `+` and `~` are legal in Debian package versions but not
 * in OCI tags; the upstream release tooling maps them to `-` (`tr '+~' '-'`)
 * and the extracted tag mirrors that.
 */
export function fileVariableTag(
  contents: string,
  variable: string,
  file: string,
  repository: string,
): string {
  const match = contents.match(new RegExp(`^\\s*${variable}\\s*:?=\\s*(\\S+)\\s*$`, "m"));
  if (!match) {
    throw new Error(`variable '${variable}' not found in ${file}`);
  }
  // Go constants quote their value; Makefile assignments do not.
  const value = match[1]!.replace(/^(["'`])(.*)\1$/, "$2");
  // A bare version carries neither a repository nor a tag separator; a
  // registry-less reference (`envoy:v1`) is parsed as one and then fails
  // the repository check rather than pinning its name as the tag.
  if (!value.includes("/") && !value.includes(":")) {
    return value.replace(/[+~]/g, "-");
  }
  const ref = parseImageRef(value);
  if (ref.repository !== repository) {
    throw new Error(
      `variable '${variable}' in ${file} references '${ref.repository}', expected '${repository}'`,
    );
  }
  if (ref.tag === "") {
    throw new Error(`variable '${variable}' in ${file} references '${value}' without a tag`);
  }
  return ref.tag.replace(/[+~]/g, "-");
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

/** The argv resolving an image tag to its registry digest. */
export function artifactDigestArgv(ref: ImageRef): string[] {
  return ["timoni", "artifact", "digest", `oci://${ref.repository}:${ref.tag}`, "-o", "json"];
}

/** A repository with the Docker Hub alias timoni answers for `docker.io`. */
function canonicalRepository(repository: string): string {
  return repository.replace(/^(oci:\/\/)?docker\.io\//, "$1index.docker.io/");
}

/**
 * The digest in a `timoni artifact digest -o json` document, checked against
 * the repository and tag it was requested for so an answer for another image
 * can never pin the wrong digest. Docker Hub references are compared by
 * their canonical `index.docker.io` name, which is how timoni echoes them.
 */
export function parseArtifactDigest(stdout: string, ref: ImageRef): string {
  const entry: unknown = JSON.parse(stdout);
  if (typeof entry !== "object" || entry === null || Array.isArray(entry)) {
    throw new Error(`timoni artifact digest of ${ref.repository}:${ref.tag} did not print a JSON object`);
  }
  const { repository, tag, digest } = entry as { repository?: unknown; tag?: unknown; digest?: unknown };
  const answered = typeof repository === "string" ? canonicalRepository(repository) : "";
  if (answered !== `oci://${canonicalRepository(ref.repository)}` || tag !== ref.tag) {
    throw new Error(
      `timoni artifact digest of ${ref.repository}:${ref.tag} answered for '${String(repository)}:${String(tag)}'`,
    );
  }
  if (typeof digest !== "string" || digest === "") {
    throw new Error(`no digest resolved for ${ref.repository}:${ref.tag}`);
  }
  return digest;
}
