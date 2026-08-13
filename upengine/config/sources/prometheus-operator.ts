// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "prometheus-operator",
  url: "https://github.com/prometheus-operator/prometheus-operator",
  // Cross-repo: the de-facto chart is kube-prometheus-stack; the parity
  // surface is its prometheusOperator values section and the
  // templates/prometheus-operator/ templates only.
  parityTarget: "https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack",
  releaseTag: "v*",
  // The release bundle carries the full CRD schemas (kubectl explain
  // works); the default normalization keeps only the CRD documents and
  // drops the bundled operator Deployment/RBAC/Service.
  crds: { releaseAsset: "bundle.yaml" },
  images: {
    // Published by the upstream tagged with the release tag itself.
    "prometheus-operator": { repository: "quay.io/prometheus-operator/prometheus-operator" },
    // Not a container: rendered into the operator's
    // --prometheus-config-reloader argument.
    "prometheus-config-reloader": {
      repository: "quay.io/prometheus-operator/prometheus-config-reloader",
      path: "configReloader.image",
    },
  },
  e2e: {
    namespace: "monitoring",
    // The CRD names carry the API group, not the module name.
    sweepMatch: ["monitoring.coreos"],
    // An Available Prometheus proves the operator reconciled the
    // fixture CR into a ready StatefulSet.
    verify: {
      argv: ["kubectl", "-n", "monitoring", "wait", "prometheus/e2e",
        "--for=condition=Available", "--timeout=30s"],
    },
  },
};
