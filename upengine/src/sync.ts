// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { crdChannels, isContainerImage, isFileVariableImage, isTrackedImage, repoOf } from "./config.ts";
import { commitSha, downloadText, fetchRepoFile, findReleaseAsset } from "./github.ts";
import { extractImages, normalizeCrdManifest, parseImageRef } from "./manifests.ts";
import {
  artifactListArgv,
  fileVariableTag,
  parseArtifactDigest,
  parseModuleVersion,
  resolveTag,
  semverOf,
  trackedImageTag,
} from "./resolve.ts";
import {
  generatedFilesDigest,
  generatedFilesPresent,
  restoreModuleFiles,
  verifyModule,
  writeModuleFiles,
} from "./codegen.ts";
import { readHistory, recordRelease, writeHistory } from "./history.ts";
import { retryRun } from "./proc.ts";
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
  if (order === 0 && !force && (await isIntact(source))) {
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
  // The raw manifest digests are recorded as provenance: release assets
  // are mutable, so the history must identify the consumed inputs.
  const rawDigests: Record<string, string> = {};
  const crdManifests: Record<string, string> = {};
  for (const [channel, input] of Object.entries(crdChannels(source.crds))) {
    const raw =
      "releaseAsset" in input
        ? await downloadText((await findReleaseAsset(repo, tag, input.releaseAsset)).browser_download_url)
        : await fetchRepoFile(repo, commit, input.file);
    rawDigests[channel] = `sha256:${new Bun.CryptoHasher("sha256").update(raw).digest("hex")}`;
    crdManifests[channel] = normalizeCrdManifest(raw, {
      keepKinds: source.crds?.keepKinds,
      keepLabels: source.crds?.keepLabels,
    });
  }

  try {
    await writeModuleFiles(source.name, images, moduleVersion, crdManifests, source.layout);
    await verifyModule(source.name);
  } catch (err) {
    await restoreModuleFiles(source.name, source.crds, source.layout).catch(() => {});
    throw err;
  }
  const updatedAt = new Date().toISOString();
  const history = {
    name: source.name,
    repo,
    tag,
    commit,
    moduleVersion,
    moduleReleases: recordRelease((await readHistory(source.name))?.moduleReleases, moduleVersion, updatedAt),
    images,
    // A single-input module keeps the channel-less crdsDigest field;
    // channel modules record one digest per channel.
    ...(rawDigests[""] !== undefined ? { crdsDigest: rawDigests[""] } : {}),
    ...(source.crds !== undefined && "channels" in source.crds ? { crdsDigests: rawDigests } : {}),
    generatedDigest: await generatedFilesDigest(source.name, source.layout, source.crds),
    updatedAt,
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

/** Whether the module's generated files match the recorded provenance.
 * Every file the current declaration expects must exist — a freshly
 * declared crds input or image set re-syncs instead of being skipped. */
async function isIntact(source: ModuleSource): Promise<boolean> {
  const history = await readHistory(source.name);
  if (history === null) {
    return false;
  }
  if (!(await generatedFilesPresent(source))) {
    return false;
  }
  return (await generatedFilesDigest(source.name, source.layout, source.crds)) === history.generatedDigest;
}

/** Resolves every image of a module at the given upstream release tag. */
async function resolveImages(
  source: ModuleSource,
  repo: string,
  tag: string,
  commit: string,
): Promise<Record<string, ImageRef>> {
  const entries = Object.entries(source.images ?? {});
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
    } else if (isFileVariableImage(imageSource)) {
      const contents = await fetchRepoFile(repo, commit, imageSource.file);
      images[key] = {
        repository: imageSource.repository,
        tag: fileVariableTag(contents, imageSource.variable, imageSource.file),
        digest: "",
      };
    } else {
      // A release image: the upstream tags it with the release tag verbatim.
      images[key] = { repository: imageSource.repository, tag, digest: "" };
    }
  }
  await resolveImageDigests(images);
  return images;
}

/**
 * Fills in the registry digest of every image the upstream manifests did not
 * pin, so the rendered pods reference the exact image the release tag pointed
 * at during the sync. A tag missing from the registry fails the bump — a
 * silently unpinned image must never reach versions.cue.
 */
async function resolveImageDigests(images: Record<string, ImageRef>): Promise<void> {
  for (const ref of Object.values(images)) {
    if (ref.digest === "") {
      ref.digest = parseArtifactDigest(await retryRun(artifactListArgv(ref), 3, 5000), ref);
    }
  }
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
