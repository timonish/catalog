// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "trust-manager",
  url: "https://github.com/cert-manager/trust-manager",
  // In-repo chart.
  parityTarget: "https://github.com/cert-manager/trust-manager/tree/main/deploy/charts/trust-manager",
  releaseTag: "v*",
  // The chart-templated Bundle CRD is spec-identical to this source file;
  // the ClusterBundle CRD in the same directory is not shipped by the
  // upstream chart and stays excluded.
  crds: { file: "deploy/crds/trust.cert-manager.io_bundles.yaml" },
  images: {
    // Published by the upstream tagged with the release tag itself.
    "trust-manager": { repository: "quay.io/jetstack/trust-manager" },
    // The default trust package follows the Debian ca-certificates
    // cadence, not the release tags; its version lives in this Makefile
    // fragment at the release commit.
    "trust-pkg-debian-trixie": {
      repository: "quay.io/jetstack/trust-pkg-debian-trixie",
      file: "make/00_debian_trixie_version.mk",
      variable: "DEBIAN_TRIXIE_BUNDLE_VERSION",
    },
  },
  e2e: {
    namespace: "trust-manager",
    // Covers the Bundle CRD (bundles.trust.cert-manager.io) and every
    // leftover of the cert-manager dependency instance, neither of
    // which carries the module name.
    sweepMatch: ["cert-manager"],
    // A Synced Bundle built from the default CAs package proves the
    // webhook admitted the fixture and the controller reconciled it
    // into the target ConfigMap.
    verify: {
      argv: ["kubectl", "wait", "bundle/e2e",
        "--for=condition=Synced", "--timeout=10s"],
    },
  },
};
