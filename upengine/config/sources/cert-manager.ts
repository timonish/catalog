// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "cert-manager",
  url: "https://github.com/cert-manager/cert-manager",
  // In-repo chart; the parity surface also spans the typed component
  // Config APIs under pkg/apis/config/, which the chart values alone
  // do not cover. Deviation: the chart's detached serviceMonitor
  // namespace is not reproduced — ServiceMonitors live in the
  // instance namespace.
  parityTarget: "https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager",
  releaseTag: "v*",
  // Multi-package CUE module: one package per component, the image
  // defaults live in templates/config/versions.cue.
  layout: "packages",
  images: {
    // Published by the upstream tagged with the release tag itself.
    controller: { repository: "quay.io/jetstack/cert-manager-controller" },
    webhook: { repository: "quay.io/jetstack/cert-manager-webhook" },
    cainjector: { repository: "quay.io/jetstack/cert-manager-cainjector" },
    // Spawned by the controller for ACME HTTP01 challenges, rendered
    // into the controller configuration file.
    acmesolver: { repository: "quay.io/jetstack/cert-manager-acmesolver" },
  },
  // The official static CRD manifest published with every release;
  // the in-repo CRD sources are marked non-authoritative upstream.
  crds: { releaseAsset: "cert-manager.crds.yaml" },
  e2e: {
    namespace: "cert-manager",
    // A Ready Certificate proves the controller, webhook and
    // cainjector work end to end on the self-signed issuer fixture.
    verify: {
      argv: ["kubectl", "-n", "cert-manager", "wait", "certificate/e2e",
        "--for=condition=Ready", "--timeout=10s"],
    },
  },
};
