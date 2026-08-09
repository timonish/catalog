// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { join } from "node:path";
import { BUNDLES_DIR, MODULES_DIR } from "./paths.ts";
import { mustRun, retryRun, run } from "./proc.ts";
import type { ModuleSource } from "./types.ts";

/**
 * The end-to-end test of one module against the current kubectl context:
 * install the module's test bundle (optionally from a just-pushed devel
 * artifact), verify the addon actually works, then uninstall and prove
 * nothing is left behind. On any failure, diagnostics are printed before
 * the error propagates.
 */
export async function e2eModule(source: ModuleSource, registry?: string): Promise<void> {
  const version = "0.0.0-devel";
  let moduleUrl = `file://${join(MODULES_DIR, source.name)}`;
  if (registry !== undefined) {
    const url = `${registry}/modules/${source.name}`;
    console.log(`pushing ${url}`);
    await mustRun([
      "timoni",
      "mod",
      "push",
      join(MODULES_DIR, source.name),
      url,
      "-v",
      version,
      "--resolve-symlinks",
    ]);
    moduleUrl = url;
  }

  try {
    await install(source, moduleUrl, version);
    await verify(source);
    await uninstall(source);
  } catch (err) {
    await diagnostics(source);
    throw err;
  }
  console.log(`${source.name}: e2e passed`);
}

/**
 * Applies the module's test bundle from test/bundles/<name>/bundle.cue;
 * the bundle declares the instance values and reads the module url and
 * version from the environment, so the same bundle installs the local
 * worktree or a pushed devel artifact.
 */
async function install(source: ModuleSource, moduleUrl: string, version: string): Promise<void> {
  const bundlePath = join(BUNDLES_DIR, source.name, "bundle.cue");
  if (!(await Bun.file(bundlePath).exists())) {
    throw new Error(`test/bundles/${source.name}/bundle.cue not found`);
  }
  console.log(`installing ${source.name} in ${source.e2e.namespace} from ${moduleUrl}`);
  await mustRun(
    ["timoni", "bundle", "apply", "-f", bundlePath, "--runtime-from-env", "--timeout=5m"],
    { env: { E2E_MODULE_URL: moduleUrl, E2E_MODULE_VERSION: version } },
  );

  // Optional fixtures the verify check depends on, e.g. a custom resource
  // the addon is expected to reconcile.
  const fixtures = fixturesPath(source);
  if (await Bun.file(fixtures).exists()) {
    console.log(`applying test/bundles/${source.name}/fixtures.yaml`);
    await mustRun(["kubectl", "-n", source.e2e.namespace, "apply", "-f", fixtures]);
  }
}

function fixturesPath(source: ModuleSource): string {
  return join(BUNDLES_DIR, source.name, "fixtures.yaml");
}

async function verify(source: ModuleSource): Promise<void> {
  const check = source.e2e.verify;
  console.log(`verifying: ${check.argv.join(" ")}`);
  const output = await retryRun(check.argv, check.attempts ?? 30, (check.delaySeconds ?? 10) * 1000);
  console.log(output.trim());
}

async function uninstall(source: ModuleSource): Promise<void> {
  const fixtures = fixturesPath(source);
  if (await Bun.file(fixtures).exists()) {
    await mustRun([
      "kubectl", "-n", source.e2e.namespace, "delete", "-f", fixtures,
      "--ignore-not-found", "--wait",
    ]);
  }

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
  // whose name references the module. CRD names drop the dashes
  // (dnsendpoints.externaldns.k8s.io), so that spelling is matched too.
  const clusterScoped = await mustRun([
    "kubectl", "get", "clusterrole,clusterrolebinding,apiservice,crd", "-o", "name",
  ]);
  const compactName = source.name.replaceAll("-", "");
  const leftovers = clusterScoped
    .split("\n")
    .filter((l) => l.includes(source.name) || l.includes(compactName));
  const namespaced = JSON.parse(
    await mustRun(["kubectl", "get", "role,rolebinding", "-A", "-o", "json"]),
  ) as { items: { kind: string; metadata: { name: string; namespace: string } }[] };
  for (const item of namespaced.items) {
    if (item.metadata.name.includes(source.name)) {
      leftovers.push(
        `${item.kind.toLowerCase()}/${item.metadata.namespace}/${item.metadata.name}`,
      );
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
