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
];
