// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "external-dns",
  url: "https://github.com/kubernetes-sigs/external-dns",
  // In-repo chart, released on the interleaved external-dns-helm-chart-*
  // tags. Deviation: the chart's detached serviceMonitor namespace is
  // not reproduced — ServiceMonitors live in the instance namespace.
  parityTarget: "https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns",
  releaseTag: "v*",
  crds: { file: "charts/external-dns/crds/dnsendpoints.externaldns.k8s.io.yaml" },
  images: {
    // Published by the upstream tagged with the release tag itself.
    "external-dns": { repository: "registry.k8s.io/external-dns/external-dns" },
  },
  e2e: {
    namespace: "external-dns",
    // The crd source records the processed generation on the DNSEndpoint
    // fixture; --dry-run in the test bundle keeps the provider untouched.
    verify: {
      argv: ["kubectl", "-n", "external-dns", "wait", "dnsendpoint/e2e",
        "--for=jsonpath={.status.observedGeneration}=1", "--timeout=10s"],
    },
  },
};
