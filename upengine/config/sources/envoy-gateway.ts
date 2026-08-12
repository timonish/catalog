// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "envoy-gateway",
  url: "https://github.com/envoyproxy/gateway",
  // In-repo chart; the onboarding parity baseline was main @ 6ff80b3
  // with release-pinned artifacts.
  parityTarget: "https://github.com/envoyproxy/gateway/tree/main/charts/gateway-helm",
  releaseTag: "v*",
  // The official CRDs-only release asset: exactly the eight
  // gateway.envoyproxy.io CRDs. The Gateway API CRDs are not included;
  // they come from the catalog's gateway-api module.
  crds: { releaseAsset: "envoy-gateway-crds.yaml" },
  images: {
    // Published by the upstream tagged with the release tag itself.
    // The Envoy proxy and ratelimit images are compiled into this
    // binary and are not tracked by the module.
    "envoy-gateway": { repository: "docker.io/envoyproxy/gateway" },
  },
  e2e: {
    namespace: "envoy-gateway",
    // The CRD names carry the API groups of both bundle instances:
    // this module's CRDs and the gateway-api dependency's CRDs.
    sweepMatch: ["gateway.envoyproxy", "gateway.networking"],
    // The fixture Job proves the full data plane: a request through
    // the managed Envoy fleet reaches the echo backend via HTTPRoute.
    verify: {
      argv: ["kubectl", "-n", "envoy-gateway", "wait", "job/e2e",
        "--for=condition=Complete", "--timeout=60s"],
    },
  },
};
