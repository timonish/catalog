// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { ROOT_DIR } from "./paths.ts";

export interface RunResult {
  stdout: string;
  stderr: string;
  exitCode: number;
}

/**
 * Runs a command by argv (never through a shell) from the repo root and
 * returns its output. Untrusted upstream data (tags, names) can therefore
 * only ever be an argument, not shell syntax.
 */
export async function run(
  argv: string[],
  opts: { stdin?: string; env?: Record<string, string> } = {},
): Promise<RunResult> {
  const proc = Bun.spawn(argv, {
    cwd: ROOT_DIR,
    stdout: "pipe",
    stderr: "pipe",
    stdin: opts.stdin === undefined ? "ignore" : new TextEncoder().encode(opts.stdin),
    env: opts.env === undefined ? process.env : { ...process.env, ...opts.env },
  });
  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  return { stdout, stderr, exitCode };
}

/** Like run, but a non-zero exit is an error carrying the tool output. */
export async function mustRun(
  argv: string[],
  opts: { stdin?: string; env?: Record<string, string> } = {},
): Promise<string> {
  const result = await run(argv, opts);
  if (result.exitCode !== 0) {
    throw new Error(`${argv.join(" ")} failed:\n${result.stderr || result.stdout}`);
  }
  return result.stdout;
}

/** Retries an argv command until it exits 0, with a fixed delay between
 * attempts; returns the last attempt's output or throws after the budget.
 * With `retryOn`, only failures whose output matches the pattern are
 * retried — anything else is deterministic and fails immediately. */
export async function retryRun(
  argv: string[],
  attempts: number,
  delayMs: number,
  opts: { env?: Record<string, string>; retryOn?: RegExp } = {},
): Promise<string> {
  let last: RunResult | null = null;
  for (let i = 0; i < attempts; i++) {
    last = await run(argv, { env: opts.env });
    if (last.exitCode === 0) {
      return last.stdout;
    }
    if (opts.retryOn !== undefined && !opts.retryOn.test(last.stderr + last.stdout)) {
      break;
    }
    await Bun.sleep(delayMs);
  }
  throw new Error(
    `${argv.join(" ")} did not succeed after retrying:\n${last?.stderr || last?.stdout}`,
  );
}
