#!/usr/bin/env bash
# Uninstall the metrics-server module and verify nothing is left behind.
set -euo pipefail

timoni -n kube-system delete metrics-server --timeout=5m

kubectl -n kube-system wait pod -l app.kubernetes.io/name=metrics-server \
  --for=delete --timeout=2m

echo "checking for leftovers"
leftovers="$(kubectl get clusterrole,clusterrolebinding,apiservice -o name | grep -i metrics-server || true)"
if [ -n "$leftovers" ]; then
  echo "cluster-scoped leftovers found:"
  echo "$leftovers"
  exit 1
fi

if kubectl -n kube-system get rolebinding metrics-server-auth-reader >/dev/null 2>&1; then
  echo "kube-system auth-reader RoleBinding was not deleted"
  exit 1
fi

echo "uninstall clean"
