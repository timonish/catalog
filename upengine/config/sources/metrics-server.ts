// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "metrics-server",
  url: "https://github.com/kubernetes-sigs/metrics-server",
  // In-repo chart, released on the interleaved metrics-server-helm-chart-*
  // tags.
  parityTarget: "https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server",
  releaseTag: "v*",
  manifests: { releaseAsset: "components.yaml" },
  images: {
    "metrics-server": { container: "metrics-server" },
    // The nanny image is not part of components.yaml; tracked from the
    // addon-resizer release line in the kubernetes/autoscaler monorepo.
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
};
