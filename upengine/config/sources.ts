// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

// Module upstream declarations for `bun upengine/src/main.ts sync`, processed
// in order; results and reporting keep this order. Adding a module's
// automation is a config-only edit to this file, typechecked by `make lint`
// and validated by `validateSources` at runtime.

import type { ModuleSource } from "../src/types.ts";

export const sources: ModuleSource[] = [
  {
    name: "metrics-server",
    url: "https://github.com/kubernetes-sigs/metrics-server",
    // The repo interleaves metrics-server-helm-chart-* release tags.
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
      },
    },
    e2e: {
      namespace: "kube-system",
      // Kind's kubelet serving certificates are self-signed.
      values: 'values: args: ["--kubelet-insecure-tls"]',
      verify: { argv: ["kubectl", "top", "nodes"] },
    },
  },
];
