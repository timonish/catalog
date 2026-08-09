// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ImageSource, ModuleSource } from "./types.ts";

const NAME_RE = /^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/;
const REPO_URL_RE = /^https:\/\/github\.com\/([\w.-]+\/[\w.-]+)$/;

/** Returns the owner/name part of a GitHub repository URL. */
export function repoOf(url: string): string {
  const match = url.match(REPO_URL_RE);
  if (!match) {
    throw new Error(`not a GitHub repository URL: ${url}`);
  }
  return match[1]!;
}

/** Whether an image's tag is extracted from the release manifests. */
export function isContainerImage(image: ImageSource): image is { container: string } {
  return "container" in image;
}

/** Whether an image's tag is tracked from another repository's releases. */
export function isTrackedImage(
  image: ImageSource,
): image is { url: string; releaseTag: string; repository: string } {
  return "url" in image;
}

/**
 * Semantic validation of the typed sources config — the shape itself is
 * enforced by the TypeScript compiler (`make lint`); this covers what the
 * types cannot: name format, duplicates, URL format, and the
 * manifests-required-by-container-images rule.
 */
export function validateSources(sources: ModuleSource[]): ModuleSource[] {
  if (sources.length === 0) {
    throw new Error("sources must not be empty");
  }
  const names = new Set<string>();
  for (const source of sources) {
    const at = `sources['${source.name}']`;
    if (!NAME_RE.test(source.name)) {
      throw new Error(`${at}: invalid name`);
    }
    if (names.has(source.name)) {
      throw new Error(`${at}: duplicate name`);
    }
    names.add(source.name);
    repoOf(source.url);
    const images = Object.entries(source.images);
    if (images.length === 0) {
      throw new Error(`${at}: 'images' must not be empty`);
    }
    for (const [key, image] of images) {
      if (isContainerImage(image)) {
        if (image.container === "") {
          throw new Error(`${at}.images['${key}']: 'container' must not be empty`);
        }
      } else if (isTrackedImage(image)) {
        repoOf(image.url);
        if (image.releaseTag === "" || image.repository === "") {
          throw new Error(`${at}.images['${key}']: 'releaseTag' and 'repository' must not be empty`);
        }
      } else if (image.repository === "") {
        throw new Error(`${at}.images['${key}']: 'repository' must not be empty`);
      }
    }
    if (images.some(([, i]) => isContainerImage(i)) && source.manifests === undefined) {
      throw new Error(`${at}: 'manifests' is required when an image is extracted by container name`);
    }
    if (source.crds !== undefined && source.crds.file === "") {
      throw new Error(`${at}: 'crds.file' must not be empty`);
    }
  }
  return sources;
}
