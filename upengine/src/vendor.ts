// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { readdir, rm } from "node:fs/promises";
import { join } from "node:path";
import { CRD_SCHEMAS, TIMONI_SCHEMAS } from "../config/catalog.ts";
import { ROOT_DIR } from "./paths.ts";
import { mustRun } from "./proc.ts";

const SCHEMAS_DIR = join(ROOT_DIR, "schemas");
const GEN_DIR = join(SCHEMAS_DIR, "cue.mod/gen");

/**
 * Refreshes the shared schemas module: the Timoni core schemas from the
 * published artifact, the full Kubernetes API schemas, and the pinned CRD
 * schemas pruned to their universally useful kinds.
 */
export async function vendorSchemas(): Promise<void> {
  console.log(`pulling ${TIMONI_SCHEMAS}`);
  await mustRun([
    "timoni", "artifact", "pull", TIMONI_SCHEMAS,
    "--output", join(SCHEMAS_DIR, "cue.mod/pkg"),
  ]);
  console.log("vendoring the Kubernetes API schemas");
  await mustRun(["timoni", "mod", "vendor", "k8s", SCHEMAS_DIR]);

  for (const crd of CRD_SCHEMAS) {
    console.log(`vendoring ${crd.group} from ${crd.url}`);
    await mustRun(["timoni", "mod", "vendor", "crd", SCHEMAS_DIR, "-f", crd.url]);
    for (const group of crd.removeGroups) {
      await rm(join(SCHEMAS_DIR, "cue.mod/gen", group), { recursive: true, force: true });
    }
    const groupDir = join(SCHEMAS_DIR, "cue.mod/gen", crd.group);
    for (const entry of await readdir(groupDir, { withFileTypes: true })) {
      if (entry.isDirectory() && !crd.keep.includes(entry.name)) {
        await rm(join(groupDir, entry.name), { recursive: true, force: true });
      }
    }
    console.log(`${crd.group}: kept ${crd.keep.join(", ")}`);
  }

  console.log("stripping comments from the generated schemas");
  let stripped = 0;
  for await (const path of new Bun.Glob("**/*.cue").scan({ cwd: GEN_DIR })) {
    const file = Bun.file(join(GEN_DIR, path));
    const source = await file.text();
    const lean = stripSchemaComments(source);
    if (lean !== source) {
      await Bun.write(file, lean);
      stripped++;
    }
  }
  console.log(`stripped ${stripped} files`);
}

/**
 * Drops comment-only lines from a generated schema file. The vendored
 * Kubernetes and CRD schemas repeat the upstream doc comment on every
 * field; that prose carries no semantics for vet/build yet dominates the
 * compressed size of every pushed module (the k8s.io tree gzips 5x
 * smaller without it). Lines inside multiline string literals are kept,
 * and so are trailing comments on code lines.
 */
export function stripSchemaComments(source: string): string {
  let inString = false;
  return source
    .split("\n")
    .filter((line) => {
      const keep = inString || !/^\s*\/\//.test(line);
      if ((line.match(/"""|'''/g)?.length ?? 0) % 2 === 1) {
        inString = !inString;
      }
      return keep;
    })
    .join("\n");
}
