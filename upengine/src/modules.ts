// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { CATALOG_REPO, LICENSE, REGISTRY, TIMONI_MIN_VERSION } from "../config/catalog.ts";
import { crdsCuePaths } from "./codegen.ts";
import {
  assertReadmeTable,
  moduleDescription,
  plainDescription,
  validateDescription,
  validatePrerequisites,
  withModuleVersions,
} from "./readme.ts";
import { readHistory } from "./history.ts";
import { parseModuleVersion } from "./resolve.ts";
import { BUNDLES_DIR, MODULES_DIR } from "./paths.ts";
import { mustRun, run } from "./proc.ts";
import type { ModuleSource } from "./types.ts";

/**
 * Lints the module metadata that publishing depends on: every source has a
 * module directory and vice versa, VERSION parses and matches the recorded
 * history, the README description line and Prerequisites section follow the
 * catalog-wide shape (the description lands in an OCI annotation), and the
 * README version section is in sync with the history manifest.
 */
export async function lintModules(sources: ModuleSource[]): Promise<void> {
  const dirs = (await mustRun(["git", "ls-files", "modules"]))
    .split("\n")
    .filter((l) => l !== "")
    .map((l) => l.split("/")[1]!)
    .filter((v, i, a) => a.indexOf(v) === i);
  const declared = new Set(sources.map((s) => s.name));
  for (const dir of dirs) {
    if (!declared.has(dir)) {
      throw new Error(`modules/${dir} has no source in upengine/config/sources/`);
    }
  }
  for (const source of sources) {
    if (!dirs.includes(source.name)) {
      throw new Error(`sources.ts declares '${source.name}' but modules/${source.name} does not exist`);
    }
    const version = (await Bun.file(join(MODULES_DIR, source.name, "VERSION")).text()).trim();
    parseModuleVersion(version);
    validateDescription(source.name, await moduleDescription(source.name));
    validatePrerequisites(
      source.name,
      await Bun.file(join(MODULES_DIR, source.name, "README.md")).text(),
      TIMONI_MIN_VERSION,
    );
    if (!(await Bun.file(join(BUNDLES_DIR, source.name, "bundle.cue")).exists())) {
      throw new Error(`test/bundles/${source.name}/bundle.cue is missing`);
    }
    for (const path of crdsCuePaths(source.name, source.crds)) {
      if (!(await Bun.file(path).exists())) {
        throw new Error(`${path} is missing; run 'make sync MODULE=${source.name} FORCE=1'`);
      }
    }
    const history = await readHistory(source.name);
    if (history !== null) {
      if (history.moduleVersion !== version) {
        throw new Error(
          `modules/${source.name}/VERSION is ${version} but the history records ${history.moduleVersion}; run 'make sync MODULE=${source.name} FORCE=1'`,
        );
      }
      const readme = await Bun.file(join(MODULES_DIR, source.name, "README.md")).text();
      if (withModuleVersions(readme, history) !== readme) {
        throw new Error(
          `modules/${source.name}/README.md version section is stale; run 'make sync MODULE=${source.name} FORCE=1'`,
        );
      }
    }
    console.log(`${source.name}: metadata valid`);
  }
  await assertReadmeTable(sources);
}

/** Vets every module with the debug values (all optional objects enabled). */
export async function vetModules(sources: ModuleSource[]): Promise<void> {
  for (const source of sources) {
    console.log(`vetting modules/${source.name}`);
    await mustRun(["timoni", "mod", "vet", join(MODULES_DIR, source.name), "--debug"]);
  }
}

/** The versions of a module published on the registry. */
export async function publishedVersions(name: string): Promise<string[] | null> {
  const result = await run([
    "timoni", "mod", "list", `${REGISTRY}/${name}`, "--with-digest=false", "-o", "json",
  ]);
  if (result.exitCode !== 0) {
    // GHCR answers DENIED for both a missing package and bad credentials,
    // so a list failure is indistinguishable from a first publish.
    return null;
  }
  return parseModuleList(result.stdout);
}

/** The version tags in a `timoni mod list -o json` document. */
export function parseModuleList(stdout: string): string[] {
  const entries: unknown = JSON.parse(stdout);
  if (!Array.isArray(entries)) {
    throw new Error("timoni mod list did not print a JSON array");
  }
  return entries.map((entry) => {
    if (typeof entry?.version !== "string" || entry.version === "") {
      throw new Error(`timoni mod list entry has no version: ${JSON.stringify(entry)}`);
    }
    return entry.version;
  });
}

