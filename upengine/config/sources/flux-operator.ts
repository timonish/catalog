// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "flux-operator",
  url: "https://github.com/controlplaneio-fluxcd/flux-operator",
  // The chart lives in a separate repo and tracks the operator
  // releases one-to-one; the module tracks the
  // controlplaneio-fluxcd/flux-operator releases directly. Deviations
  // from the chart: the free-form web.config value is a typed open
  // schema rendered into a hash-named immutable Secret (replacing the
  // checksum/web-config pod annotation), and the chart's
  // web.userActions.access value is unified with
  // web.config.userActions.access — either drives the rendered
  // configuration and the fine-grained rules of the serverOnly web
  // ClusterRole, and CUE rejects conflicting settings (the chart lets
  // an external config Secret and the value drift apart silently).
  // commonLabels/commonAnnotations apply to the object metadata; the
  // pod template metadata is served by podLabels/podAnnotations.
  // web.serverReplicas is always written to the
  // Deployment in serverOnly mode (the chart omits it unless greater
  // than one). The chart's extraEnvs maps to the standard env value,
  // installCRDs to the standard crds.install/keep pair, and
  // rbac.createAggregation to rbac.aggregateClusterRoles. The
  // hardcoded prometheus.io/* pod annotations are not rendered
  // (achievable through podAnnotations; scraping is served by the
  // ServiceMonitor), the chart's serviceMonitor 60s/30s scrape
  // defaults are dropped (the Prometheus administrator owns the
  // cadence), and Ingress/HTTPRoute render only with web.enabled (the
  // chart renders them even when the Service lacks the web port).
  // Helm-only mechanics excluded: name/fullname overrides.
  parityTarget: "https://github.com/controlplaneio-fluxcd/charts/tree/main/charts/flux-operator",
  releaseTag: "v*",
  images: {
    // Published by the upstream tagged with the release tag itself.
    "flux-operator": { repository: "ghcr.io/controlplaneio-fluxcd/flux-operator" },
  },
  // The all-in-one release manifest; the default normalization keeps
  // only the CRD documents and drops the bundled operator
  // Deployment/RBAC/Service.
  crds: { releaseAsset: "install.yaml" },
  e2e: {
    namespace: "flux-system",
    // The module CRD names carry the API group, the Flux distribution
    // leftovers carry the toolkit.fluxcd.io groups or the flux-system
    // suffix (cluster roles), and the web user roles are named
    // flux-web-*.
    sweepMatch: ["fluxcd.controlplane.io", "toolkit.fluxcd.io", "flux-system", "flux-web"],
    // A ready FluxInstance proves the operator deployed the Flux
    // distribution from the fixture end to end; the fixture teardown
    // lets the operator garbage-collect the distribution before the
    // uninstall sweep.
    verify: {
      argv: ["kubectl", "-n", "flux-system", "wait", "fluxinstance/flux",
        "--for=condition=Ready", "--timeout=15s"],
    },
  },
};
