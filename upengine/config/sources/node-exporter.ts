// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "node-exporter",
  url: "https://github.com/prometheus/node_exporter",
  // Cross-repo: the chart lives in prometheus-community/helm-charts
  // while the releases are tracked from the upstream repo.
  // Deviations from the chart:
  // - kubeRBACProxy (with tlsSecret, the rbac ConfigMap and the
  //   rbac.create-gated ClusterRole/Binding, which the chart renders
  //   only for the proxy) is not reproduced — the module ships no
  //   RBAC at all.
  // - The permissionInitContainer (root chown/chmod for the opt-in
  //   rapl/slabinfo collectors) is not reproduced; the fix is
  //   achievable via `initContainers` mounting the always-present
  //   `proc`/`sys` host volumes.
  // - image.distroless and the `version` semver override are covered
  //   by the image tag/digest values; the udev path argument is
  //   always set (the tracked releases are past 1.4.0).
  // - restartPolicy is not exposed — DaemonSet pods only accept
  //   `Always`.
  // - extraManifests, releaseLabel, global.*, nameOverride,
  //   fullnameOverride and namespaceOverride are Helm mechanics.
  // - extraHostVolumeMounts, configmaps, secrets, sidecars,
  //   sidecarVolumeMount and sidecarHostVolumeMounts collapse into
  //   extraVolumes/extraVolumeMounts/extraContainers.
  // - The detached monitor namespaces are not reproduced — monitors
  //   live in the instance namespace.
  // - The chart deep-merges user affinity into its default
  //   nodeAffinity; the module's affinity value replaces the default
  //   wholesale.
  parityTarget: "https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-node-exporter",
  releaseTag: "v*",
  images: {
    // Published by the upstream tagged with the release tag itself.
    "node-exporter": { repository: "quay.io/prometheus/node-exporter" },
  },
  e2e: {
    namespace: "node-exporter",
    // The fixture Job scrapes the metrics endpoint through the
    // Service and asserts a real node metric series exists.
    verify: {
      argv: ["kubectl", "-n", "node-exporter", "wait", "job/e2e",
        "--for=condition=Complete", "--timeout=60s"],
    },
  },
};
