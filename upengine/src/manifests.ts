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

/** How normalizeCrdManifest treats the manifest beyond its defaults. */
export interface NormalizeOptions {
  /** Document kinds retained besides CustomResourceDefinition. */
  keepKinds?: string[];
  /** Preserve `metadata.labels` instead of stripping them — for upstreams
   * whose CRD labels are semantic (e.g. the Gateway API policy labels). */
  keepLabels?: boolean;
}

/**
 * Normalizes an upstream CRD manifest for import into a module: keeps only
 * the CustomResourceDefinition documents (plus any `keepKinds`) and strips
 * the packaging metadata they carry — labels (unless `keepLabels`) and the
 * `helm.sh/resource-policy` annotation baked into chart-rendered release
 * assets. The module instance owns the object metadata; leftover chart
 * labels would be wrong on every install.
 */
export function normalizeCrdManifest(manifest: string, options: NormalizeOptions = {}): string {
  // The round-trip goes through JavaScript numbers, which silently lose
  // precision above 2^53 — refuse loudly instead of corrupting a schema.
  const bigInt = manifest.match(/^[^#\n]*?:\s*[+-]?[0-9]{16,}\s*$/m);
  if (bigInt !== null) {
    throw new Error(
      `the CRD manifest contains an integer beyond safe JavaScript precision: ${bigInt[0].trim()}`,
    );
  }
  const kinds = new Set(["CustomResourceDefinition", ...(options.keepKinds ?? [])]);
  const kept: Record<string, unknown>[] = [];
  let crdCount = 0;
  for (const doc of parseAllDocuments(manifest)) {
    if (typeof doc !== "object" || doc === null) {
      continue;
    }
    const obj = doc as Record<string, unknown>;
    if (typeof obj.kind !== "string" || !kinds.has(obj.kind)) {
      continue;
    }
    if (obj.kind === "CustomResourceDefinition") {
      crdCount++;
    }
    const metadata = obj.metadata;
    if (typeof metadata === "object" && metadata !== null) {
      const meta = metadata as Record<string, unknown>;
      if (!options.keepLabels) {
        delete meta.labels;
      }
      const annotations = meta.annotations;
      if (typeof annotations === "object" && annotations !== null) {
        const ann = annotations as Record<string, unknown>;
        delete ann["helm.sh/resource-policy"];
        if (Object.keys(ann).length === 0) {
          delete meta.annotations;
        }
      } else if (annotations === null) {
        delete meta.annotations;
      }
    }
    kept.push(obj);
  }
  if (crdCount === 0) {
    throw new Error("the CRD manifest contains no CustomResourceDefinition documents");
  }
  return kept.map((doc) => YAML.stringify(doc, null, 2)).join("\n---\n");
}

function parseAllDocuments(manifests: string): unknown[] {
  const docs: unknown[] = [];
  // A document separator is `---` at line start, optionally followed by
  // whitespace or a comment (both are legal YAML).
  for (const chunk of manifests.split(/^---(?:[ \t]+.*)?$/m)) {
    if (chunk.trim() === "") {
      continue;
    }
    const doc = YAML.parse(chunk) as unknown;
    // A kind: List document carries the actual objects in items.
    const items = (doc as Record<string, unknown> | null)?.items;
    if ((doc as Record<string, unknown> | null)?.kind === "List" && Array.isArray(items)) {
      docs.push(...items);
    } else {
      docs.push(doc);
    }
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
  if (obj.kind === "CronJob") {
    const jobTemplate = spec?.jobTemplate as Record<string, unknown> | undefined;
    const jobSpec = jobTemplate?.spec as Record<string, unknown> | undefined;
    const template = jobSpec?.template as Record<string, unknown> | undefined;
    return template?.spec;
  }
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
