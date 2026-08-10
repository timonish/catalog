package templates

import (
	timoniv1 "timoni.sh/core/v1alpha1"
)

// Config defines the schema and defaults for the Instance values.
#Config: {
	// Runtime version info automatically set at apply-time.
	moduleVersion!: string
	kubeVersion!:   string

	// The ValidatingAdmissionPolicy v1 API requires Kubernetes 1.30 or newer.
	clusterVersion: timoniv1.#SemVer & {#Version: kubeVersion, #Minimum: "1.30.0"}

	// Kubernetes metadata common to all resources.
	metadata: timoniv1.#Metadata & {#Version: moduleVersion}

	// Extra labels added to all resources.
	commonLabels?: timoniv1.#Labels
	if commonLabels != _|_ {
		metadata: labels: commonLabels
	}

	// The Gateway API release channel. The standard channel contains the
	// graduated APIs; the experimental channel adds the experimental
	// fields and the x-k8s.io API group resources. Switching a live
	// instance from standard to experimental is denied by the
	// safe-upgrades policy — disable `safeUpgrades`, apply, then switch.
	channel: *"standard" | "experimental"

	// CRD lifecycle settings. `keep: true` marks the CRDs with
	// `timoni.sh/prune: disabled` so an uninstall preserves them and
	// every Gateway API custom resource in the cluster.
	crds: keep: *false | bool

	// Install the upstream safe-upgrades ValidatingAdmissionPolicy,
	// which denies replacing the Gateway API CRDs with an older release
	// (the exact version threshold is channel-specific and set by the
	// upstream policy) and replacing standard channel CRDs with
	// experimental ones.
	safeUpgrades: *true | bool
}

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: #Config

	// The CRD sets of both release channels are generated into
	// crds_standard.cue and crds_experimental.cue; only the objects of
	// the selected channel are rendered.
	_channel: crds[config.channel]

	objects: {
		for name, crd in _channel.customresourcedefinition {
			"crd-\(name)": crd
			"crd-\(name)": metadata: labels: config.metadata.labels
			if config.metadata.annotations != _|_ {
				"crd-\(name)": metadata: annotations: config.metadata.annotations
			}

			// Keep the CRDs (and thus all Gateway API custom resources
			// in the cluster) around when the instance is deleted.
			if config.crds.keep {
				"crd-\(name)": metadata: annotations: "timoni.sh/prune": "disabled"
			}
		}

		if config.safeUpgrades {
			for name, policy in _channel.validatingadmissionpolicy {
				"vap-\(name)": policy
				"vap-\(name)": metadata: labels: config.metadata.labels
				if config.metadata.annotations != _|_ {
					"vap-\(name)": metadata: annotations: config.metadata.annotations
				}
			}
			for name, binding in _channel.validatingadmissionpolicybinding {
				"vapb-\(name)": binding
				"vapb-\(name)": metadata: labels: config.metadata.labels
				if config.metadata.annotations != _|_ {
					"vapb-\(name)": metadata: annotations: config.metadata.annotations
				}
			}
		}
	}
}
