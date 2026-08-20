// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, test } from "bun:test";
import { IMAGES_ANNOTATION, imagesAnnotation, pushAnnotations, selectModules } from "./modules.ts";
import type { HistoryEntry, ModuleSource } from "./types.ts";

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

describe("imagesAnnotation", () => {
  test("renders pinned references, sorted", () => {
    expect(
      imagesAnnotation({
        "metrics-server": {
          repository: "registry.k8s.io/metrics-server/metrics-server",
          tag: "v0.9.0",
          digest: "sha256:aaa",
        },
        "addon-resizer": {
          repository: "registry.k8s.io/autoscaling/addon-resizer",
          tag: "1.8.24",
          digest: "sha256:bbb",
        },
      }),
    ).toBe(
      "registry.k8s.io/autoscaling/addon-resizer:1.8.24@sha256:bbb," +
        "registry.k8s.io/metrics-server/metrics-server:v0.9.0@sha256:aaa",
    );
  });

  test("omits the tag for digest-only images", () => {
    expect(imagesAnnotation({ app: { repository: "r/app", tag: "", digest: "sha256:abc" } })).toBe(
      "r/app@sha256:abc",
    );
  });

  test("is empty for CRDs-only modules", () => {
    expect(imagesAnnotation({})).toBe("");
  });

  test("rejects images without a digest", () => {
    expect(() => imagesAnnotation({ app: { repository: "r", tag: "t", digest: "" } })).toThrow(
      "image 'app' has no digest",
    );
  });
});

describe("pushAnnotations", () => {
  test("emits the images annotation alongside the OCI standard ones", () => {
    const history = {
      images: { app: { repository: "ghcr.io/org/app", tag: "1.0.0", digest: "sha256:abc" } },
    } as unknown as HistoryEntry;
    const args = pushAnnotations("app", "deadbeef", "An app.", history);
    expect(args.filter((a) => a === "-a")).toHaveLength(6);
    expect(args).toContain("org.opencontainers.image.revision=deadbeef");
    expect(args).toContain("org.opencontainers.image.description=An app.");
    expect(args).toContain(`${IMAGES_ANNOTATION}=ghcr.io/org/app:1.0.0@sha256:abc`);
  });

  test("omits the images annotation when the module has no images", () => {
    const history = { images: {} } as unknown as HistoryEntry;
    const args = pushAnnotations("crds", "rev", "CRDs.", history);
    expect(args.some((a) => a.startsWith(IMAGES_ANNOTATION))).toBe(false);
    expect(args).toContain("org.opencontainers.image.revision=rev");
  });

  test("rejects a history manifest without an images map", () => {
    expect(() => pushAnnotations("app", "rev", "An app.", {} as HistoryEntry)).toThrow(
      "has no images map",
    );
  });
});
