// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { CrdInput, CrdsConfig, ImageSource, ModuleSource } from "./types.ts";

const NAME_RE = /^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/;
const REPO_URL_RE = /^https:\/\/github\.com\/([\w.-]+\/[\w.-]+)$/;
const VARIABLE_RE = /^[A-Za-z_][A-Za-z0-9_]*$/;

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

/** Whether an image's tag is read from a variable in a repo file. */
export function isFileVariableImage(
  image: ImageSource,
): image is { file: string; variable: string; repository: string } {
  return "file" in image;
}

/**
 * The CRD inputs of a module keyed by channel: a `channels` declaration
 * verbatim, a single input under the `null`-marker key "" (rendered to the
 * channel-less templates/crds.cue), or an empty record without `crds`.
 */
export function crdChannels(crds: CrdsConfig | undefined): Record<string, CrdInput> {
  if (crds === undefined) {
    return {};
  }
  if ("channels" in crds) {
    return crds.channels;
  }
  return { "": crds };
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
    if (!source.parityTarget.startsWith("https://")) {
      throw new Error(`${at}: 'parityTarget' must be an https URL`);
    }
    const images = Object.entries(source.images ?? {});
    if (source.images !== undefined && images.length === 0) {
      throw new Error(`${at}: 'images' must not be empty; omit it for a CRDs-only module`);
    }
    if (source.images === undefined && source.crds === undefined) {
      throw new Error(`${at}: a module must declare 'images' or 'crds'`);
    }
    for (const [key, image] of images) {
      // The variants are discriminated by their marker key; an object
      // carrying more than one would silently resolve as the first
      // matching guard.
      const markers = ["container", "url", "file"].filter((m) => m in image);
      if (markers.length > 1) {
        throw new Error(
          `${at}.images['${key}']: '${markers.join("' and '")}' cannot be combined`,
        );
      }
      if (isContainerImage(image)) {
        if (image.container === "") {
          throw new Error(`${at}.images['${key}']: 'container' must not be empty`);
        }
      } else if (isTrackedImage(image)) {
        repoOf(image.url);
        if (image.releaseTag === "" || image.repository === "") {
          throw new Error(`${at}.images['${key}']: 'releaseTag' and 'repository' must not be empty`);
        }
      } else if (isFileVariableImage(image)) {
        if (image.file === "" || image.repository === "") {
          throw new Error(`${at}.images['${key}']: 'file' and 'repository' must not be empty`);
        }
        if (!VARIABLE_RE.test(image.variable)) {
          throw new Error(`${at}.images['${key}']: invalid 'variable' name`);
        }
      } else if (image.repository === "") {
        throw new Error(`${at}.images['${key}']: 'repository' must not be empty`);
      }
    }
    if (images.some(([, i]) => isContainerImage(i)) && source.manifests === undefined) {
      throw new Error(`${at}: 'manifests' is required when an image is extracted by container name`);
    }
    if (source.crds !== undefined) {
      if ("channels" in source.crds) {
        if ("file" in source.crds || "releaseAsset" in source.crds) {
          throw new Error(`${at}: crds 'channels' cannot be combined with 'file' or 'releaseAsset'`);
        }
        const channels = Object.entries(source.crds.channels);
        if (channels.length === 0) {
          throw new Error(`${at}: crds 'channels' must not be empty`);
        }
        for (const [channel, input] of channels) {
          if (!NAME_RE.test(channel)) {
            throw new Error(`${at}.crds.channels['${channel}']: invalid channel name`);
          }
          validateCrdInput(input, `${at}.crds.channels['${channel}']`);
        }
      } else {
        validateCrdInput(source.crds, `${at}`);
      }
      if (source.crds.keepKinds?.some((k) => k === "")) {
        throw new Error(`${at}: crds 'keepKinds' entries must not be empty`);
      }
    }
  }
  return sources;
}

function validateCrdInput(input: CrdInput, at: string): void {
  if ("file" in input && "releaseAsset" in input) {
    throw new Error(`${at}: crds must declare either 'file' or 'releaseAsset', not both`);
  }
  const location = "file" in input ? input.file : input.releaseAsset;
  if (location === "") {
    throw new Error(`${at}: the crds 'file' or 'releaseAsset' must not be empty`);
  }
}
