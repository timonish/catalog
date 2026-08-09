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
| Module | Version | Upstream |
|---|---|---|
| [metrics-server](modules/metrics-server/README.md) | 0.9.0-1 | [kubernetes-sigs/metrics-server](https://github.com/kubernetes-sigs/metrics-server) |
<!-- modules:end -->

## License

[Apache-2.0](LICENSE)
