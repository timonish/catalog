package main

import timoniv1 "timoni.sh/core/v1alpha1"

// Enable the ready-made health checks from the Timoni core library
// (Gateway API, Cluster API and friends).
timoni: healthChecks: timoniv1.#HealthCheckLibrary.all

// With `tls.type: cert-manager`, the apply waits for the Certificate to
// be issued before the instance is considered ready. Certificates report
// readiness through the `Ready` status condition, the shorthand default;
// cert-manager never emits a `Stalled` condition, so the check never
// fails fast and a slow issuer simply keeps the wait in progress.
timoni: healthChecks: {
	"cert-manager.io/Certificate": timoniv1.#HealthCheckForCondition & {
		group: "cert-manager.io"
		kind:  "Certificate"
	}
}