/** Prints each module's local VERSION next to its publish state. */
export async function statusModules(sources: ModuleSource[]): Promise<void> {
  for (const source of sources) {
    const version = (await Bun.file(join(MODULES_DIR, source.name, "VERSION")).text()).trim();
    const published = await publishedVersions(source.name);
    const state = published?.includes(version) ? "published" : "not published";
    console.log(`${source.name} ${version} ${state}`);
  }
}

/**
 * Publishes every module version missing from the registry — idempotent and
 * safe to rerun; failures in one module never block the others. GHCR cannot
 * distinguish a missing package from bad credentials, so a list failure
 * warns and attempts the push (a real credential problem then fails loudly).
 */
export async function publishModules(sources: ModuleSource[], only?: string): Promise<void> {
  const selected = only ? sources.filter((s) => s.name === only) : sources;
  if (only !== undefined && selected.length === 0) {
    throw new Error(`no source named '${only}' in sources.ts`);
  }
  const failures: string[] = [];
  for (const source of selected) {
    const version = (await Bun.file(join(MODULES_DIR, source.name, "VERSION")).text()).trim();
    parseModuleVersion(version);
    try {
      const published = await publishedVersions(source.name);
      if (published === null) {
        console.warn(`::warning::cannot list ${REGISTRY}/${source.name} (first publish?)`);
      } else if (published.includes(version)) {
        console.log(`${source.name} ${version} already published, skipping`);
        continue;
      }
      console.log(`publishing ${source.name} ${version}`);
      await pushModule(source.name, version);
      console.log(`::notice::published ${source.name} ${version}`);
    } catch (err) {
      failures.push(source.name);
      console.error(`::error::push failed for ${source.name} ${version}: ${err instanceof Error ? err.message : err}`);
    }
  }
  if (failures.length > 0) {
    throw new Error(`failed modules: ${failures.join(", ")}`);
  }
}

async function pushModule(name: string, version: string): Promise<void> {
  const revision =
    process.env.GITHUB_SHA ?? (await mustRun(["git", "rev-parse", "HEAD"])).trim();
  await mustRun([
    "timoni",
    "mod",
    "push",
    join(MODULES_DIR, name),
    `${REGISTRY}/${name}`,
    `-v=${version}`,
    "--latest",
    "--resolve-symlinks",
    "--sign",
    "cosign",
    "-a",
    `org.opencontainers.image.source=https://github.com/${CATALOG_REPO}`,
    "-a",
    `org.opencontainers.image.licenses=${LICENSE}`,
    "-a",
    `org.opencontainers.image.revision=${revision}`,
    "-a",
    `org.opencontainers.image.description=${plainDescription(await moduleDescription(name))}`,
    "-a",
    `org.opencontainers.image.documentation=https://github.com/${CATALOG_REPO}/blob/main/modules/${name}/README.md`,
  ]);
}

/** The sources eligible for the CI e2e matrix: everything not opting out
 * with `e2e.ci: false` (those stay runnable locally via `make e2e`). */
export function ciSources(sources: ModuleSource[]): ModuleSource[] {
  return sources.filter((s) => s.e2e.ci !== false);
}

/**
 * The modules selected by a list of changed files: per-module data files
 * (modules/<name>, the module's source declaration, history manifest and
 * e2e bundle) select only their module; anything else under the engine,
 * the shared schemas, the Makefile or the workflows is an engine-wide
 * change and selects all modules.
 */
export function selectModules(sources: ModuleSource[], files: string[]): string[] {
  const perModule = [
    /^modules\/([^/]+)\//,
    /^upengine\/config\/sources\/([^/]+)\.ts$/,
    /^upengine\/history\/([^/]+)\.json$/,
    /^test\/bundles\/([^/]+)\//,
  ];
  const names = new Set<string>();
  for (const file of files) {
    const match = perModule.map((re) => file.match(re)).find((m) => m != null);
    if (match) {
      names.add(match[1]!);
    } else if (/^(schemas\/|upengine\/|Makefile|\.github\/workflows\/)/.test(file)) {
      return sources.map((s) => s.name);
    }
  }
  return sources.map((s) => s.name).filter((n) => names.has(n));
}

/** The modules affected by the changes between a base ref and HEAD. */
export async function changedModules(sources: ModuleSource[], base: string): Promise<string[]> {
  let diff = await run(["git", "diff", "--name-only", `${base}...HEAD`]);
  if (diff.exitCode !== 0) {
    diff = await run(["git", "diff", "--name-only", base, "HEAD"]);
  }
  if (diff.exitCode !== 0) {
    throw new Error(`git diff against '${base}' failed:\n${diff.stderr}`);
  }
  return selectModules(sources, diff.stdout.split("\n").filter((l) => l !== ""));
}
