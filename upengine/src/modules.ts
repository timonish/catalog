// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { CATALOG_REPO, LICENSE, REGISTRY } from "../config/catalog.ts";
import { moduleDescription } from "./readme.ts";
import { parseModuleVersion } from "./resolve.ts";
import { MODULES_DIR } from "./paths.ts";
import { mustRun, run } from "./proc.ts";
import type { ModuleSource } from "./types.ts";

/**
 * Lints the module metadata that publishing depends on: every source has a
 * module directory and vice versa, VERSION parses, and the README carries a
 * description line without double quotes (it lands in an OCI annotation).
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
      throw new Error(`modules/${dir} has no entry in upengine/config/sources.ts`);
    }
  }
  for (const source of sources) {
    if (!dirs.includes(source.name)) {
      throw new Error(`sources.ts declares '${source.name}' but modules/${source.name} does not exist`);
    }
    parseModuleVersion(await Bun.file(join(MODULES_DIR, source.name, "VERSION")).text());
    const description = await moduleDescription(source.name);
    if (description.includes('"')) {
      throw new Error(`modules/${source.name}/README.md description must not contain double quotes`);
    }
    console.log(`${source.name}: metadata valid`);
  }
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
  const result = await run(["timoni", "mod", "list", `${REGISTRY}/${name}`, "--with-digest=false"]);
  if (result.exitCode !== 0) {
    // GHCR answers DENIED for both a missing package and bad credentials,
    // so a list failure is indistinguishable from a first publish.
    return null;
  }
  return result.stdout
    .split("\n")
    .slice(1)
    .map((l) => l.split(/\s+/)[0]!)
    .filter((v) => v !== "");
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
    `org.opencontainers.image.description=${await moduleDescription(name)}`,
    "-a",
    `org.opencontainers.image.documentation=https://github.com/${CATALOG_REPO}/blob/main/modules/${name}/README.md`,
  ]);
}

/**
 * The modules affected by the changes between a base ref and HEAD: a change
 * under modules/<name> selects that module; changes to the shared schemas,
 * the engine, the Makefile or the workflows select all of them.
 */
export async function changedModules(sources: ModuleSource[], base: string): Promise<string[]> {
  let diff = await run(["git", "diff", "--name-only", `${base}...HEAD`]);
  if (diff.exitCode !== 0) {
    diff = await run(["git", "diff", "--name-only", base, "HEAD"]);
  }
  if (diff.exitCode !== 0) {
    throw new Error(`git diff against '${base}' failed:\n${diff.stderr}`);
  }
  const files = diff.stdout.split("\n").filter((l) => l !== "");
  if (files.some((f) => /^(schemas\/|upengine\/|Makefile|\.github\/workflows\/)/.test(f))) {
    return sources.map((s) => s.name);
  }
  const names = new Set<string>();
  for (const file of files) {
    const match = file.match(/^modules\/([^/]+)\//);
    if (match) {
      names.add(match[1]!);
    }
  }
  return sources.map((s) => s.name).filter((n) => names.has(n));
}
