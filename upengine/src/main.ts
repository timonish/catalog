// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { appendFileSync } from "node:fs";
import { loadConfig } from "./config.ts";
import { updateReadme } from "./readme.ts";
import { renderSyncSummary } from "./summary.ts";
import { syncModule } from "./sync.ts";
import { SOURCES_PATH } from "./paths.ts";
import type { SyncChange, SyncFailure } from "./types.ts";

/**
 * CLI: `bun upengine/src/main.ts sync [--source <name>] [--force]`
 *
 * Syncs every module in upengine/config/sources.yaml against its upstream
 * (or a single module with --source). Failures never stop the run: each
 * module is processed and reported. Set FORCE_SYNC=1 (or --force) to re-sync
 * modules that are already at the latest upstream release.
 *
 * Outputs for CI: when SYNC_SUMMARY is set, the markdown summary is written
 * there; when GITHUB_OUTPUT is set, `changed=<bool>` and a space-separated
 * `modules=<names>` line are appended.
 */
async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const command = args[0];
  if (command !== "sync") {
    throw new Error(`usage: main.ts sync [--source <name>] [--force]`);
  }
  let only: string | undefined;
  let force = process.env.FORCE_SYNC === "1";
  for (let i = 1; i < args.length; i++) {
    if (args[i] === "--source") {
      only = args[++i];
      if (only === undefined) {
        throw new Error("--source requires a module name");
      }
    } else if (args[i] === "--force") {
      force = true;
    } else {
      throw new Error(`unknown argument '${args[i]}'`);
    }
  }

  const config = await loadConfig(SOURCES_PATH);
  const sources = only ? config.sources.filter((s) => s.name === only) : config.sources;
  if (only !== undefined && sources.length === 0) {
    throw new Error(`no source named '${only}' in sources.yaml`);
  }

  const changes: SyncChange[] = [];
  const failures: SyncFailure[] = [];
  let upToDate = 0;
  for (const source of sources) {
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
      console.error(`${source.name}: ${message}`);
    }
  }

  if (changes.length > 0) {
    await updateReadme(config.sources);
  }

  const summary = renderSyncSummary(changes, failures, upToDate);
  console.log(`\n${summary}`);
  if (process.env.SYNC_SUMMARY) {
    await Bun.write(process.env.SYNC_SUMMARY, summary);
  }
  if (process.env.GITHUB_OUTPUT) {
    appendFileSync(
      process.env.GITHUB_OUTPUT,
      `changed=${changes.length > 0}\nmodules=${changes.map((c) => c.name).join(" ")}\n`,
    );
  }
  if (failures.length > 0) {
    process.exit(1);
  }
}

await main();
