// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { mkdir, rename } from "node:fs/promises";
import { join } from "node:path";
import { HISTORY_DIR } from "./paths.ts";
import type { HistoryEntry, ModuleRelease } from "./types.ts";

function historyPath(name: string): string {
  return join(HISTORY_DIR, `${name}.json`);
}

/** The release record with `version` included, sorted newest first (the
 * build suffix is a semver prerelease, so numeric suffixes order
 * correctly: 0.9.0-10 > 0.9.0-4). An already-recorded version keeps its
 * original release time — a forced re-sync is not a new release. */
export function recordRelease(
  releases: ModuleRelease[] | undefined,
  version: string,
  releasedAt: string,
): ModuleRelease[] {
  const all = new Map((releases ?? []).map((r) => [r.version, r] as const));
  if (!all.has(version)) {
    all.set(version, { version, releasedAt });
  }
  return [...all.values()].sort((a, b) => Bun.semver.order(b.version, a.version));
}

export async function readHistory(name: string): Promise<HistoryEntry | null> {
  const file = Bun.file(historyPath(name));
  if (!(await file.exists())) {
    return null;
  }
  return (await file.json()) as HistoryEntry;
}

/** Written last, after the module files and guards, so a partial sync never
 * records success. The write is atomic (temp file + rename) so a crashed run
 * never leaves a truncated provenance file. */
export async function writeHistory(entry: HistoryEntry): Promise<void> {
  await mkdir(HISTORY_DIR, { recursive: true });
  const path = historyPath(entry.name);
  const tmp = `${path}.tmp`;
  await Bun.write(tmp, `${JSON.stringify(entry, null, 2)}\n`);
  await rename(tmp, path);
}
