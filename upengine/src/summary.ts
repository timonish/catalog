// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { SyncChange, SyncFailure } from "./types.ts";

/**
 * Renders the markdown summary of a sync run: one section per bumped module
 * (this doubles as the PR body of a single-module bump), plus failures so a
 * transient blip on one module is visible instead of silently dropped.
 */
export function renderSyncSummary(
  changes: SyncChange[],
  failures: SyncFailure[],
  upToDate: number,
): string {
  const lines: string[] = [];
  for (const change of changes) {
    lines.push(renderChange(change));
  }
  if (failures.length > 0) {
    lines.push("## Failures", "");
    for (const failure of failures) {
      lines.push(`- **${failure.name}**: ${failure.message}`);
    }
    lines.push("");
  }
  lines.push(`${changes.length} module(s) updated, ${failures.length} failed, ${upToDate} up to date.`);
  return lines.join("\n");
}

/** The PR body of one module bump. */
export function renderChange(change: SyncChange): string {
  const lines = [
    `## ${change.name} ${change.moduleVersion}`,
    "",
    `Update [${change.repo}](https://github.com/${change.repo}) to [${change.tag}](https://github.com/${change.repo}/releases/tag/${change.tag}) (module \`${change.prevModuleVersion}\` -> \`${change.moduleVersion}\`).`,
    "",
    "| Image | Tag |",
    "|---|---|",
  ];
  for (const ref of Object.values(change.images)) {
    lines.push(`| \`${ref.repository}\` | ${ref.tag} |`);
  }
  lines.push("");
  return lines.join("\n");
}
