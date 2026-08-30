// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

/** The GitHub repository hosting this catalog. */
export const CATALOG_REPO = "timonish/catalog";

/** The OCI registry prefix modules are published under. */
export const REGISTRY = "oci://ghcr.io/timonish/modules";

/** OCI annotations applied to every published module. */
export const LICENSE = "Apache-2.0";

/** The Timoni core schemas artifact pulled into schemas/cue.mod/pkg. */
export const TIMONI_SCHEMAS = "oci://ghcr.io/stefanprodan/timoni/schemas:latest";

/** The minimum Timoni version every module README lists as a prerequisite —
 * the version the catalog is built, vetted and e2e-tested with. */
export const TIMONI_MIN_VERSION = "0.34";

/**
 * CRD schemas vendored into the shared schemas/ module, pruned to the
 * universally useful kinds. Everything else is per-module.
 */
export const CRD_SCHEMAS = [
  {
    url: "https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.93.0/stripped-down-crds.yaml",
    group: "monitoring.coreos.com",
    keep: ["servicemonitor", "podmonitor"],
    removeGroups: [] as string[],
  },
  {
    url: "https://github.com/cert-manager/cert-manager/releases/download/v1.21.1/cert-manager.crds.yaml",
    group: "cert-manager.io",
    keep: ["certificate", "issuer"],
    removeGroups: ["acme.cert-manager.io"],
  },
  {
    url: "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml",
    group: "gateway.networking.k8s.io",
    keep: ["httproute", "grpcroute"],
    removeGroups: [] as string[],
  },
];
