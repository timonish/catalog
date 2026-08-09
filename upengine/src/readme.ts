// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { MODULES_DIR, README_PATH } from "./paths.ts";
import { repoOf } from "./config.ts";
import type { ModuleSource } from "./types.ts";

const START_MARKER = "<!-- modules:start -->";
const END_MARKER = "<!-- modules:end -->";

/**
 * The one-line module description: the first non-empty, non-heading line of
 * the module README (the same line push-mod uses for the OCI description).
 */
export async function moduleDescription(name: string): Promise<string> {
  const text = await Bun.file(join(MODULES_DIR, name, "README.md")).text();
  for (const line of text.split("\n").slice(1)) {
    const trimmed = line.trim();
    if (trimmed !== "" && !trimmed.startsWith("#")) {
      return trimmed;
    }
  }
  throw new Error(`modules/${name}/README.md has no description line`);
}

/** Regenerates the modules table between the markers in the root README. */
export async function updateReadme(sources: ModuleSource[]): Promise<void> {
  const rows = ["| Module | Version | Upstream | Description |", "|---|---|---|---|"];
  for (const source of sources) {
    const version = (await Bun.file(join(MODULES_DIR, source.name, "VERSION")).text()).trim();
    const description = await moduleDescription(source.name);
    rows.push(
      `| [${source.name}](modules/${source.name}/README.md) | ${version} | [${repoOf(source.url)}](${source.url}) | ${description} |`,
    );
  }

  const readme = await Bun.file(README_PATH).text();
  const start = readme.indexOf(START_MARKER);
  const end = readme.indexOf(END_MARKER);
  if (start < 0 || end < 0 || end < start) {
    throw new Error(`README.md is missing the ${START_MARKER} / ${END_MARKER} markers`);
  }
  const updated =
    readme.slice(0, start + START_MARKER.length) +
    "\n" +
    rows.join("\n") +
    "\n" +
    readme.slice(end);
  if (updated !== readme) {
    await Bun.write(README_PATH, updated);
  }
}
