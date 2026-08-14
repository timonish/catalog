// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "dex",
  url: "https://github.com/dexidp/dex",
  // The chart lives in a separate repo and pins its own appVersion;
  // the module tracks the dexidp/dex releases directly. Deviations
  // from the chart: the free-form config value is a typed schema
  // rendered into a hash-named immutable Secret (replacing the
  // checksum/config annotation), and the listen addresses are written
  // into the configuration file instead of container flags, with the
  // https/grpc listeners (chart https.enabled/grpc.enabled) derived
  // from the config's web TLS and grpc settings. The RBAC over the
  // dex.coreos.com custom resources renders only with the kubernetes
  // storage backend, and dex creates the CRDs itself at runtime
  // (upstream ships no complete CRD manifests). The chart's env map,
  // envVars list and probe defaults map to the standard env/envFrom
  // and probe values. The chart's detached serviceMonitor.namespace is
  // not reproduced — ServiceMonitors live in the instance namespace —
  // and serviceMonitor.path is fixed to /metrics (the only path the
  // telemetry mux serves). Helm-only mechanics excluded: name/fullname/
  // namespace overrides, tpl expansion in image and ingress fields,
  // Capabilities-based apiVersion switches, the legacy ingress-class
  // annotation mutation, and the helm.sh/hook test Secret.
  parityTarget: "https://github.com/dexidp/helm-charts/tree/master/charts/dex",
  releaseTag: "v*",
  images: {
    // Published by the upstream tagged with the release tag itself.
    dex: { repository: "ghcr.io/dexidp/dex" },
  },
  e2e: {
    namespace: "dex",
    // The fixture Job fetches the OpenID Connect discovery document
    // through the Service, proving the issuer serves requests.
    verify: {
      argv: ["kubectl", "-n", "dex", "wait", "job/e2e",
        "--for=condition=Complete", "--timeout=60s"],
    },
  },
};
