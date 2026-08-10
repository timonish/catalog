// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, test } from "bun:test";
import { validateSources } from "./config.ts";
import { sources as configuredSources } from "../config/sources.ts";
import { extractImages, normalizeCrdManifest, parseImageRef } from "./manifests.ts";
import { parseModuleVersion, pickLatestRelease, semverOf, trackedImageTag } from "./resolve.ts";
import { renderVersionsCue } from "./codegen.ts";
import { renderChange } from "./summary.ts";
import { plainDescription, renderModuleVersions, withModuleVersions } from "./readme.ts";
import type { ModuleSource } from "./types.ts";

const VALID: ModuleSource[] = [
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
    e2e: {
      namespace: "kube-system",
      verify: { argv: ["kubectl", "top", "nodes"] },
    },
  },
];

describe("validateSources", () => {
  test("accepts the checked-in config", () => {
    expect(validateSources(configuredSources)).toBe(configuredSources);
  });

  test("rejects duplicate names", () => {
    expect(() => validateSources([VALID[0]!, VALID[0]!])).toThrow("duplicate name");
  });

  test("rejects container images without manifests", () => {
    const source = { ...VALID[0]!, manifests: undefined };
    expect(() => validateSources([source])).toThrow("'manifests' is required");
  });

  test("rejects a non-GitHub url", () => {
    const source = { ...VALID[0]!, url: "https://gitlab.com/foo/bar" };
    expect(() => validateSources([source])).toThrow("not a GitHub repository URL");
  });

  test("rejects an invalid module name", () => {
    const source = { ...VALID[0]!, name: "Metrics_Server" };
    expect(() => validateSources([source])).toThrow("invalid name");
  });

  test("accepts a release image with a crds manifest", () => {
    const source: ModuleSource = {
      name: "external-dns",
      url: "https://github.com/kubernetes-sigs/external-dns",
      releaseTag: "v*",
      crds: { file: "charts/external-dns/crds/dnsendpoints.externaldns.k8s.io.yaml" },
      images: { "external-dns": { repository: "registry.k8s.io/external-dns/external-dns" } },
      e2e: { namespace: "external-dns", verify: { argv: ["kubectl", "get", "crd"] } },
    };
    expect(validateSources([source])).toEqual([source]);
  });

  test("rejects a release image with an empty repository", () => {
    const source = { ...VALID[0]!, images: { app: { repository: "" } } };
    expect(() => validateSources([source])).toThrow("'repository' must not be empty");
  });

  test("rejects an empty crds file", () => {
    const source = { ...VALID[0]!, crds: { file: "" } };
    expect(() => validateSources([source])).toThrow("must not be empty");
  });

  test("rejects an empty crds release asset", () => {
    const source = { ...VALID[0]!, crds: { releaseAsset: "" } };
    expect(() => validateSources([source])).toThrow("must not be empty");
  });

  test("rejects crds declaring both file and release asset", () => {
    const source = {
      ...VALID[0]!,
      crds: { file: "crds.yaml", releaseAsset: "crds.yaml" } as { file: string },
    };
    expect(() => validateSources([source])).toThrow("not both");
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
      // A prerelease semver with the GitHub flag mistakenly unset must not win.
      { tag_name: "v0.11.0-rc.1", draft: false, prerelease: false },
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

  test("handles separators with comments, CronJob and List documents", () => {
    const stream = [
      "kind: CronJob",
      "spec:",
      "  jobTemplate:",
      "    spec:",
      "      template:",
      "        spec:",
      "          containers:",
      "            - name: cleaner",
      "              image: registry.k8s.io/cleaner:v1",
      "--- # a comment after the separator",
      "kind: List",
      "items:",
      "  - kind: Deployment",
      "    spec:",
      "      template:",
      "        spec:",
      "          containers:",
      "            - name: app",
      "              image: registry.k8s.io/app:v2",
      "",
    ].join("\n");
    const images = extractImages(stream);
    expect(images.get("cleaner")).toBe("registry.k8s.io/cleaner:v1");
    expect(images.get("app")).toBe("registry.k8s.io/app:v2");
  });

  test("normalizes a chart-rendered CRD manifest", () => {
    const manifest = [
      "# release header",
      "apiVersion: apiextensions.k8s.io/v1",
      "kind: CustomResourceDefinition",
      "metadata:",
      '  name: "certificates.cert-manager.io"',
      "  annotations:",
      "    helm.sh/resource-policy: keep",
      "    controller-gen.kubebuilder.io/version: v0.21.0",
      "  labels:",
      "    app: cert-manager",
      "    helm.sh/chart: cert-manager-v1.21.1",
      "spec:",
      "  group: cert-manager.io",
      "---",
      "apiVersion: v1",
      "kind: Namespace",
      "metadata:",
      "  name: cert-manager",
      "---",
      "apiVersion: apiextensions.k8s.io/v1",
      "kind: CustomResourceDefinition",
      "metadata:",
      "  name: issuers.cert-manager.io",
      "  annotations:",
      "    helm.sh/resource-policy: keep",
      "  labels:",
      "    app: cert-manager",
      "spec:",
      "  group: cert-manager.io",
      "",
    ].join("\n");
    const normalized = normalizeCrdManifest(manifest);
    const docs = normalized.split(/^---$/m).map((d) => Bun.YAML.parse(d) as Record<string, any>);
    expect(docs.length).toBe(2);
    expect(docs.map((d) => d.metadata.name)).toEqual([
      "certificates.cert-manager.io",
      "issuers.cert-manager.io",
    ]);
    for (const doc of docs) {
      expect(doc.kind).toBe("CustomResourceDefinition");
      expect(doc.metadata.labels).toBeUndefined();
    }
    // Non-packaging annotations survive; emptied annotation maps are dropped.
    expect(docs[0]!.metadata.annotations).toEqual({
      "controller-gen.kubebuilder.io/version": "v0.21.0",
    });
    expect(docs[1]!.metadata.annotations).toBeUndefined();
  });

  test("rejects a CRD manifest without CRDs", () => {
    expect(() => normalizeCrdManifest("apiVersion: v1\nkind: Namespace\n")).toThrow(
      "no CustomResourceDefinition",
    );
  });

  test("rejects a CRD manifest with integers beyond JS precision", () => {
    const manifest = [
      "kind: CustomResourceDefinition",
      "metadata:",
      "  name: x.example.com",
      "spec:",
      "  bigDefault: 9007199254740993",
    ].join("\n");
    expect(() => normalizeCrdManifest(manifest)).toThrow("beyond safe JavaScript precision");
  });

  test("normalizes null metadata annotations", () => {
    const manifest = [
      "kind: CustomResourceDefinition",
      "metadata:",
      "  name: x.example.com",
      "  annotations: null",
      "spec: {}",
    ].join("\n");
    const doc = Bun.YAML.parse(normalizeCrdManifest(manifest)) as Record<string, any>;
    expect(doc.metadata).toEqual({name: "x.example.com"});
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
    const cue = renderVersionsCue({
      "metrics-server": { repository: "registry.k8s.io/metrics-server/metrics-server", tag: "v0.9.0", digest: "" },
    });
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

  test("renders versions.cue in the config package for multi-package modules", () => {
    const cue = renderVersionsCue(
      { controller: { repository: "quay.io/jetstack/cert-manager-controller", tag: "v1.21.1", digest: "" } },
      "packages",
    );
    expect(cue).toContain("\npackage config\n");
    expect(cue).toContain('repository: "quay.io/jetstack/cert-manager-controller"');
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

  test("strips markdown links from descriptions", () => {
    expect(
      plainDescription(
        "A [Timoni](https://timoni.sh) module for deploying [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server), a scalable source of metrics.",
      ),
    ).toBe("A Timoni module for deploying Kubernetes Metrics Server, a scalable source of metrics.");
    expect(plainDescription("No links here.")).toBe("No links here.");
  });

  test("renders the module readme version section", () => {
    const history = {
      name: "metrics-server",
      repo: "kubernetes-sigs/metrics-server",
      tag: "v0.9.0",
      commit: "2a7c4b2",
      moduleVersion: "0.9.0-1",
      images: {
        "metrics-server": { repository: "registry.k8s.io/metrics-server/metrics-server", tag: "v0.9.0", digest: "" },
        "addon-resizer": { repository: "registry.k8s.io/autoscaling/addon-resizer", tag: "1.8.24", digest: "" },
      },
      generatedDigest: "sha256:abc",
      updatedAt: "2026-08-09T00:00:00.000Z",
    };
    const section = renderModuleVersions(history);
    expect(section).not.toContain("#");
    expect(section).toContain("Latest module version is `0.9.0-1`, packaging the upstream release");
    expect(section).toContain(
      "[v0.9.0](https://github.com/kubernetes-sigs/metrics-server/releases/tag/v0.9.0)",
    );
    expect(section).toContain("| `registry.k8s.io/autoscaling/addon-resizer` | 1.8.24 |");

    const readme = "# metrics-server\n\nDesc.\n\n<!-- versions:start -->\nstale\n<!-- versions:end -->\n";
    const updated = withModuleVersions(readme, history);
    expect(updated).toContain(`<!-- versions:start -->\n${section}\n<!-- versions:end -->`);
    expect(withModuleVersions(updated, history)).toBe(updated);
    expect(() => withModuleVersions("# no markers\n", history)).toThrow("missing");
  });
});
