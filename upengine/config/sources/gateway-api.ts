// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "gateway-api",
  url: "https://github.com/kubernetes-sigs/gateway-api",
  // No chart: the parity surface is the standard-install.yaml /
  // experimental-install.yaml release assets, fully ingested by the
  // sync through the crds channels below.
  parityTarget: "https://github.com/kubernetes-sigs/gateway-api/releases",
  releaseTag: "v*",
  // CRDs-only module, no images: the module renders the CRD set of the
  // channel selected through the instance values.
  crds: {
    channels: {
      standard: { releaseAsset: "standard-install.yaml" },
      experimental: { releaseAsset: "experimental-install.yaml" },
    },
    // The safe-upgrades ValidatingAdmissionPolicy ships with the CRDs,
    // and the Gateway API CRD labels/annotations are semantic (channel,
    // bundle-version, GEP-713 policy kind) — nothing is stripped.
    keepKinds: ["ValidatingAdmissionPolicy", "ValidatingAdmissionPolicyBinding"],
    keepLabels: true,
  },
  e2e: {
    // Local-only until the ingress-controller bundles exercise the CRDs;
    // CI gates this module with vet.
    ci: false,
    namespace: "gateway-system",
    // The CRD names carry the API group, not the module name.
    sweepMatch: ["gateway.networking"],
    // A served GatewayClass fixture proves the CRDs are established.
    verify: { argv: ["kubectl", "get", "gatewayclass", "e2e"] },
  },
};
