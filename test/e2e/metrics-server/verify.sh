#!/usr/bin/env bash
# Verify that the metrics API serves node metrics.
set -euo pipefail

echo "waiting for the metrics API to serve node metrics"
for i in $(seq 1 30); do
  if kubectl top nodes >/dev/null 2>&1; then
    kubectl top nodes
    pods="$(kubectl top pods -n kube-system --sort-by=memory)"
    head -5 <<<"$pods"
    echo "metrics API is serving"
    exit 0
  fi
  sleep 10
done

echo "timed out waiting for kubectl top nodes"
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml
exit 1
