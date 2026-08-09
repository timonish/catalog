// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { repoOf } from "./config.ts";
import { commitSha, downloadText, fetchRepoFile, findReleaseAsset } from "./github.ts";
import { extractImages, parseImageRef } from "./manifests.ts";
import { parseModuleVersion, resolveTag, semverOf, trackedImageTag } from "./resolve.ts";
import { writeModuleFiles, verifyModule } from "./codegen.ts";
import { writeHistory } from "./history.ts";
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

  if (upstream === current.upstream && !force) {
    return { change: null };
  }

  // A new upstream release resets the build suffix; a forced re-sync of the
  // current release keeps the existing module version.
  const moduleVersion = upstream === current.upstream ? `${upstream}-${current.build}` : `${upstream}-0`;

  const images = await resolveImages(source, repo, tag);
  await writeModuleFiles(source.name, images, moduleVersion);
  await verifyModule(source.name);
  await writeHistory({
    name: source.name,
    repo,
    tag,
    commit: await commitSha(repo, tag),
    moduleVersion,
    images: Object.fromEntries(images),
    updatedAt: new Date().toISOString(),
  });

  return {
    change: {
      name: source.name,
      repo,
      tag,
      prevModuleVersion: `${current.upstream}-${current.build}`,
      moduleVersion,
      images: Object.fromEntries(images),
    },
  };
}

/** Resolves every image of a module at the given upstream release tag. */
async function resolveImages(
  source: ModuleSource,
  repo: string,
  tag: string,
): Promise<Map<string, ImageRef>> {
  let manifestImages: Map<string, string> | null = null;
  if ([...source.images.values()].some((i) => i.kind === "container")) {
    manifestImages = extractImages(await fetchManifests(source, repo, tag));
  }

  const images = new Map<string, ImageRef>();
  for (const [key, imageSource] of source.images) {
    if (imageSource.kind === "container") {
      const ref = manifestImages!.get(imageSource.container);
      if (ref === undefined) {
        const known = [...manifestImages!.keys()].join(", ") || "none";
        throw new Error(
          `container '${imageSource.container}' not found in the ${repo}@${tag} manifests (containers: ${known})`,
        );
      }
      images.set(key, parseImageRef(ref));
    } else {
      const trackedRepo = repoOf(imageSource.url);
      const trackedTag = await resolveTag(trackedRepo, imageSource.releaseTag, undefined);
      images.set(key, {
        repository: imageSource.repository,
        tag: trackedImageTag(trackedTag, imageSource.releaseTag),
        digest: "",
      });
    }
  }
  return images;
}

async function fetchManifests(source: ModuleSource, repo: string, tag: string): Promise<string> {
  const input = source.manifests!;
  if (input.kind === "releaseAsset") {
    const asset = await findReleaseAsset(repo, tag, input.asset);
    return downloadText(asset.browser_download_url);
  }
  return fetchRepoFile(repo, tag, input.path);
}
