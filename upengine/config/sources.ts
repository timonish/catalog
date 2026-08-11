// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

// Module upstream declarations for `bun upengine/src/main.ts sync`, processed
// in order; results and reporting keep this order. Adding a module's
// automation is a config-only edit to this file, typechecked by `make lint`
// and validated by `validateSources` at runtime.

import type { ModuleSource } from "../src/types.ts";

export const sources: ModuleSource[] = [
  {
    name: "metrics-server",
    url: "https://github.com/kubernetes-sigs/metrics-server",
    // The repo interleaves metrics-server-helm-chart-* release tags.
    releaseTag: "v*",
    manifests: { releaseAsset: "components.yaml" },
    images: {
      "metrics-server": { container: "metrics-server" },
      // The nanny image is not part of components.yaml; tracked from the
      // addon-resizer release line in the kubernetes/autoscaler monorepo.
      "addon-resizer": {
        url: "https://github.com/kubernetes/autoscaler",
        releaseTag: "addon-resizer-*",
        repository: "registry.k8s.io/autoscaling/addon-resizer",
      },
    },
    e2e: {
      namespace: "kube-system",
      verify: { argv: ["kubectl", "top", "nodes"] },
    },
  },
  {
    name: "cert-manager",
    url: "https://github.com/cert-manager/cert-manager",
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
  },
  {
    name: "gateway-api",
    url: "https://github.com/kubernetes-sigs/gateway-api",
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
  },
  {
    name: "prometheus-operator",
    url: "https://github.com/prometheus-operator/prometheus-operator",
    releaseTag: "v*",
    // The release bundle carries the full CRD schemas (kubectl explain
    // works); the default normalization keeps only the CRD documents and
    // drops the bundled operator Deployment/RBAC/Service.
    crds: { releaseAsset: "bundle.yaml" },
    images: {
      // Published by the upstream tagged with the release tag itself.
      "prometheus-operator": { repository: "quay.io/prometheus-operator/prometheus-operator" },
      // Not a container: rendered into the operator's
      // --prometheus-config-reloader argument.
      "prometheus-config-reloader": { repository: "quay.io/prometheus-operator/prometheus-config-reloader" },
    },
    e2e: {
      namespace: "monitoring",
      // The CRD names carry the API group, not the module name.
      sweepMatch: ["monitoring.coreos"],
      // An Available Prometheus proves the operator reconciled the
      // fixture CR into a ready StatefulSet.
      verify: {
        argv: ["kubectl", "-n", "monitoring", "wait", "prometheus/e2e",
          "--for=condition=Available", "--timeout=30s"],
      },
    },
  },
  {
    name: "kube-state-metrics",
    url: "https://github.com/kubernetes/kube-state-metrics",
    releaseTag: "v*",
    images: {
      // Published by the upstream tagged with the release tag itself.
      "kube-state-metrics": { repository: "registry.k8s.io/kube-state-metrics/kube-state-metrics" },
    },
    e2e: {
      namespace: "kube-state-metrics",
      // The fixture Job scrapes the metrics endpoint through the
      // headless Service and asserts a real metric series exists.
      verify: {
        argv: ["kubectl", "-n", "kube-state-metrics", "wait", "job/e2e",
          "--for=condition=Complete", "--timeout=60s"],
      },
    },
  },
  {
    name: "envoy-gateway",
    url: "https://github.com/envoyproxy/gateway",
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
  },
  {
    name: "external-dns",
    url: "https://github.com/kubernetes-sigs/external-dns",
    // The repo interleaves external-dns-helm-chart-* release tags.
    releaseTag: "v*",
    crds: { file: "charts/external-dns/crds/dnsendpoints.externaldns.k8s.io.yaml" },
    images: {
      // Published by the upstream tagged with the release tag itself.
      "external-dns": { repository: "registry.k8s.io/external-dns/external-dns" },
    },
    e2e: {
      namespace: "external-dns",
      // The crd source records the processed generation on the DNSEndpoint
      // fixture; --dry-run in the test bundle keeps the provider untouched.
      verify: {
        argv: ["kubectl", "-n", "external-dns", "wait", "dnsendpoint/e2e",
          "--for=jsonpath={.status.observedGeneration}=1", "--timeout=10s"],
      },
    },
  },
  {
    name: "trust-manager",
    url: "https://github.com/cert-manager/trust-manager",
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
  },
  {
    name: "vertical-pod-autoscaler",
    url: "https://github.com/kubernetes/autoscaler",
    // The monorepo interleaves the release lines of several components,
    // including vertical-pod-autoscaler-chart-* for the separately
    // versioned chart; the glob's digit guard keeps only the app releases.
    releaseTag: "vertical-pod-autoscaler-*",
    // Multi-package CUE module: one package per component, the image
    // defaults live in templates/config/versions.cue.
    layout: "packages",
    images: {
      // The release images are tagged with the bare semver (1.7.1) while
      // the release tag carries the component prefix, so each image is
      // declared as a tracked image against the module's own release line
      // — the glob prefix strip yields the image tag.
      recommender: {
        url: "https://github.com/kubernetes/autoscaler",
        releaseTag: "vertical-pod-autoscaler-*",
        repository: "registry.k8s.io/autoscaling/vpa-recommender",
      },
      updater: {
        url: "https://github.com/kubernetes/autoscaler",
        releaseTag: "vertical-pod-autoscaler-*",
        repository: "registry.k8s.io/autoscaling/vpa-updater",
      },
      "admission-controller": {
        url: "https://github.com/kubernetes/autoscaler",
        releaseTag: "vertical-pod-autoscaler-*",
        repository: "registry.k8s.io/autoscaling/vpa-admission-controller",
      },
    },
    // The generated manifest holding both CRDs (VerticalPodAutoscaler,
    // VerticalPodAutoscalerCheckpoint); the chart's crds/ directory is a
    // copy of this file.
    crds: { file: "vertical-pod-autoscaler/deploy/vpa-v1-crd-gen.yaml" },
    e2e: {
      namespace: "vertical-pod-autoscaler",
      // Covers the autoscaling.k8s.io CRDs and every leftover of the
      // cert-manager and metrics-server dependency instances (including
      // the v1beta1.metrics.k8s.io APIService), none of which carries
      // the module name.
      sweepMatch: ["autoscaling.k8s.io", "cert-manager", "metrics-server", "metrics.k8s.io"],
      // A recommendation on the fixture VPA proves the recommender
      // consumed metrics-server data and, with the bundle's
      // failurePolicy: Fail, that the webhook admitted the CR through
      // the cert-manager-issued certificate.
      verify: {
        argv: ["kubectl", "-n", "vertical-pod-autoscaler", "wait",
          "vpa/e2e", "--for=condition=RecommendationProvided",
          "--timeout=10s"],
      },
    },
  },
];
