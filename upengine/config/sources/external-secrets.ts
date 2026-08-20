// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "external-secrets",
  url: "https://github.com/external-secrets/external-secrets",
  // In-repo chart (released on its own helm-chart-* tag line, which the
  // v* glob excludes). Helm-only mechanics and deviations not
  // reproduced: the bitwarden-sdk-server subchart (a separate addon),
  // the Grafana dashboard ConfigMap, extraObjects and podSpecExtra,
  // the image flavour suffix and global.repository (set image.tag /
  // image.repository instead), the per-kind CRD install toggles (the
  // CRDs install as a set; the reconcilers stay switchable), the
  // v1alpha1 conversion webhook and unsafeServeV1Beta1 (removed
  // upstream APIs), serviceMonitor.namespace and renderMode, the
  // ServiceMonitor bearer token read from a `<sa>-token` Secret the
  // chart never creates (use the canonical bearerTokenSecret), the
  // certController.create, createOperator and webhook.service.enabled
  // toggles (the cert-controller follows webhook.tls.type, the other
  // two always render), certController.rbac.create (the single
  // rbac.create covers all components), the separate
  // aggregateToView/Edit/Admin switches (one aggregateClusterRoles),
  // per-component image and imagePullSecrets (one binary serves all
  // three components), webhook.secretAnnotations and the
  // name/namespace overrides. OpenShift adaptSecurityContext maps to
  // securityContextPreset. The chart's metrics.listen.secure passes
  // the cert/key as absolute paths to flags expecting file names
  // under certDir; the module passes the names. The view/edit roles
  // add the stssessiontokens generator the chart leaves out of them.
  parityTarget: "https://github.com/external-secrets/external-secrets/tree/main/deploy/charts/external-secrets",
  releaseTag: "v*",
  images: {
    // One image serves all three components (the webhook and
    // cert-controller are subcommands), published by the upstream
    // tagged with the release tag itself.
    "external-secrets": { repository: "ghcr.io/external-secrets/external-secrets" },
  },
  // The all-in-one release manifest; the default normalization keeps
  // only the CRD documents and drops the bundled operator
  // Deployments/RBAC/webhook configurations. The CRD labels are
  // semantic: with enablePartialCache the cert-controller caches only
  // the CRDs labeled external-secrets.io/component=controller.
  crds: { releaseAsset: "external-secrets.yaml", keepLabels: true },
  e2e: {
    namespace: "external-secrets",
    // The validating webhook configurations carry fixed upstream
    // names without the module name.
    sweepMatch: ["secretstore-validate", "externalsecret-validate"],
    // A Ready ExternalSecret synced from the fake-provider SecretStore
    // fixture proves the controller reconciles and, with the default
    // failurePolicy Fail, that the webhook and cert-controller admit
    // the fixture resources.
    verify: {
      argv: ["kubectl", "-n", "external-secrets", "wait", "externalsecret/e2e",
        "--for=condition=Ready", "--timeout=10s"],
    },
  },
};
