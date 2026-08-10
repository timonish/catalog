# Timoni Module Catalog

A catalog of [Timoni](https://timoni.sh) modules for popular Kubernetes
addons, published as signed OCI artifacts to
`ghcr.io/timonish/modules/<name>`.

Each module packages an upstream addon, and its
version mirrors the upstream stable release plus a catalog build number
(e.g. `1.2.3-0`). Upstream releases are tracked daily and published
automatically once they pass validation and end-to-end tests.

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
| [cert-manager](modules/cert-manager/README.md) | 1.21.1-0 | 2026.08.10 | [cert-manager/cert-manager](https://github.com/cert-manager/cert-manager) |
| [external-dns](modules/external-dns/README.md) | 0.21.0-1 | 2026.08.10 | [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns) |
| [gateway-api](modules/gateway-api/README.md) | 1.6.1-0 | 2026.08.10 | [kubernetes-sigs/gateway-api](https://github.com/kubernetes-sigs/gateway-api) |
| [metrics-server](modules/metrics-server/README.md) | 0.9.0-2 | 2026.08.10 | [kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server) |
<!-- modules:end -->

## License

[Apache-2.0](LICENSE)
