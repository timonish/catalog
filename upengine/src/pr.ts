// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { CATALOG_REPO } from "../config/catalog.ts";
import { fetchRetry } from "./github.ts";
import { renderReadmeTable, writeReadmeTable } from "./readme.ts";
import { renderChange } from "./summary.ts";
import { MODULES_DIR } from "./paths.ts";
import { mustRun, run } from "./proc.ts";
import type { ModuleSource, SyncChange } from "./types.ts";

const API_BASE = "https://api.github.com";

function botToken(): string {
  const token = process.env.BOT_GH_TOKEN || process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  if (!token) {
    throw new Error("no GitHub token: set BOT_GH_TOKEN (or GITHUB_TOKEN)");
  }
  if (!process.env.BOT_GH_TOKEN) {
    console.warn(
      "::warning::BOT_GH_TOKEN is not set; PRs created with the workflow token do not trigger CI, which blocks auto-merge",
    );
  }
  return token;
}

async function api(method: string, path: string, body?: unknown): Promise<unknown> {
  const res = await fetchRetry(`${API_BASE}${path}`, {
    method,
    headers: {
      Accept: "application/vnd.github+json",
      "User-Agent": "timonish-catalog-upengine",
      Authorization: `Bearer ${botToken()}`,
      ...(body !== undefined ? { "Content-Type": "application/json" } : {}),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const payload = (await res.json().catch(() => ({}))) as Record<string, unknown>;
  if (!res.ok) {
    throw new Error(`${method} ${path}: ${res.status} ${payload.message ?? res.statusText}`);
  }
  return payload;
}

/**
 * Opens (or refreshes) one pull request per bumped module and requests
 * auto-merge. Each branch is rebuilt from the base commit with only that
 * module's generated files plus a README table consistent with the branch
 * content (other modules stay at their base versions). A failure on one
 * module never blocks the others.
 */
export async function createPullRequests(
  sources: ModuleSource[],
  changes: SyncChange[],
  baseSha: string,
): Promise<void> {
  // Capture the just-synced generated files before resetting the worktree:
  // each branch must contain exactly one module's bump.
  const staged = new Map<string, Map<string, string>>();
  for (const change of changes) {
    const files = new Map<string, string>();
    for (const path of changePaths(change.name)) {
      // crds.cue only exists for modules that track upstream CRDs.
      const file = Bun.file(path);
      if (await file.exists()) {
        files.set(path, await file.text());
      }
    }
    staged.set(change.name, files);
  }
  await mustRun(["git", "checkout", "--", "."]);
  await run(["git", "config", "user.name", "timonish-bot"]);
  await run(["git", "config", "user.email", "bot@timonish.dev"]);

  const failures: string[] = [];
  for (const change of changes) {
    try {
      await createPullRequest(sources, change, baseSha, staged.get(change.name)!);
    } catch (err) {
      failures.push(change.name);
      console.error(`::error::PR for ${change.name} failed: ${err instanceof Error ? err.message : err}`);
    } finally {
      await run(["git", "checkout", "--detach", baseSha]);
      await run(["git", "checkout", "--", "."]);
    }
  }
  if (failures.length > 0) {
    throw new Error(`pull requests failed for: ${failures.join(", ")}`);
  }
}

function changePaths(name: string): string[] {
  return [
    // Whichever versions.cue location the module's layout uses exists;
    // the caller filters on existence.
    join(MODULES_DIR, name, "templates/versions.cue"),
    join(MODULES_DIR, name, "templates/config/versions.cue"),
    join(MODULES_DIR, name, "templates/crds.cue"),
    join(MODULES_DIR, name, "VERSION"),
    join(MODULES_DIR, name, "README.md"),
    join("upengine/history", `${name}.json`),
  ];
}

async function createPullRequest(
  sources: ModuleSource[],
  change: SyncChange,
  baseSha: string,
  files: Map<string, string>,
): Promise<void> {
  const branch = `update/${change.name}`;
  const title = `Update ${change.name} to ${change.moduleVersion}`;

  await mustRun(["git", "checkout", "-B", branch, baseSha]);
  for (const [path, content] of files) {
    await Bun.write(path, content);
  }
  // Candidate paths absent from the snapshot are removed if the base
  // still tracks them (e.g. the flat versions.cue of a module that
  // migrated to the packages layout).
  for (const path of changePaths(change.name)) {
    if (!files.has(path)) {
      await run(["git", "rm", "-q", "--ignore-unmatch", "--", path]);
    }
  }
  // The README table is regenerated for this branch's content: this module
  // at the new version, everything else at the base version.
  await writeReadmeTable(await renderReadmeTable(sources));
  await mustRun(["git", "add", "README.md", ...files.keys()]);
  await mustRun(["git", "commit", "-s", "-m", title]);
  await mustRun(["git", "push", "--force", "origin", branch]);

  const existing = (await api(
    "GET",
    `/repos/${CATALOG_REPO}/pulls?head=${CATALOG_REPO.split("/")[0]}:${branch}&state=open`,
  )) as { number: number; node_id: string }[];
  let number: number;
  let nodeId: string;
  if (existing.length > 0) {
    number = existing[0]!.number;
    nodeId = existing[0]!.node_id;
    await api("PATCH", `/repos/${CATALOG_REPO}/pulls/${number}`, {
      title,
      body: renderChange(change),
    });
  } else {
    const created = (await api("POST", `/repos/${CATALOG_REPO}/pulls`, {
      title,
      head: branch,
      base: "main",
      body: renderChange(change),
    })) as { number: number; node_id: string };
    number = created.number;
    nodeId = created.node_id;
  }
  console.log(`::notice::PR #${number}: ${title}`);

  // Auto-merge is a GraphQL-only mutation; failure to enable it parks the
  // PR open instead of failing the run.
  const res = await fetchRetry(`${API_BASE}/graphql`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${botToken()}`,
      "Content-Type": "application/json",
      "User-Agent": "timonish-catalog-upengine",
    },
    body: JSON.stringify({
      query:
        "mutation($id: ID!) { enablePullRequestAutoMerge(input: {pullRequestId: $id, mergeMethod: REBASE}) { clientMutationId } }",
      variables: { id: nodeId },
    }),
  });
  const payload = (await res.json().catch(() => ({}))) as { errors?: { message: string }[] };
  if (!res.ok || payload.errors?.length) {
    console.warn(
      `::warning::auto-merge unavailable for PR #${number}: ${payload.errors?.[0]?.message ?? res.statusText}`,
    );
  }
}
