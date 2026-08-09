// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { MODULES_DIR } from "./paths.ts";
import { mustRun, retryRun, run } from "./proc.ts";
import type { ModuleSource } from "./types.ts";

/**
 * The end-to-end test of one module against the current kubectl context:
 * install (optionally from a just-pushed devel artifact), verify the addon
 * actually works, then uninstall and prove nothing is left behind. On any
 * failure, diagnostics are printed before the error propagates.
 */
export async function e2eModule(source: ModuleSource, registry?: string): Promise<void> {
  const version = "0.0.0-devel";
  let moduleRef = join(MODULES_DIR, source.name);
  if (registry !== undefined) {
    const url = `${registry}/modules/${source.name}`;
    console.log(`pushing ${url}`);
    await mustRun([
      "timoni",
      "mod",
      "push",
      moduleRef,
      url,
      "-v",
      version,
      "--resolve-symlinks",
    ]);
    moduleRef = url;
  }

  try {
    await install(source, moduleRef, version, registry !== undefined);
    await verify(source);
    await uninstall(source);
  } catch (err) {
    await diagnostics(source);
    throw err;
  }
  console.log(`${source.name}: e2e passed`);
}

async function install(
  source: ModuleSource,
  moduleRef: string,
  version: string,
  fromRegistry: boolean,
): Promise<void> {
  const argv = [
    "timoni",
    "-n",
    source.e2e.namespace,
    "apply",
    source.name,
    moduleRef,
    "--timeout=5m",
  ];
  if (fromRegistry) {
    argv.push("-v", version);
  }
  if (source.e2e.values !== undefined) {
    argv.push("--values", "-");
  }
  console.log(`installing ${source.name} in ${source.e2e.namespace}`);
  await mustRun(argv, { stdin: source.e2e.values });
}

async function verify(source: ModuleSource): Promise<void> {
  const check = source.e2e.verify;
  console.log(`verifying: ${check.argv.join(" ")}`);
  const output = await retryRun(check.argv, check.attempts ?? 30, (check.delaySeconds ?? 10) * 1000);
  console.log(output.trim());
}

async function uninstall(source: ModuleSource): Promise<void> {
  console.log(`uninstalling ${source.name}`);
  await mustRun(["timoni", "-n", source.e2e.namespace, "delete", source.name, "--timeout=5m"]);

  // Wait for the instance pods to drain.
  await retryRun(
    ["kubectl", "wait", "pod", "-l", `app.kubernetes.io/name=${source.name}`,
      "-n", source.e2e.namespace, "--for=delete", "--timeout=2m"],
    2,
    5000,
  );

  // Sweep for leftovers: cluster-scoped resources and bindings anywhere
  // whose name references the module.
  const clusterScoped = await mustRun([
    "kubectl", "get", "clusterrole,clusterrolebinding,apiservice", "-o", "name",
  ]);
  const leftovers = clusterScoped.split("\n").filter((l) => l.includes(source.name));
  const bindings = JSON.parse(
    await mustRun(["kubectl", "get", "rolebinding", "-A", "-o", "json"]),
  ) as { items: { metadata: { name: string; namespace: string } }[] };
  for (const item of bindings.items) {
    if (item.metadata.name.includes(source.name)) {
      leftovers.push(`rolebinding/${item.metadata.namespace}/${item.metadata.name}`);
    }
  }
  if (leftovers.length > 0) {
    throw new Error(`uninstall left resources behind:\n${leftovers.join("\n")}`);
  }
  console.log("uninstall clean");
}

async function diagnostics(source: ModuleSource): Promise<void> {
  console.log("--- diagnostics ---");
  for (const argv of [
    ["kubectl", "-n", source.e2e.namespace, "get", "pods", "-o", "wide"],
    ["kubectl", "-n", source.e2e.namespace, "describe", "deploy", source.name],
    ["kubectl", "-n", source.e2e.namespace, "logs", "-l", `app.kubernetes.io/name=${source.name}`,
      "--all-containers", "--tail=50"],
  ]) {
    const result = await run(argv);
    console.log(`$ ${argv.join(" ")}\n${result.stdout || result.stderr}`);
  }
}
