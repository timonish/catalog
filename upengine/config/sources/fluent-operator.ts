// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "fluent-operator",
  url: "https://github.com/fluent/fluent-operator",
  // In-repo chart; the parity surface is its operator.* section plus
  // the top-level containerRuntime — the module ships the operator
  // only. The chart's canned Fluent Bit/Fluentd logging pipeline
  // (Kubernetes, fluentbit.*, fluentd.* rendered as fluent.io custom
  // resources) is out of scope: users author the pipeline resources
  // themselves. Other deviations: kubeedge is part of the excluded
  // pipeline; operator.enable and the RBAC name overrides are Helm
  // packaging mechanics; serviceMonitor.path is fixed to /metrics
  // (the only path controller-runtime serves); the metrics Service
  // the chart renders scrapes nothing upstream (the operator default
  // is --metrics-bind-address=0), the module passes the flag instead.
  // RBAC deviations from the chart: namespaces are read-only (the
  // controller never mutates them, and write access would be delegable
  // through the FluentBit rbacRules field), and roles/rolebindings add
  // the delete verb the namespaced-mode finalizer needs.
  // Upstream chart v4 restructures the CRD packaging (CRDs move into
  // the chart crds/ dir, containerd-only defaults) — recheck this
  // scoping when it lands.
  parityTarget: "https://github.com/fluent/fluent-operator/tree/master/charts/fluent-operator",
  releaseTag: "v*",
  images: {
    // Published by the upstream tagged with the release tag itself.
    "fluent-operator": { repository: "ghcr.io/fluent/fluent-operator/fluent-operator" },
  },
  // The all-in-one release manifest; the default normalization keeps
  // only the CRD documents and drops the bundled operator
  // Deployment/RBAC/Service.
  crds: { releaseAsset: "setup.yaml" },
  e2e: {
    namespace: "fluent-system",
    // The CRD names carry the API groups, not the module name.
    sweepMatch: ["fluent.io"],
    // A ready Fluent Bit DaemonSet proves the operator reconciled the
    // fixture pipeline (FluentBit + config + input + output) end to end.
    verify: {
      argv: ["kubectl", "-n", "fluent-system", "rollout", "status",
        "daemonset/fluent-bit", "--timeout=15s"],
    },
  },
};
