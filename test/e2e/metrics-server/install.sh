#!/usr/bin/env bash
# Install the metrics-server module on the test cluster.
# Usage: install.sh <module-url> <module-version>
set -euo pipefail

MODULE_URL="${1?module url required}"
MODULE_VERSION="${2?module version required}"

# Kind's kubelet serving certificates are self-signed.
timoni -n kube-system apply metrics-server "$MODULE_URL" \
  -v "$MODULE_VERSION" \
  --timeout=5m \
  --values - <<EOF
values: args: ["--kubelet-insecure-tls"]
EOF
