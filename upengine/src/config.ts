// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { YAML } from "bun";
import type { EngineConfig, ImageSource, ManifestsInput, ModuleSource } from "./types.ts";

const SOURCE_KEYS = ["name", "url", "releaseTag", "version", "manifests", "images"];
const MANIFESTS_KEYS = ["releaseAsset", "file"];
const IMAGE_KEYS = ["container", "url", "releaseTag", "repository"];
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

export async function loadConfig(path: string): Promise<EngineConfig> {
  let doc: unknown;
  try {
    doc = YAML.parse(await Bun.file(path).text());
  } catch (err) {
    throw new Error(`${path}: ${err instanceof Error ? err.message : err}`);
  }
  try {
    return parseConfig(doc);
  } catch (err) {
    throw new Error(`${path}: ${(err as Error).message}`);
  }
}

export function parseConfig(doc: unknown): EngineConfig {
  if (!isRecord(doc)) {
    throw new Error("expected a top-level mapping with a 'sources' list");
  }
  const unknown = Object.keys(doc).filter((k) => k !== "sources");
  if (unknown.length > 0) {
    throw new Error(`unknown top-level keys: ${unknown.join(", ")}`);
  }
  if (!Array.isArray(doc.sources) || doc.sources.length === 0) {
    throw new Error("'sources' must be a non-empty list");
  }

  const names = new Set<string>();
  const sources = (doc.sources as unknown[]).map((entry, i) => {
    const source = parseSource(entry, `sources[${i}]`);
    if (names.has(source.name)) {
      throw new Error(`sources[${i}]: duplicate name '${source.name}'`);
    }
    names.add(source.name);
    return source;
  });
  return { sources };
}

function parseSource(entry: unknown, at: string): ModuleSource {
  if (!isRecord(entry)) {
    throw new Error(`${at}: expected a mapping`);
  }
  const unknown = Object.keys(entry).filter((k) => !SOURCE_KEYS.includes(k));
  if (unknown.length > 0) {
    throw new Error(`${at}: unknown keys: ${unknown.join(", ")}`);
  }
  const name = requireString(entry, "name", at);
  if (!NAME_RE.test(name)) {
    throw new Error(`${at}: invalid name '${name}'`);
  }
  const url = requireString(entry, "url", at);
  repoOf(url);
  const releaseTag = optionalString(entry, "releaseTag", at);
  const version = optionalString(entry, "version", at);

  let manifests: ManifestsInput | undefined;
  if (entry.manifests !== undefined) {
    manifests = parseManifests(entry.manifests, `${at}.manifests`);
  }

  if (!isRecord(entry.images) || Object.keys(entry.images).length === 0) {
    throw new Error(`${at}: 'images' must be a non-empty mapping`);
  }
  const images = new Map<string, ImageSource>();
  for (const [key, value] of Object.entries(entry.images)) {
    images.set(key, parseImage(value, `${at}.images.${key}`));
  }

  const needsManifests = [...images.values()].some((i) => i.kind === "container");
  if (needsManifests && manifests === undefined) {
    throw new Error(`${at}: 'manifests' is required when an image is extracted by container name`);
  }

  return { name, url, releaseTag, version, manifests, images };
}

function parseManifests(entry: unknown, at: string): ManifestsInput {
  if (!isRecord(entry)) {
    throw new Error(`${at}: expected a mapping`);
  }
  const keys = Object.keys(entry);
  const unknown = keys.filter((k) => !MANIFESTS_KEYS.includes(k));
  if (unknown.length > 0) {
    throw new Error(`${at}: unknown keys: ${unknown.join(", ")}`);
  }
  if (keys.length !== 1) {
    throw new Error(`${at}: exactly one of ${MANIFESTS_KEYS.join(", ")} is required`);
  }
  if (typeof entry.releaseAsset === "string" && entry.releaseAsset !== "") {
    return { kind: "releaseAsset", asset: entry.releaseAsset };
  }
  if (typeof entry.file === "string" && entry.file !== "") {
    return { kind: "file", path: entry.file };
  }
  throw new Error(`${at}: '${keys[0]}' must be a non-empty string`);
}

function parseImage(entry: unknown, at: string): ImageSource {
  if (!isRecord(entry)) {
    throw new Error(`${at}: expected a mapping`);
  }
  const unknown = Object.keys(entry).filter((k) => !IMAGE_KEYS.includes(k));
  if (unknown.length > 0) {
    throw new Error(`${at}: unknown keys: ${unknown.join(", ")}`);
  }
  if (entry.container !== undefined) {
    if (Object.keys(entry).length !== 1) {
      throw new Error(`${at}: 'container' cannot be combined with other keys`);
    }
    const container = entry.container;
    if (typeof container !== "string" || container === "") {
      throw new Error(`${at}: 'container' must be a non-empty string`);
    }
    return { kind: "container", container };
  }
  const url = requireString(entry, "url", at);
  repoOf(url);
  const releaseTag = requireString(entry, "releaseTag", at);
  const repository = requireString(entry, "repository", at);
  return { kind: "tracked", url, releaseTag, repository };
}

function requireString(entry: Record<string, unknown>, key: string, at: string): string {
  const value = entry[key];
  if (typeof value !== "string" || value === "") {
    throw new Error(`${at}: '${key}' must be a non-empty string`);
  }
  return value;
}

function optionalString(
  entry: Record<string, unknown>,
  key: string,
  at: string,
): string | undefined {
  if (entry[key] === undefined) {
    return undefined;
  }
  return requireString(entry, key, at);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
