# gateway-api

A [Timoni](https://timoni.sh) module for deploying the [Kubernetes Gateway API](https://github.com/kubernetes-sigs/gateway-api) custom resource definitions, consumed by ingress controllers and service meshes.

## Version

<!-- versions:start -->
Latest module version is `1.6.1-1`, packaging the upstream release
[v1.6.1](https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.6.1).
<!-- versions:end -->

To list all available versions and their digests:

```shell
timoni mod list oci://ghcr.io/timonish/modules/gateway-api
```

## Prerequisites

- Kubernetes 1.30+
- [Timoni](https://timoni.sh/install/) 0.31+

## Install

The module installs the Gateway API CRDs of the selected release channel
together with the upstream `safe-upgrades` validating admission policy,
which protects the CRDs from being replaced with an older release by
other tooling (the exact version threshold is set by the upstream
policy per channel). It deploys no workloads — a Gateway API implementation
(ingress controller or service mesh) is expected to be installed
separately.

To install the standard channel (the graduated APIs):

```shell
timoni -n gateway-system apply gateway-api \
  oci://ghcr.io/timonish/modules/gateway-api
```

To install the experimental channel, which adds the experimental fields
of the standard resources and the `gateway.networking.x-k8s.io` group,
place the following in a `values.cue` file:

```cue
values: {
	channel: "experimental"
}
```

And apply it with:

```shell
timoni -n gateway-system apply gateway-api \
  oci://ghcr.io/timonish/modules/gateway-api \
  --values values.cue
```

To uninstall the instance and delete the CRDs along with every Gateway
API custom resource in the cluster:

```shell
timoni -n gateway-system delete gateway-api
```

To preserve the CRDs (and thus all Gateway API custom resources) on
uninstall, set `crds: keep: true` in the instance values.

### Switching channels

Upgrading a live instance from the standard to the experimental channel
is denied by the `safe-upgrades` policy. To switch, remove the policy
with a first apply setting the following values:

```cue
values: {
	safeUpgrades: false
}
```

Then switch the channel (and restore the policy) with a second apply:

```cue
values: {
	channel: "experimental"
}
```

Admission policy removal takes a few seconds to propagate inside the
API server — if the second apply is still denied, simply retry it.
Switching back from experimental to standard is always allowed: the
x-k8s.io CRDs are removed (unless `crds: keep: true` preserves them)
and the experimental-only fields of the standard resources are no
longer served.

## Bundle

For production deployments it is recommended to use a Timoni
[bundle](https://timoni.sh/bundle/) that offers a declarative way of
managing the lifecycle of applications and their infra dependencies.

Bundle instances are applied in definition order, so the Gateway API
CRDs are declared before the controllers implementing them:

```cue
bundle: {
	apiVersion: "v1alpha1"
	name:       "cluster-addons"
	instances: {
		"gateway-api": {
			module: {
				url:     "oci://ghcr.io/timonish/modules/gateway-api"
				version: "latest"
			}
			namespace: "gateway-system"
			values: {
				channel: "standard"
			}
		}
		// Gateway API implementations (ingress controller, service
		// mesh) follow here; they find the CRDs already established.
	}
}
```

Save the bundle as `cluster-addons.cue` and apply the stack with:

```shell
timoni bundle apply -f cluster-addons.cue
```

## Configuration

All values are optional.

| Key | Type | Default | Description |
|---|---|---|---|
| `channel` | `string` | `standard` | Gateway API release channel: `standard` or `experimental` |
| `crds.keep` | `bool` | `false` | Keep the CRDs (and all Gateway API custom resources) when the instance is deleted |
| `safeUpgrades` | `bool` | `true` | Install the upstream safe-upgrades validating admission policy, denying CRD replacements with older releases and standard-to-experimental switches |
| `commonLabels` | `{[string]: string}` | unset | Extra labels added to all resources |
