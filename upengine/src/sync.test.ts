// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, test } from "bun:test";
import { parseConfig } from "./config.ts";
import { extractImages, parseImageRef } from "./manifests.ts";
import { parseModuleVersion, pickLatestRelease, semverOf, trackedImageTag } from "./resolve.ts";
import { renderVersionsCue } from "./codegen.ts";
import { renderChange } from "./summary.ts";

const VALID_CONFIG = {
  sources: [
    {
      name: "metrics-server",
      url: "https://github.com/kubernetes-sigs/metrics-server",
      releaseTag: "v*",
      manifests: { releaseAsset: "components.yaml" },
      images: {
        "metrics-server": { container: "metrics-server" },
        "addon-resizer": {
          url: "https://github.com/kubernetes/autoscaler",
          releaseTag: "addon-resizer-*",
          repository: "registry.k8s.io/autoscaling/addon-resizer",
        },
      },
    },
  ],
};

describe("parseConfig", () => {
  test("accepts a valid config", () => {
    const config = parseConfig(VALID_CONFIG);
    expect(config.sources).toHaveLength(1);
    const source = config.sources[0]!;
    expect(source.name).toBe("metrics-server");
    expect(source.manifests).toEqual({ kind: "releaseAsset", asset: "components.yaml" });
    expect(source.images.get("metrics-server")).toEqual({ kind: "container", container: "metrics-server" });
    expect(source.images.get("addon-resizer")).toMatchObject({ kind: "tracked" });
  });

  test("rejects unknown keys", () => {
    const doc = structuredClone(VALID_CONFIG) as Record<string, unknown>;
    (doc.sources as Record<string, unknown>[])[0]!.pin = 1;
    expect(() => parseConfig(doc)).toThrow("unknown keys: pin");
  });

  test("rejects duplicate names", () => {
    const doc = { sources: [VALID_CONFIG.sources[0], VALID_CONFIG.sources[0]] };
    expect(() => parseConfig(doc)).toThrow("duplicate name");
  });

  test("rejects container images without manifests", () => {
    const doc = structuredClone(VALID_CONFIG);
    delete (doc.sources[0] as Record<string, unknown>).manifests;
    expect(() => parseConfig(doc)).toThrow("'manifests' is required");
  });

  test("rejects a non-GitHub url", () => {
    const doc = structuredClone(VALID_CONFIG);
    doc.sources[0]!.url = "https://gitlab.com/foo/bar";
    expect(() => parseConfig(doc)).toThrow("not a GitHub repository URL");
  });
});

describe("versions", () => {
  test("parses module versions", () => {
    expect(parseModuleVersion("0.8.0-0\n")).toEqual({ upstream: "0.8.0", build: 0 });
    expect(parseModuleVersion("1.19.2-11")).toEqual({ upstream: "1.19.2", build: 11 });
    expect(() => parseModuleVersion("v0.8.0")).toThrow("invalid module version");
    expect(() => parseModuleVersion("0.8.0")).toThrow("invalid module version");
  });

  test("extracts the semver of a tag", () => {
    expect(semverOf("v0.9.0")).toBe("0.9.0");
    expect(semverOf("addon-resizer-1.8.24")).toBe("1.8.24");
  });

  test("strips the glob prefix from tracked image tags", () => {
    expect(trackedImageTag("addon-resizer-1.8.24", "addon-resizer-*")).toBe("1.8.24");
    expect(trackedImageTag("v1.2.3", "v*")).toBe("1.2.3");
  });

  test("picks the highest matching release", () => {
    const releases = [
      { tag_name: "metrics-server-helm-chart-3.13.0", draft: false, prerelease: false },
      { tag_name: "v0.9.0", draft: false, prerelease: false },
      { tag_name: "v0.8.0", draft: false, prerelease: false },
      { tag_name: "v0.10.0-rc.1", draft: false, prerelease: true },
    ];
    expect(pickLatestRelease(releases, "v*")).toBe("v0.9.0");
    expect(pickLatestRelease(releases, "metrics-server-helm-chart-*")).toBe(
      "metrics-server-helm-chart-3.13.0",
    );
    expect(() => pickLatestRelease(releases, "flux-*")).toThrow("no release tag matches");
  });
});

describe("manifests", () => {
  const STREAM = `
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
spec:
  template:
    spec:
      containers:
        - name: metrics-server
          image: registry.k8s.io/metrics-server/metrics-server:v0.9.0
`;

  test("extracts images by container name", () => {
    const images = extractImages(STREAM);
    expect(images.get("metrics-server")).toBe("registry.k8s.io/metrics-server/metrics-server:v0.9.0");
  });

  test("rejects conflicting images for one container name", () => {
    const conflicting = `${STREAM}\n---\nkind: DaemonSet\nspec:\n  template:\n    spec:\n      containers:\n        - name: metrics-server\n          image: other:v1\n`;
    expect(() => extractImages(conflicting)).toThrow("different images");
  });

  test("parses image references", () => {
    expect(parseImageRef("registry.k8s.io/metrics-server/metrics-server:v0.9.0")).toEqual({
      repository: "registry.k8s.io/metrics-server/metrics-server",
      tag: "v0.9.0",
      digest: "",
    });
    expect(parseImageRef("ghcr.io/org/app:v1@sha256:abc")).toEqual({
      repository: "ghcr.io/org/app",
      tag: "v1",
      digest: "sha256:abc",
    });
    expect(parseImageRef("registry.k8s.io/pause")).toEqual({
      repository: "registry.k8s.io/pause",
      tag: "",
      digest: "",
    });
  });
});

describe("rendering", () => {
  test("renders versions.cue deterministically", () => {
    const cue = renderVersionsCue(
      new Map([
        ["metrics-server", { repository: "registry.k8s.io/metrics-server/metrics-server", tag: "v0.9.0", digest: "" }],
      ]),
    );
    expect(cue).toBe(
      `// Code generated by upengine. DO NOT EDIT.

package templates

// The container images tracked from the upstream releases.
#defaultImages: {
\t"metrics-server": {
\t\trepository: "registry.k8s.io/metrics-server/metrics-server"
\t\ttag:        "v0.9.0"
\t\tdigest:     ""
\t}
}
`,
    );
  });

  test("renders a bump PR body", () => {
    const body = renderChange({
      name: "metrics-server",
      repo: "kubernetes-sigs/metrics-server",
      tag: "v0.9.0",
      prevModuleVersion: "0.8.0-0",
      moduleVersion: "0.9.0-0",
      images: {
        "metrics-server": {
          repository: "registry.k8s.io/metrics-server/metrics-server",
          tag: "v0.9.0",
          digest: "",
        },
      },
    });
    expect(body).toContain("## metrics-server 0.9.0-0");
    expect(body).toContain("`0.8.0-0` -> `0.9.0-0`");
    expect(body).toContain("| `registry.k8s.io/metrics-server/metrics-server` | v0.9.0 |");
  });
});
