// Copyright 2026 Stefan Prodan.
// SPDX-License-Identifier: Apache-2.0

// Module upstream declarations for `bun upengine/src/main.ts sync`: one file
// per module under sources/, assembled here in alphabetical order — results
// and reporting keep this order. Adding a module's automation is a
// config-only edit (new sources/<name>.ts plus one import below), typechecked
// by `make lint` and validated by `validateSources` at runtime.

import type { ModuleSource } from "../src/types.ts";
import { source as certManager } from "./sources/cert-manager.ts";
import { source as envoyGateway } from "./sources/envoy-gateway.ts";
import { source as externalDns } from "./sources/external-dns.ts";
import { source as gatewayApi } from "./sources/gateway-api.ts";
import { source as kubeStateMetrics } from "./sources/kube-state-metrics.ts";
import { source as metricsServer } from "./sources/metrics-server.ts";
import { source as prometheusOperator } from "./sources/prometheus-operator.ts";
import { source as trustManager } from "./sources/trust-manager.ts";
import { source as verticalPodAutoscaler } from "./sources/vertical-pod-autoscaler.ts";

export const sources: ModuleSource[] = [
  certManager,
  envoyGateway,
  externalDns,
  gatewayApi,
  kubeStateMetrics,
  metricsServer,
  prometheusOperator,
  trustManager,
  verticalPodAutoscaler,
];
