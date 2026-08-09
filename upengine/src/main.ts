// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { appendFileSync } from "node:fs";
import { sources as configuredSources } from "../config/sources.ts";
import { validateSources } from "./config.ts";
import { e2eModule } from "./e2e.ts";
import {
  changedModules,
  lintModules,
  publishModules,
  statusModules,
  vetModules,
} from "./modules.ts";
import { createPullRequests } from "./pr.ts";
import { updateReadme } from "./readme.ts";
import { renderSyncSummary } from "./summary.ts";
import { syncModule } from "./sync.ts";
import { vendorSchemas } from "./vendor.ts";
import { mustRun } from "./proc.ts";
import type { ModuleSource, SyncChange, SyncFailure } from "./types.ts";

const USAGE = `usage: main.ts <command>

commands:
  sync [--source <name>] [--force]   sync modules with their upstream releases
  update                             sync, then open one auto-merge PR per bump
  lint                               validate module metadata against sources.ts
  vet                                timoni mod vet --debug every module
  status                             local VERSION vs published registry versions
  publish [--source <name>]          publish missing module versions to GHCR
  changed --base <ref>               modules affected between a base ref and HEAD
  e2e --source <name> [--registry <oci-url>]
                                     install, verify and uninstall on the cluster
  join --result <state>              fail when a needed matrix job failed
  vendor-schemas                     refresh the shared schemas module`;

interface SyncOutcome {
  changes: SyncChange[];
  failures: SyncFailure[];
  upToDate: number;
}

async function runSync(sources: ModuleSource[], only: string | undefined, force: boolean): Promise<SyncOutcome> {
  const selected = only ? sources.filter((s) => s.name === only) : sources;
  if (only !== undefined && selected.length === 0) {
    throw new Error(`no source named '${only}' in sources.ts`);
  }
  const changes: SyncChange[] = [];
  const failures: SyncFailure[] = [];
  let upToDate = 0;
  for (const source of selected) {
    try {
      const result = await syncModule(source, force);
      if (result.change === null) {
        upToDate++;
        console.log(`${source.name}: up to date`);
      } else {
        changes.push(result.change);
        console.log(`${source.name}: updated to ${result.change.moduleVersion}`);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      failures.push({ name: source.name, message });
      console.error(`::error::${source.name}: ${message}`);
    }
  }
  if (changes.length > 0) {
    await updateReadme(sources);
  }
  const summary = renderSyncSummary(changes, failures, upToDate);
  console.log(`\n${summary}`);
  if (process.env.SYNC_SUMMARY) {
    await Bun.write(process.env.SYNC_SUMMARY, summary);
  }
  if (process.env.GITHUB_OUTPUT) {
    appendFileSync(
      process.env.GITHUB_OUTPUT,
      `changed=${changes.length > 0}\nmodules=${JSON.stringify(changes.map((c) => c.name))}\n`,
    );
  }
  return { changes, failures, upToDate };
}

function flagValue(args: string[], flag: string): string | undefined {
  const i = args.indexOf(flag);
  if (i < 0) {
    return undefined;
  }
  const value = args[i + 1];
  if (value === undefined) {
    throw new Error(`${flag} requires a value`);
  }
  return value;
}

async function main(): Promise<void> {
  const [command, ...args] = process.argv.slice(2);
  const sources = validateSources(configuredSources);
  const force = args.includes("--force") || process.env.FORCE_SYNC === "1";

  switch (command) {
    case "sync": {
      const outcome = await runSync(sources, flagValue(args, "--source"), force);
      if (outcome.failures.length > 0) {
        process.exit(1);
      }
      break;
    }
    case "update": {
      // Sync and PR creation share one process so partial failures never
      // skip the pull requests of the modules that did succeed.
      const baseSha = (await mustRun(["git", "rev-parse", "HEAD"])).trim();
      const outcome = await runSync(sources, undefined, force);
      if (outcome.changes.length > 0) {
        await createPullRequests(sources, outcome.changes, baseSha);
      }
      if (outcome.failures.length > 0) {
        process.exit(1);
      }
      break;
    }
    case "lint":
      await lintModules(sources);
      break;
    case "vet":
      await vetModules(sources);
      break;
    case "status":
      await statusModules(sources);
      break;
    case "publish":
      await publishModules(sources, flagValue(args, "--source"));
      break;
    case "changed": {
      const base = flagValue(args, "--base");
      if (base === undefined) {
        throw new Error("changed requires --base <ref>");
      }
      const modules = await changedModules(sources, base);
      console.log(`changed modules: ${JSON.stringify(modules)}`);
      if (process.env.GITHUB_OUTPUT) {
        appendFileSync(process.env.GITHUB_OUTPUT, `modules=${JSON.stringify(modules)}\n`);
      }
      break;
    }
    case "e2e": {
      const name = flagValue(args, "--source");
      if (name === undefined) {
        throw new Error("e2e requires --source <name>");
      }
      const source = sources.find((s) => s.name === name);
      if (source === undefined) {
        throw new Error(`no source named '${name}' in sources.ts`);
      }
      await e2eModule(source, flagValue(args, "--registry"));
      break;
    }
    case "join": {
      const result = flagValue(args, "--result");
      if (result === "failure" || result === "cancelled") {
        throw new Error(`needed jobs ended with: ${result}`);
      }
      console.log(`ok (result: ${result})`);
      break;
    }
    case "vendor-schemas":
      await vendorSchemas();
      break;
    default:
      throw new Error(USAGE);
  }
}

await main();
