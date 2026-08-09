// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { isContainerImage, isTrackedImage, repoOf } from "./config.ts";
import { commitSha, downloadText, fetchRepoFile, findReleaseAsset } from "./github.ts";
import { extractImages, parseImageRef } from "./manifests.ts";
import { parseModuleVersion, resolveTag, semverOf, trackedImageTag } from "./resolve.ts";
import {
  generatedFilesDigest,
  restoreModuleFiles,
  verifyModule,
  writeModuleFiles,
} from "./codegen.ts";
import { readHistory, writeHistory } from "./history.ts";
import { updateModuleReadme } from "./readme.ts";
import { MODULES_DIR } from "./paths.ts";
import type { ImageRef, ModuleSource, SyncChange } from "./types.ts";

export interface SyncResult {
  /** null when the module is already up to date. */
  change: SyncChange | null;
}

/**
 * Syncs one module against its upstream: resolves the latest release,
 * compares it to the VERSION file, and on a new release regenerates the
 * module's versions.cue and VERSION, runs the vet/build guards, and records
 * the provenance manifest. The sync only ever writes generated files.
 *
 * Skip conditions are self-healing: staying at the current version requires
 * the history manifest to exist and its recorded digest to match the
 * generated files on disk — a hand-edited versions.cue or missing history
 * triggers a re-sync of the same release instead of being skipped forever.
 * An upstream release older than the current version is rejected (release
 * deletion or a config mistake must never downgrade a module unattended).
 */
export async function syncModule(source: ModuleSource, force: boolean): Promise<SyncResult> {
  const moduleDir = join(MODULES_DIR, source.name);
  const versionFile = Bun.file(join(moduleDir, "VERSION"));
  if (!(await versionFile.exists())) {
    throw new Error(`modules/${source.name}/VERSION not found`);
  }
  const current = parseModuleVersion(await versionFile.text());

  const repo = repoOf(source.url);
  const tag = await resolveTag(repo, source.releaseTag, source.version);
  const upstream = semverOf(tag);
  if (!/^\d+\.\d+\.\d+$/.test(upstream)) {
    throw new Error(`resolved tag '${tag}' of ${repo} carries no release semver`);
  }

  const order = Bun.semver.order(upstream, current.upstream);
  if (order < 0 && source.version === undefined) {
    throw new Error(
      `resolved release ${upstream} of ${repo} is older than the module version ${current.upstream}; refusing to downgrade`,
    );
  }
  if (order === 0 && !force && (await isIntact(source.name))) {
    return { change: null };
  }

  // A new upstream release resets the build suffix; a re-sync of the
  // current release keeps the existing module version.
  const moduleVersion = order === 0 ? `${upstream}-${current.build}` : `${upstream}-0`;

  // The tag is pinned to a commit before any input is fetched, so the
  // provenance record cannot diverge from the consumed input when a
  // mutable tag moves mid-sync.
  const commit = await commitSha(repo, tag);
  const images = await resolveImages(source, repo, tag, commit);
  const crdManifest =
    source.crds === undefined ? null : await fetchRepoFile(repo, commit, source.crds.file);

  try {
    await writeModuleFiles(source.name, images, moduleVersion, crdManifest);
    await verifyModule(source.name);
  } catch (err) {
    await restoreModuleFiles(source.name, source.crds !== undefined).catch(() => {});
    throw err;
  }
  const history = {
    name: source.name,
    repo,
    tag,
    commit,
    moduleVersion,
    images,
    generatedDigest: await generatedFilesDigest(source.name),
    updatedAt: new Date().toISOString(),
  };
  // The README version section renders before the history is recorded, so
  // a failure here (e.g. missing markers) leaves a stale history and the
  // next run re-syncs instead of skipping.
  await updateModuleReadme(history);
  await writeHistory(history);

  return {
    change: {
      name: source.name,
      repo,
      tag,
      prevModuleVersion: `${current.upstream}-${current.build}`,
      moduleVersion,
      images,
    },
  };
}

/** Whether the module's generated files match the recorded provenance. */
async function isIntact(name: string): Promise<boolean> {
  const history = await readHistory(name);
  if (history === null) {
    return false;
  }
  return (await generatedFilesDigest(name)) === history.generatedDigest;
}

/** Resolves every image of a module at the given upstream release tag. */
async function resolveImages(
  source: ModuleSource,
  repo: string,
  tag: string,
  commit: string,
): Promise<Record<string, ImageRef>> {
  const entries = Object.entries(source.images);
  let manifestImages: Map<string, string> | null = null;
  if (entries.some(([, i]) => isContainerImage(i))) {
    manifestImages = extractImages(await fetchManifests(source, repo, tag, commit));
  }

  const images: Record<string, ImageRef> = {};
  for (const [key, imageSource] of entries) {
    if (isContainerImage(imageSource)) {
      const ref = manifestImages!.get(imageSource.container);
      if (ref === undefined) {
        const known = [...manifestImages!.keys()].join(", ") || "none";
        throw new Error(
          `container '${imageSource.container}' not found in the ${repo}@${tag} manifests (containers: ${known})`,
        );
      }
      images[key] = parseImageRef(ref);
    } else if (isTrackedImage(imageSource)) {
      const trackedRepo = repoOf(imageSource.url);
      const trackedTag = await resolveTag(trackedRepo, imageSource.releaseTag, undefined);
      images[key] = {
        repository: imageSource.repository,
        tag: trackedImageTag(trackedTag, imageSource.releaseTag),
        digest: "",
      };
    } else {
      // A release image: the upstream tags it with the release tag verbatim.
      images[key] = { repository: imageSource.repository, tag, digest: "" };
    }
  }
  return images;
}

async function fetchManifests(
  source: ModuleSource,
  repo: string,
  tag: string,
  commit: string,
): Promise<string> {
  const input = source.manifests!;
  if ("releaseAsset" in input) {
    const asset = await findReleaseAsset(repo, tag, input.releaseAsset);
    return downloadText(asset.browser_download_url);
  }
  // Repo files are fetched at the pinned commit, not the mutable tag.
  return fetchRepoFile(repo, commit, input.file);
}
