// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "envoy-gateway",
  url: "https://github.com/envoyproxy/gateway",
  parityTarget: "https://github.com/envoyproxy/gateway/tree/main/charts/gateway-helm",
  releaseTag: "v*",
  // The official CRDs-only release asset: exactly the eight
  // gateway.envoyproxy.io CRDs. The Gateway API CRDs are not included;
  // they come from the catalog's gateway-api module.
  crds: { releaseAsset: "envoy-gateway-crds.yaml" },
  images: {
    // Published by the upstream tagged with the release tag itself; it
    // also runs the certgen Job and the shutdown manager sidecar of the
    // managed Envoy fleet.
    "envoy-gateway": { repository: "docker.io/envoyproxy/gateway" },
    // The data plane images the controller deploys: the managed Envoy
    // fleet and, when global rate limiting is configured, the ratelimit
    // service. Both are versioned independently of the releases by the
    // constants the controller compiles in, and the module renders them
    // into the EnvoyGateway configuration so the whole install is
    // digest-pinned.
    envoy: {
      repository: "docker.io/envoyproxy/envoy",
      file: "api/v1alpha1/shared_types.go",
      variable: "DefaultEnvoyProxyImage",
      path: "proxy.image",
    },
    ratelimit: {
      repository: "docker.io/envoyproxy/ratelimit",
      file: "api/v1alpha1/shared_types.go",
      variable: "DefaultRateLimitImage",
      path: "rateLimit.image",
    },
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
