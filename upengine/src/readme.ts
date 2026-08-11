// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { MODULES_DIR, README_PATH } from "./paths.ts";
import { repoOf } from "./config.ts";
import { readHistory } from "./history.ts";
import type { HistoryEntry, ModuleSource } from "./types.ts";

const START_MARKER = "<!-- modules:start -->";
const END_MARKER = "<!-- modules:end -->";

const VERSIONS_START = "<!-- versions:start -->";
const VERSIONS_END = "<!-- versions:end -->";

/**
 * Reduces a markdown description to plain text by replacing links with
 * their text, e.g. `[Timoni](https://timoni.sh)` becomes `Timoni` — the
 * form that lands in the OCI description annotation.
 */
export function plainDescription(description: string): string {
  return description.replace(/\[([^\]]*)\]\([^()\s]*\)/g, "$1");
}

/**
 * The one-line module description: the first non-empty, non-heading line of
 * the module README (the same line publish uses for the OCI description,
 * after stripping the markdown links).
 */
export async function moduleDescription(name: string): Promise<string> {
  const text = await Bun.file(join(MODULES_DIR, name, "README.md")).text();
  for (const line of text.split("\n").slice(1)) {
    const trimmed = line.trim();
    if (trimmed !== "" && !trimmed.startsWith("#") && !trimmed.startsWith("<!--")) {
      return trimmed;
    }
  }
  throw new Error(`modules/${name}/README.md has no description line`);
}

/** Renders the engine-owned version section of a module README. */
export function renderModuleVersions(history: HistoryEntry): string {
  const images = Object.values(history.images);
  const release = `[${history.tag}](https://github.com/${history.repo}/releases/tag/${history.tag})`;
  if (images.length === 0) {
    return [
      `Latest module version is \`${history.moduleVersion}\`, packaging the upstream release`,
      `${release}.`,
    ].join("\n");
  }
  // The Digest column appears with the first sync that pins digests, so
  // the sections of modules synced before digest pinning stay valid.
  const withDigests = images.some((image) => image.digest !== "");
  const rows = withDigests
    ? ["| Image | Tag | Digest |", "|---|---|---|"]
    : ["| Image | Tag |", "|---|---|"];
  for (const image of images) {
    const digest = image.digest === "" ? "" : `\`${image.digest}\``;
    rows.push(
      withDigests
        ? `| \`${image.repository}\` | ${image.tag} | ${digest} |`
        : `| \`${image.repository}\` | ${image.tag} |`,
    );
  }
  return [
    `Latest module version is \`${history.moduleVersion}\`, packaging the upstream release`,
    release,
    "with the following container images:",
    "",
    ...rows,
  ].join("\n");
}

/** The module README with its version section rendered from the history. */
export function withModuleVersions(readme: string, history: HistoryEntry): string {
  const start = readme.indexOf(VERSIONS_START);
  const end = readme.indexOf(VERSIONS_END);
  if (start < 0 || end < 0 || end < start) {
    throw new Error(
      `modules/${history.name}/README.md is missing the ${VERSIONS_START} / ${VERSIONS_END} markers`,
    );
  }
  return (
    readme.slice(0, start + VERSIONS_START.length) +
    "\n" +
    renderModuleVersions(history) +
    "\n" +
    readme.slice(end)
  );
}

/** Replaces the version section between the markers in a module README. */
export async function updateModuleReadme(history: HistoryEntry): Promise<void> {
  const path = join(MODULES_DIR, history.name, "README.md");
  const readme = await Bun.file(path).text();
  const updated = withModuleVersions(readme, history);
  if (updated !== readme) {
    await Bun.write(path, updated);
  }
}

/** Renders the modules table, ordered by module name, from the
 * worktree's VERSION files and the recorded sync history. */
export async function renderReadmeTable(sources: ModuleSource[]): Promise<string> {
  const rows = ["| Module | Version | Updated | Upstream |", "|---|---|---|---|"];
  const ordered = [...sources].sort((a, b) => a.name.localeCompare(b.name));
  for (const source of ordered) {
    const version = (await Bun.file(join(MODULES_DIR, source.name, "VERSION")).text()).trim();
    const history = await readHistory(source.name);
    const updated = history === null ? "" : formatTableDate(history.updatedAt);
    rows.push(
      `| [${source.name}](modules/${source.name}/README.md) | ${version} | ${updated} | [${repoOf(source.url)}](${source.url}) |`,
    );
  }
  return rows.join("\n");
}

/** The date of a history timestamp in the YYYY.MM.DD table format. */
export function formatTableDate(timestamp: string): string {
  return new Date(timestamp).toISOString().slice(0, 10).replaceAll("-", ".");
}

/** Replaces the modules table between the markers in the root README. */
export async function writeReadmeTable(table: string): Promise<void> {
  const readme = await Bun.file(README_PATH).text();
  const start = readme.indexOf(START_MARKER);
  const end = readme.indexOf(END_MARKER);
  if (start < 0 || end < 0 || end < start) {
    throw new Error(`README.md is missing the ${START_MARKER} / ${END_MARKER} markers`);
  }
  const updated =
    readme.slice(0, start + START_MARKER.length) + "\n" + table + "\n" + readme.slice(end);
  if (updated !== readme) {
    await Bun.write(README_PATH, updated);
  }
}

/** Regenerates the modules table in place. */
export async function updateReadme(sources: ModuleSource[]): Promise<void> {
  await writeReadmeTable(await renderReadmeTable(sources));
}
