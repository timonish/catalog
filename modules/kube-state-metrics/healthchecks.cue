package main

import timoniv1 "timoni.sh/core/v1alpha1"

// Default health checks from the Timoni core library
// (Gateway API, Cluster API, etc.).
timoni: healthChecks: timoniv1.#HealthCheckLibrary.all
