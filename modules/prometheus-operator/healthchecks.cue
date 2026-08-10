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
}
