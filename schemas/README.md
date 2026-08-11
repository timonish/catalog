# Shared schemas

This CUE module holds the single copy of the vendored schemas used by all
Timoni modules in this repository:

- `cue.mod/pkg/timoni.sh` — the Timoni core schemas
- `cue.mod/gen/k8s.io` — the full Kubernetes API schemas (no pruning)
- `cue.mod/gen/monitoring.coreos.com` — the Prometheus Operator ServiceMonitor
  and PodMonitor CRD schemas (most addons expose one of these)
- `cue.mod/gen/cert-manager.io` — the cert-manager Certificate and Issuer
  CRD schemas (most addons offer optional cert-manager provisioned TLS)
- `cue.mod/gen/gateway.networking.k8s.io` — the Gateway API HTTPRoute and
  GRPCRoute CRD schemas (most apps expose their endpoints through one of
  these)

The CRD kinds not listed above are pruned by `make update-shared-schemas`.
Only these universal schemas are shared. Other CRD schemas are per-addon and
are vendored directly into the module that needs them
(`modules/<name>/cue.mod/gen/<group>`) by the sync engine.

Instead of vendoring these into every module, each module symlinks them:

```shell
ln -s ../../../../schemas/cue.mod/gen/k8s.io modules/my-module/cue.mod/gen/k8s.io
ln -s ../../../../schemas/cue.mod/pkg/timoni.sh modules/my-module/cue.mod/pkg/timoni.sh
```

Timoni v0.30 or newer follows the symlinks when building, vetting and pushing
modules. Publishing to a registry requires the `--resolve-symlinks` flag,
which packages the symlink targets as regular files (already set in
`make push-mod`).

## Updating

```shell
make update-shared-schemas   # update the Timoni core and Kubernetes API schemas
```

The target pulls the Timoni core schemas from
`oci://ghcr.io/stefanprodan/timoni/schemas:latest` into `cue.mod/pkg` and
vendors the Kubernetes API and Prometheus Operator CRD schemas into
`cue.mod/gen` (the Prometheus Operator version is pinned in the Makefile).
These are refreshed when upgrading Timoni/Kubernetes/Prometheus Operator,
not on addon releases.
