# Timoni Module Catalog

A catalog of [Timoni](https://timoni.sh) modules for popular Kubernetes
addons, published as signed OCI artifacts to
`ghcr.io/timonish/modules/<name>`.

Each module packages an upstream addon, and its version mirrors the
upstream stable release plus a catalog build number (e.g. `1.2.3-0`).
Upstream releases are tracked daily and published automatically once
they pass validation and end-to-end tests. All container images
shipped by the modules are pinned by digest, and listed in each
module's README.

## Usage

Install a module on a cluster with:

```shell
timoni -n <namespace> apply <name> oci://ghcr.io/timonish/modules/<name>
```

See each module's README for its values API and configuration examples.

## Modules

<!-- modules:start -->
| Module | Version | Updated | Upstream |
|---|---|---|---|
| [cert-manager](modules/cert-manager/README.md) | 1.21.1-1 | 2026.08.11 | [cert-manager/cert-manager](https://github.com/cert-manager/cert-manager) |
| [envoy-gateway](modules/envoy-gateway/README.md) | 1.8.3-1 | 2026.08.11 | [envoyproxy/gateway](https://github.com/envoyproxy/gateway) |
| [external-dns](modules/external-dns/README.md) | 0.21.0-2 | 2026.08.11 | [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns) |
| [gateway-api](modules/gateway-api/README.md) | 1.6.1-1 | 2026.08.11 | [kubernetes-sigs/gateway-api](https://github.com/kubernetes-sigs/gateway-api) |
| [kube-state-metrics](modules/kube-state-metrics/README.md) | 2.19.1-2 | 2026.08.11 | [kubernetes/kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) |
| [metrics-server](modules/metrics-server/README.md) | 0.9.0-3 | 2026.08.11 | [kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server) |
| [prometheus-operator](modules/prometheus-operator/README.md) | 0.93.1-1 | 2026.08.11 | [prometheus-operator/prometheus-operator](https://github.com/prometheus-operator/prometheus-operator) |
| [trust-manager](modules/trust-manager/README.md) | 0.24.0-0 | 2026.08.11 | [cert-manager/trust-manager](https://github.com/cert-manager/trust-manager) |
| [vertical-pod-autoscaler](modules/vertical-pod-autoscaler/README.md) | 1.7.1-0 | 2026.08.11 | [kubernetes/autoscaler](https://github.com/kubernetes/autoscaler) |
<!-- modules:end -->

## License

[Apache-2.0](LICENSE)
