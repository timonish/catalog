// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

// Module upstream declarations for `bun upengine/src/main.ts sync`: one file
// per module under sources/, each exporting `source: ModuleSource`, loaded
// here in filename order. Adding a module's automation is a single new
// sources/<name>.ts file — nothing else to edit; the files are typechecked
// by `make lint` and validated by `validateSources` at runtime.

import { readdir } from "node:fs/promises";
import { basename, join } from "node:path";
import type { ModuleSource } from "../src/types.ts";

const dir = join(import.meta.dir, "sources");

export const sources: ModuleSource[] = [];
for (const file of (await readdir(dir)).filter((f) => f.endsWith(".ts")).sort()) {
  const declared = (await import(join(dir, file))) as { source?: ModuleSource };
  if (declared.source === undefined) {
    throw new Error(`config/sources/${file} does not export 'source'`);
  }
  if (declared.source.name !== basename(file, ".ts")) {
    throw new Error(
      `config/sources/${file} declares name '${declared.source.name}'; the filename must match`,
    );
  }
  sources.push(declared.source);
}
