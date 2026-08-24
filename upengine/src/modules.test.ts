// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, test } from "bun:test";
import { pushAnnotations, selectModules } from "./modules.ts";
import type { ModuleSource } from "./types.ts";

const SOURCES = ["cert-manager", "metrics-server", "trust-manager"].map(
  (name) => ({ name }) as ModuleSource,
);

describe("selectModules", () => {
  test("selects nothing for docs-only changes", () => {
    expect(selectModules(SOURCES, ["README.md", "docs/internal/maintenance.md"])).toEqual([]);
  });

  test("maps per-module data files to their module", () => {
    expect(
      selectModules(SOURCES, [
        "modules/metrics-server/templates/config.cue",
        "upengine/config/sources/cert-manager.ts",
        "upengine/history/cert-manager.json",
        "test/bundles/trust-manager/bundle.cue",
      ]),
    ).toEqual(["cert-manager", "metrics-server", "trust-manager"]);
  });

  test("keeps source order and ignores unknown module names", () => {
    expect(
      selectModules(SOURCES, ["modules/trust-manager/README.md", "modules/gone/README.md"]),
    ).toEqual(["trust-manager"]);
  });

  test("selects all modules for engine changes", () => {
    for (const file of [
      "upengine/src/sync.ts",
      "upengine/config/sources.ts",
      "schemas/cue.mod/gen/k8s.io/api/core/v1/types_gen.cue",
      "Makefile",
      ".github/workflows/e2e.yaml",
    ]) {
      expect(selectModules(SOURCES, [file]).length).toBe(SOURCES.length);
    }
  });
});

describe("pushAnnotations", () => {
  test("emits the OCI standard annotations only", () => {
    const args = pushAnnotations("app", "deadbeef", "An app.");
    expect(args.filter((a) => a === "-a")).toHaveLength(5);
    expect(args).toContain("org.opencontainers.image.revision=deadbeef");
    expect(args).toContain("org.opencontainers.image.description=An app.");
    expect(args).toContain(
      "org.opencontainers.image.documentation=https://github.com/timonish/catalog/blob/main/modules/app/README.md",
    );
    expect(args.some((a) => a.startsWith("sh.timoni."))).toBe(false);
  });
});
