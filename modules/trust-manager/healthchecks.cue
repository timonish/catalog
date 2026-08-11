package main

import timoniv1 "timoni.sh/core/v1alpha1"

// Default health checks from the Timoni core library
// (Gateway API, Cluster API, etc.).
timoni: healthChecks: timoniv1.#HealthCheckLibrary.all

// Default health checks for custom resources included in this module.
timoni: healthChecks: {
	"cert-manager.io/Certificate": timoniv1.#HealthCheckForCondition & {
		group: "cert-manager.io"
		kind:  "Certificate"
	}
	// Bundles created by users next to the instance report readiness
	// through the Synced condition.
	"trust.cert-manager.io/Bundle": timoniv1.#HealthCheckForCondition & {
		group:         "trust.cert-manager.io"
		kind:          "Bundle"
		conditionType: "Synced"
	}
}
