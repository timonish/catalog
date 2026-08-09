// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { YAML } from "bun";
import type { ImageRef } from "./types.ts";

/**
 * Extracts a container-name -> image-reference map from a multi-document
 * Kubernetes manifest stream, walking the pod templates of workload kinds
 * (and bare Pods), including init and ephemeral containers. A container name
 * appearing twice with different images is a hard error — the config must
 * then disambiguate by tracking the image explicitly.
 */
export function extractImages(manifests: string): Map<string, string> {
  const images = new Map<string, string>();
  for (const doc of parseAllDocuments(manifests)) {
    const spec = podSpecOf(doc);
    if (spec === undefined) {
      continue;
    }
    for (const listKey of ["containers", "initContainers", "ephemeralContainers"]) {
      const list = (spec as Record<string, unknown>)[listKey];
      if (!Array.isArray(list)) {
        continue;
      }
      for (const container of list) {
        const name = (container as Record<string, unknown>).name;
        const image = (container as Record<string, unknown>).image;
        if (typeof name !== "string" || typeof image !== "string") {
          continue;
        }
        const existing = images.get(name);
        if (existing !== undefined && existing !== image) {
          throw new Error(`container '${name}' appears with different images: ${existing}, ${image}`);
        }
        images.set(name, image);
      }
    }
  }
  return images;
}

function parseAllDocuments(manifests: string): unknown[] {
  const docs: unknown[] = [];
  for (const chunk of manifests.split(/^---$/m)) {
    if (chunk.trim() === "") {
      continue;
    }
    docs.push(YAML.parse(chunk));
  }
  return docs;
}

function podSpecOf(doc: unknown): unknown {
  if (typeof doc !== "object" || doc === null) {
    return undefined;
  }
  const obj = doc as Record<string, unknown>;
  if (obj.kind === "Pod") {
    return obj.spec;
  }
  const spec = obj.spec as Record<string, unknown> | undefined;
  const template = spec?.template as Record<string, unknown> | undefined;
  return template?.spec;
}

/**
 * Splits an OCI image reference into repository, tag and digest
 * (`registry.k8s.io/metrics-server/metrics-server:v0.8.0` and the
 * `repo@sha256:...` / `repo:tag@sha256:...` forms).
 */
export function parseImageRef(ref: string): ImageRef {
  let rest = ref;
  let digest = "";
  const at = rest.indexOf("@");
  if (at >= 0) {
    digest = rest.slice(at + 1);
    rest = rest.slice(0, at);
  }
  let repository = rest;
  let tag = "";
  const colon = rest.lastIndexOf(":");
  if (colon > rest.lastIndexOf("/")) {
    tag = rest.slice(colon + 1);
    repository = rest.slice(0, colon);
  }
  if (repository === "") {
    throw new Error(`invalid image reference '${ref}'`);
  }
  return { repository, tag, digest };
}
