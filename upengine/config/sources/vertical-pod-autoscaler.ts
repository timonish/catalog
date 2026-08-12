// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

import type { ModuleSource } from "../../src/types.ts";

export const source: ModuleSource = {
  name: "vertical-pod-autoscaler",
  url: "https://github.com/kubernetes/autoscaler",
  // In-repo chart, versioned separately on vertical-pod-autoscaler-chart-*
  // tags; its appVersion pins the app release the module tracks.
  parityTarget: "https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler/charts/vertical-pod-autoscaler",
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
};
