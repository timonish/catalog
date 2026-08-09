// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import { HISTORY_DIR } from "./paths.ts";
import type { HistoryEntry } from "./types.ts";

function historyPath(name: string): string {
  return join(HISTORY_DIR, `${name}.json`);
}

export async function readHistory(name: string): Promise<HistoryEntry | null> {
  const file = Bun.file(historyPath(name));
  if (!(await file.exists())) {
    return null;
  }
  return (await file.json()) as HistoryEntry;
}

/** Written last, after the module files and guards, so a partial sync never
 * records success. */
export async function writeHistory(entry: HistoryEntry): Promise<void> {
  await mkdir(HISTORY_DIR, { recursive: true });
  await Bun.write(historyPath(entry.name), `${JSON.stringify(entry, null, 2)}\n`);
}
