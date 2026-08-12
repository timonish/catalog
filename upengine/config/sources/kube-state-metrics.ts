// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "kube-state-metrics",
  url: "https://github.com/kubernetes/kube-state-metrics",
  // Cross-repo: the chart lives in prometheus-community/helm-charts
  // while the releases are tracked from the upstream repo.
  // Deviation: the chart's detached serviceMonitor namespace is not
  // reproduced — ServiceMonitors live in the instance namespace.
  parityTarget: "https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics",
  releaseTag: "v*",
  images: {
    // Published by the upstream tagged with the release tag itself.
    "kube-state-metrics": { repository: "registry.k8s.io/kube-state-metrics/kube-state-metrics" },
  },
  e2e: {
    namespace: "kube-state-metrics",
    // The fixture Job scrapes the metrics endpoint through the
    // headless Service and asserts a real metric series exists.
    verify: {
      argv: ["kubectl", "-n", "kube-state-metrics", "wait", "job/e2e",
        "--for=condition=Complete", "--timeout=60s"],
    },
  },
};
