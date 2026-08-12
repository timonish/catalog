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

See each module's README for its current version, values API and
configuration examples.

## Modules

<!-- modules:start -->
| Module | Upstream |
|---|---|
| [cert-manager](modules/cert-manager/README.md) | [cert-manager/cert-manager](https://github.com/cert-manager/cert-manager) |
| [envoy-gateway](modules/envoy-gateway/README.md) | [envoyproxy/gateway](https://github.com/envoyproxy/gateway) |
| [external-dns](modules/external-dns/README.md) | [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns) |
| [gateway-api](modules/gateway-api/README.md) | [kubernetes-sigs/gateway-api](https://github.com/kubernetes-sigs/gateway-api) |
| [kube-state-metrics](modules/kube-state-metrics/README.md) | [kubernetes/kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) |
| [metrics-server](modules/metrics-server/README.md) | [kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server) |
| [prometheus-operator](modules/prometheus-operator/README.md) | [prometheus-operator/prometheus-operator](https://github.com/prometheus-operator/prometheus-operator) |
| [trust-manager](modules/trust-manager/README.md) | [cert-manager/trust-manager](https://github.com/cert-manager/trust-manager) |
| [vertical-pod-autoscaler](modules/vertical-pod-autoscaler/README.md) | [kubernetes/autoscaler](https://github.com/kubernetes/autoscaler) |
<!-- modules:end -->

## License

[Apache-2.0](LICENSE)
