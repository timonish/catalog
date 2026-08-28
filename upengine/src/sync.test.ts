// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import { describe, expect, test } from "bun:test";
import { crdChannels, validateSources } from "./config.ts";
import { sources as configuredSources } from "../config/sources.ts";
import { extractImages, normalizeCrdManifest, parseImageRef } from "./manifests.ts";
import {
  artifactDigestArgv,
  fileVariableTag,
  parseArtifactDigest,
  parseModuleVersion,
  pickLatestRelease,
  semverOf,
  trackedImageTag,
} from "./resolve.ts";
import { GENERATED_FILE_RE, crdsCuePaths, generatedFilesPresent, renderImagesCue } from "./codegen.ts";
import { ciSources, parseModuleList } from "./modules.ts";
import { renderChange, renderSyncSummary } from "./summary.ts";
import {
  plainDescription,
  renderModuleVersions,
  renderReadmeTable,
  validateDescription,
  validatePrerequisites,
  withModuleVersions,
} from "./readme.ts";
import type { ModuleSource } from "./types.ts";

const VALID: ModuleSource[] = [
  {
    name: "metrics-server",
    url: "https://github.com/kubernetes-sigs/metrics-server",
    parityTarget: "https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server",
    releaseTag: "v*",
    manifests: { releaseAsset: "components.yaml" },
    images: {
      "metrics-server": { container: "metrics-server" },
      "addon-resizer": {
        url: "https://github.com/kubernetes/autoscaler",
        releaseTag: "addon-resizer-*",
        repository: "registry.k8s.io/autoscaling/addon-resizer",
        path: "addonResizer.image",
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

  test("renders the sync summary with failures and the totals line", () => {
    const change = {
      name: "gateway-api",
      repo: "kubernetes-sigs/gateway-api",
      tag: "v1.6.1",
      prevModuleVersion: "1.6.0-0",
      moduleVersion: "1.6.1-0",
      images: {},
    };
    const failure = { name: "envoy-gateway", message: "digest lookup failed" };
    const summary = renderSyncSummary([change], [failure], 12);
    expect(summary).toContain(renderChange(change));
    expect(summary).toContain("## Failures\n\n- **envoy-gateway**: digest lookup failed\n");
    expect(summary.endsWith("1 module(s) updated, 1 failed, 12 up to date.")).toBe(true);
  });

  test("renders a summary without changes or failures as the totals line only", () => {
    expect(renderSyncSummary([], [], 14)).toBe("0 module(s) updated, 0 failed, 14 up to date.");
    expect(renderSyncSummary([], [], 14)).not.toContain("## Failures");
  });

  test("rejects container images without manifests", () => {
    const source = { ...VALID[0]!, manifests: undefined };
    expect(() => validateSources([source])).toThrow("'manifests' is required");
  });

  test("rejects a non-GitHub url", () => {
    const source = { ...VALID[0]!, url: "https://gitlab.com/foo/bar" };
    expect(() => validateSources([source])).toThrow("not a GitHub repository URL");
  });

  test("rejects a non-https parityTarget", () => {
    const source = { ...VALID[0]!, parityTarget: "charts/metrics-server" };
    expect(() => validateSources([source])).toThrow("'parityTarget' must be an https URL");
  });

  test("rejects an invalid module name", () => {
    const source = { ...VALID[0]!, name: "Metrics_Server" };
    expect(() => validateSources([source])).toThrow("invalid name");
  });

  test("accepts a release image with a crds manifest", () => {
    const source: ModuleSource = {
      name: "external-dns",
      url: "https://github.com/kubernetes-sigs/external-dns",
      parityTarget: "https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns",
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

  test("rejects an invalid image values path", () => {
    const source = {
      ...VALID[0]!,
      images: { app: { repository: "quay.io/x", path: "addon-resizer.image" } },
    };
    expect(() => validateSources([source])).toThrow("invalid values 'path'");
  });

  test("rejects images with colliding values paths", () => {
    // Two images without a path both default to `image`.
    const twoDefaults = {
      ...VALID[0]!,
      images: { app: { repository: "quay.io/x" }, sidecar: { repository: "quay.io/y" } },
    };
    expect(() => validateSources([twoDefaults])).toThrow("collides with");
    // A path nested under another image's path unifies with its defaults.
    const nested = {
      ...VALID[0]!,
      images: {
        app: { repository: "quay.io/x" },
        sidecar: { repository: "quay.io/y", path: "image.sidecar" },
      },
    };
    expect(() => validateSources([nested])).toThrow("collides with");
  });

  test("accepts a file-variable image", () => {
    const source = {
      ...VALID[0]!,
      images: {
        pkg: {
          repository: "quay.io/jetstack/trust-pkg-debian-trixie",
          file: "make/00_debian_trixie_version.mk",
          variable: "DEBIAN_TRIXIE_BUNDLE_VERSION",
        },
      },
    };
    expect(validateSources([source])).toEqual([source]);
  });

  test("rejects a file-variable image with an empty file", () => {
    const source = {
      ...VALID[0]!,
      images: { pkg: { repository: "quay.io/x", file: "", variable: "VERSION" } },
    };
    expect(() => validateSources([source])).toThrow("'file' and 'repository' must not be empty");
  });

  test("rejects a file-variable image with an invalid variable name", () => {
    const source = {
      ...VALID[0]!,
      images: { pkg: { repository: "quay.io/x", file: "v.mk", variable: "NOT A NAME" } },
    };
    expect(() => validateSources([source])).toThrow("invalid 'variable' name");
  });

  test("rejects an image combining variant marker keys", () => {
    const image = {
      repository: "quay.io/x",
      url: "https://github.com/o/r",
      releaseTag: "v*",
      file: "v.mk",
      variable: "V",
    } as unknown as ModuleSource["images"];
    const source = { ...VALID[0]!, images: { pkg: image } } as unknown as ModuleSource;
    expect(() => validateSources([source])).toThrow("cannot be combined");
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

  const CRDS_ONLY: ModuleSource = {
    name: "gateway-api",
    url: "https://github.com/kubernetes-sigs/gateway-api",
    parityTarget: "https://github.com/kubernetes-sigs/gateway-api/releases",
    releaseTag: "v*",
    crds: {
      channels: {
        standard: { releaseAsset: "standard-install.yaml" },
        experimental: { releaseAsset: "experimental-install.yaml" },
      },
      keepKinds: ["ValidatingAdmissionPolicy"],
      keepLabels: true,
    },
    e2e: {
      ci: false,
      namespace: "gateway-system",
      verify: { argv: ["kubectl", "get", "gatewayclass", "e2e"] },
    },
  };

  test("accepts a CRDs-only module with channels and no images", () => {
    expect(validateSources([CRDS_ONLY])).toEqual([CRDS_ONLY]);
  });

  test("rejects a module without images and without crds", () => {
    const source = { ...CRDS_ONLY, crds: undefined };
    expect(() => validateSources([source])).toThrow("must declare 'images' or 'crds'");
  });

  test("rejects declared-but-empty images", () => {
    const source = { ...CRDS_ONLY, images: {} };
    expect(() => validateSources([source])).toThrow("'images' must not be empty");
  });

  test("rejects empty crds channels", () => {
    const source = { ...CRDS_ONLY, crds: { channels: {} } };
    expect(() => validateSources([source])).toThrow("'channels' must not be empty");
  });

  test("rejects an invalid channel name", () => {
    const source = { ...CRDS_ONLY, crds: { channels: { "Standard!": { file: "crds.yaml" } } } };
    expect(() => validateSources([source])).toThrow("invalid channel name");
  });

  test("rejects a channel input declaring both file and release asset", () => {
    const source = {
      ...CRDS_ONLY,
      crds: { channels: { standard: { file: "a.yaml", releaseAsset: "b.yaml" } as { file: string } } },
    };
    expect(() => validateSources([source])).toThrow("not both");
  });

  test("rejects channels combined with a single input", () => {
    const crds = {
      channels: { standard: { file: "a.yaml" } },
      file: "b.yaml",
    } as unknown as ModuleSource["crds"];
    expect(() => validateSources([{ ...CRDS_ONLY, crds }])).toThrow("cannot be combined");
  });

  test("rejects empty keepKinds entries", () => {
    const source = { ...CRDS_ONLY, crds: { ...CRDS_ONLY.crds!, keepKinds: [""] } };
    expect(() => validateSources([source])).toThrow("'keepKinds' entries must not be empty");
  });

  test("maps crds inputs to channels", () => {
    expect(crdChannels(undefined)).toEqual({});
    expect(crdChannels({ file: "crds.yaml" })).toEqual({ "": { file: "crds.yaml" } });
    expect(Object.keys(crdChannels(CRDS_ONLY.crds))).toEqual(["standard", "experimental"]);
  });

  test("computes the generated crds paths per channel", () => {
    const suffixes = (paths: string[]) => paths.map((p) => p.split("/modules/")[1]);
    expect(suffixes(crdsCuePaths("external-dns", { file: "crds.yaml" }))).toEqual([
      "external-dns/templates/crds.cue",
    ]);
    expect(suffixes(crdsCuePaths("gateway-api", CRDS_ONLY.crds))).toEqual([
      "gateway-api/templates/crds_standard.cue",
      "gateway-api/templates/crds_experimental.cue",
    ]);
    expect(crdsCuePaths("metrics-server", undefined)).toEqual([]);
  });

  test("filters e2e.ci: false sources out of the CI matrix", () => {
    expect(ciSources([VALID[0]!, CRDS_ONLY]).map((s) => s.name)).toEqual(["metrics-server"]);
  });

  test("matches the generated file paths", () => {
    for (const path of [
      "modules/a/images.cue",
      "modules/a/templates/crds.cue",
      "modules/a/templates/crds_standard.cue",
    ]) {
      expect(GENERATED_FILE_RE.test(path)).toBe(true);
    }
    for (const path of [
      "modules/a/templates/config.cue",
      "modules/a/values.cue",
      "modules/a/templates/images.cue",
      "modules/a/templates/crds_standard.cue.bak",
      "modules/a/README.md",
    ]) {
      expect(GENERATED_FILE_RE.test(path)).toBe(false);
    }
  });

  test("detects missing expected generated files", async () => {
    // Every checked-in module carries all the files its declaration expects.
    for (const source of configuredSources) {
      expect(await generatedFilesPresent(source)).toBe(true);
    }
    // A channel declared in sources.ts but absent on disk must re-sync.
    const gatewayApi = configuredSources.find((s) => s.name === "gateway-api")!;
    const withNewChannel: ModuleSource = {
      ...gatewayApi,
      crds: { channels: { standard: { releaseAsset: "standard-install.yaml" }, nightly: { releaseAsset: "nightly.yaml" } } },
    };
    expect(await generatedFilesPresent(withNewChannel)).toBe(false);
    // Freshly declared images without an images.cue must re-sync.
    const withImages: ModuleSource = {
      ...gatewayApi,
      images: { app: { repository: "registry.k8s.io/app" } },
    };
    expect(await generatedFilesPresent(withImages)).toBe(false);
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

  test("extracts file-variable image tags", () => {
    const mk = [
      "# comment",
      "DEBIAN_TRIXIE_BUNDLE_VERSION := 20250419.1",
      "DEBIAN_TRIXIE_BUNDLE_SOURCE_IMAGE=docker.io/library/debian:13-slim",
      "",
    ].join("\n");
    const pkg = "quay.io/jetstack/trust-pkg-debian-trixie";
    expect(fileVariableTag(mk, "DEBIAN_TRIXIE_BUNDLE_VERSION", "v.mk", pkg)).toBe("20250419.1");
    // Debian version characters illegal in OCI tags map to '-'.
    expect(fileVariableTag("V := 20250419+deb13~1\n", "V", "v.mk", pkg)).toBe("20250419-deb13-1");
    expect(() => fileVariableTag(mk, "MISSING", "v.mk", pkg)).toThrow(
      "variable 'MISSING' not found in v.mk",
    );
    // The variable name must match the whole identifier, not a prefix of a
    // longer one.
    expect(() => fileVariableTag("PREFIXED_V := 1\n", "V", "v.mk", pkg)).toThrow("not found");
  });

  test("extracts the tag of a full-reference file variable", () => {
    // A Go constant, as the envoy-gateway controller declares the images
    // it deploys.
    const go = [
      "const (",
      '\t// DefaultEnvoyProxyImage is the default image used by envoyproxy',
      '\tDefaultEnvoyProxyImage = "docker.io/envoyproxy/envoy:distroless-v1.39.0"',
      '\tDefaultRateLimitImage = "docker.io/envoyproxy/ratelimit:17b1956c"',
      ")",
      "",
    ].join("\n");
    expect(
      fileVariableTag(go, "DefaultEnvoyProxyImage", "shared_types.go", "docker.io/envoyproxy/envoy"),
    ).toBe("distroless-v1.39.0");
    expect(
      fileVariableTag(go, "DefaultRateLimitImage", "shared_types.go", "docker.io/envoyproxy/ratelimit"),
    ).toBe("17b1956c");
    // A repository the upstream moved away from must fail the sync instead
    // of pinning a tag of a different image.
    expect(() =>
      fileVariableTag(go, "DefaultEnvoyProxyImage", "shared_types.go", "ghcr.io/envoyproxy/envoy"),
    ).toThrow("references 'docker.io/envoyproxy/envoy', expected 'ghcr.io/envoyproxy/envoy'");
    // A reference without a tag carries no version to pin.
    expect(() =>
      fileVariableTag('I = "docker.io/envoyproxy/envoy"\n', "I", "t.go", "docker.io/envoyproxy/envoy"),
    ).toThrow("without a tag");
    // A registry-less reference is a reference, not a version: its name
    // must never end up pinned as the tag.
    expect(() => fileVariableTag('I = "envoy:v1"\n', "I", "t.go", "docker.io/envoyproxy/envoy")).toThrow(
      "references 'envoy', expected 'docker.io/envoyproxy/envoy'",
    );
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

  test("parses timoni mod list JSON output", () => {
    const stdout = JSON.stringify([
      { name: "", repository: "oci://ghcr.io/timonish/modules/metrics-server", version: "latest", digest: "" },
      { name: "", repository: "oci://ghcr.io/timonish/modules/metrics-server", version: "0.9.0-2", digest: "" },
    ]);
    expect(parseModuleList(stdout)).toEqual(["latest", "0.9.0-2"]);
    expect(parseModuleList("[]")).toEqual([]);
    expect(() => parseModuleList(`{"version":"1.0.0"}`)).toThrow("JSON array");
    expect(() => parseModuleList(`[{"name":""}]`)).toThrow("no version");
  });

  test("builds the digest lookup argv", () => {
    const argv = artifactDigestArgv({
      repository: "registry.k8s.io/metrics-server/metrics-server",
      tag: "v0.9.0",
      digest: "",
    });
    expect(argv).toEqual([
      "timoni", "artifact", "digest", "oci://registry.k8s.io/metrics-server/metrics-server:v0.9.0", "-o", "json",
    ]);
  });

  test("parses timoni artifact digest JSON output", () => {
    const ref = { repository: "registry.k8s.io/autoscaling/addon-resizer", tag: "1.8.24", digest: "" };
    const digest = "sha256:0d97e9dd5adb46a05fb1eebd1e1b73eee3f5741621ed6247131c99672c2b6ab0";
    const stdout = JSON.stringify({ repository: `oci://${ref.repository}`, tag: "1.8.24", digest });
    expect(parseArtifactDigest(stdout, ref)).toBe(digest);
    expect(() => parseArtifactDigest("[]", ref)).toThrow("JSON object");
    const repository = `oci://${ref.repository}`;
    expect(() => parseArtifactDigest(JSON.stringify({ repository, tag: "1.8.25", digest }), ref)).toThrow(
      "answered for 'oci://registry.k8s.io/autoscaling/addon-resizer:1.8.25'",
    );
    expect(() =>
      parseArtifactDigest(JSON.stringify({ repository: "oci://docker.io/other/addon-resizer", tag: "1.8.24", digest }), ref),
    ).toThrow("answered for");
    expect(() =>
      parseArtifactDigest(JSON.stringify({ repository, tag: "1.8.24", digest: "" }), ref),
    ).toThrow("no digest resolved");
    const hub = { repository: "docker.io/envoyproxy/gateway", tag: "v1.9.1", digest: "" };
    const answered = { repository: "oci://index.docker.io/envoyproxy/gateway", tag: "v1.9.1", digest };
    expect(parseArtifactDigest(JSON.stringify(answered), hub)).toBe(digest);
    expect(parseArtifactDigest(JSON.stringify({ ...answered, repository: "oci://docker.io/envoyproxy/gateway" }), hub)).toBe(digest);
    expect(() =>
      parseArtifactDigest(JSON.stringify({ ...answered, repository: "oci://ghcr.io/envoyproxy/gateway" }), hub),
    ).toThrow("answered for");
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

  test("keeps declared kinds and labels when asked", () => {
    const manifest = [
      "apiVersion: apiextensions.k8s.io/v1",
      "kind: CustomResourceDefinition",
      "metadata:",
      "  name: gateways.gateway.networking.k8s.io",
      "  annotations:",
      "    gateway.networking.k8s.io/channel: standard",
      "  labels:",
      "    gateway.networking.k8s.io/policy: Direct",
      "spec:",
      "  group: gateway.networking.k8s.io",
      "---",
      "apiVersion: admissionregistration.k8s.io/v1",
      "kind: ValidatingAdmissionPolicy",
      "metadata:",
      "  name: safe-upgrades.gateway.networking.k8s.io",
      "spec: {}",
      "---",
      "apiVersion: v1",
      "kind: Namespace",
      "metadata:",
      "  name: dropped",
      "",
    ].join("\n");
    const normalized = normalizeCrdManifest(manifest, {
      keepKinds: ["ValidatingAdmissionPolicy"],
      keepLabels: true,
    });
    const docs = normalized.split(/^---$/m).map((d) => Bun.YAML.parse(d) as Record<string, any>);
    expect(docs.map((d) => d.kind)).toEqual(["CustomResourceDefinition", "ValidatingAdmissionPolicy"]);
    expect(docs[0]!.metadata.labels).toEqual({ "gateway.networking.k8s.io/policy": "Direct" });
    expect(docs[0]!.metadata.annotations).toEqual({ "gateway.networking.k8s.io/channel": "standard" });
  });

  test("rejects a kept-kinds manifest without CRDs", () => {
    const manifest = "apiVersion: admissionregistration.k8s.io/v1\nkind: ValidatingAdmissionPolicy\nmetadata:\n  name: x\n";
    expect(() => normalizeCrdManifest(manifest, { keepKinds: ["ValidatingAdmissionPolicy"] })).toThrow(
      "no CustomResourceDefinition",
    );
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
  test("renders images.cue deterministically", () => {
    const cue = renderImagesCue(
      {
        "metrics-server": { repository: "registry.k8s.io/metrics-server/metrics-server", tag: "v0.9.0", digest: "" },
      },
      {},
    );
    expect(cue).toBe(
      `// Code generated by upengine. DO NOT EDIT.

package main

// The container images tracked from the upstream releases.
values: {
\timage: {
\t\trepository: *"registry.k8s.io/metrics-server/metrics-server" | string
\t\ttag:        *"v0.9.0" | string
\t\tdigest:     *"" | string
\t}
}
`,
    );
  });

  test("renders images.cue at the declared values paths", () => {
    const cue = renderImagesCue(
      {
        controller: { repository: "quay.io/jetstack/cert-manager-controller", tag: "v1.21.1", digest: "" },
        webhook: { repository: "quay.io/jetstack/cert-manager-webhook", tag: "v1.21.1", digest: "" },
      },
      { controller: "controller.image", webhook: "webhook.image" },
    );
    expect(cue).toContain('\tcontroller: image: {');
    expect(cue).toContain('\twebhook: image: {');
    expect(cue).toContain('repository: *"quay.io/jetstack/cert-manager-controller" | string');
  });

  test("rejects values path labels that need quoting", () => {
    const images = { app: { repository: "registry.k8s.io/app", tag: "v1", digest: "" } };
    expect(() => renderImagesCue(images, { app: "addon-resizer.image" })).toThrow(
      "not a dotted list of CUE labels",
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

  test("renders an image-less bump PR body without a table", () => {
    const body = renderChange({
      name: "gateway-api",
      repo: "kubernetes-sigs/gateway-api",
      tag: "v1.6.1",
      prevModuleVersion: "1.6.0-0",
      moduleVersion: "1.6.1-0",
      images: {},
    });
    expect(body).toContain("## gateway-api 1.6.1-0");
    expect(body).not.toContain("| Image | Tag |");
  });

  test("renders an image-less module readme version section", () => {
    const section = renderModuleVersions({
      name: "gateway-api",
      repo: "kubernetes-sigs/gateway-api",
      tag: "v1.6.1",
      commit: "abc",
      moduleVersion: "1.6.1-0",
      moduleReleases: [
        { version: "1.6.1-0", releasedAt: "2026-08-10T00:00:00.000Z" },
        { version: "1.6.0-0", releasedAt: "2026-08-01T00:00:00.000Z" },
      ],
      images: {},
      generatedDigest: "sha256:abc",
      updatedAt: "2026-08-10T00:00:00.000Z",
    });
    expect(section).toBe(
      "Latest module version is `1.6.1-0`, packaging the upstream release\n" +
        "[v1.6.1](https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.6.1).",
    );
  });

  test("renders the modules table ordered by name from the sources alone", () => {
    const table = renderReadmeTable(configuredSources);
    const lines = table.split("\n");
    expect(lines[0]).toBe("| Module | Upstream |");
    const names = lines.slice(2).map((l) => l.match(/^\| \[([^\]]+)\]/)![1]);
    expect(names).toEqual([...names].sort());
    expect(names).toHaveLength(configuredSources.length);
  });

  test("validates the description line shape", () => {
    const valid =
      "A [Timoni](https://timoni.sh) module for deploying [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics), an agent that generates Prometheus metrics about the state of Kubernetes objects.";
    expect(() => validateDescription("ksm", valid)).not.toThrow();
    // The gateway-api form with a 'the' article.
    expect(() =>
      validateDescription(
        "gateway-api",
        "A [Timoni](https://timoni.sh) module for deploying the [Kubernetes Gateway API](https://github.com/kubernetes-sigs/gateway-api) custom resource definitions, consumed by ingress controllers and service meshes.",
      ),
    ).not.toThrow();
    expect(() =>
      validateDescription("x", "A [Timoni](https://timoni.sh) module for deploying [X](https://x) to Kubernetes clusters."),
    ).toThrow("must match");
    expect(() => validateDescription("x", 'A module for "X".')).toThrow("must match");
  });

  test("validates the prerequisites section shape", () => {
    const valid =
      "# m\n\nDesc.\n\n## Prerequisites\n\n- Kubernetes 1.25+\n- [Timoni](https://timoni.sh/install/) 0.31+\n- Extra dependency\n\n## Install\n";
    expect(() => validatePrerequisites("m", valid, "0.31")).not.toThrow();
    expect(() => validatePrerequisites("m", "# m\n\nDesc.\n", "0.31")).toThrow("no '## Prerequisites'");
    expect(() =>
      validatePrerequisites("m", "# m\n\n## Prerequisites\n\n- Kubernetes 1.25 or newer\n- [Timoni](https://timoni.sh/install/) 0.31+\n", "0.31"),
    ).toThrow("first prerequisite");
    expect(() =>
      validatePrerequisites("m", "# m\n\n## Prerequisites\n\n- Kubernetes 1.25+\n- Timoni 0.30+\n", "0.31"),
    ).toThrow("second prerequisite");
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
      moduleReleases: [
        { version: "0.9.0-1", releasedAt: "2026-08-09T00:00:00.000Z" },
        { version: "0.9.0-0", releasedAt: "2026-08-01T00:00:00.000Z" },
      ],
      images: {
        "metrics-server": {
          repository: "registry.k8s.io/metrics-server/metrics-server",
          tag: "v0.9.0",
          digest: "sha256:1c2b2ac30e04466f8b96fb245248b2a1c3d21a7ec3fbfef0b98cabf294f1c3dc",
        },
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
    expect(section).toContain("| Image | Tag | Digest |");
    expect(section).toContain(
      "| `registry.k8s.io/metrics-server/metrics-server` | v0.9.0 | `sha256:1c2b2ac30e04466f8b96fb245248b2a1c3d21a7ec3fbfef0b98cabf294f1c3dc` |",
    );
    // A module synced before digest pinning renders an empty digest cell.
    expect(section).toContain("| `registry.k8s.io/autoscaling/addon-resizer` | 1.8.24 |  |");

    // A section with no digests at all keeps the pre-pinning table shape.
    const legacy = renderModuleVersions({
      ...history,
      images: {
        "addon-resizer": { repository: "registry.k8s.io/autoscaling/addon-resizer", tag: "1.8.24", digest: "" },
      },
    });
    expect(legacy).toContain("| Image | Tag |");
    expect(legacy).not.toContain("Digest");

    const readme = "# metrics-server\n\nDesc.\n\n<!-- versions:start -->\nstale\n<!-- versions:end -->\n";
    const updated = withModuleVersions(readme, history);
    expect(updated).toContain(`<!-- versions:start -->\n${section}\n<!-- versions:end -->`);
    expect(withModuleVersions(updated, history)).toBe(updated);
    expect(() => withModuleVersions("# no markers\n", history)).toThrow("missing");
  });
});
