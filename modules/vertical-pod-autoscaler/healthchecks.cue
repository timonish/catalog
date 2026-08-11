package main

import timoniv1 "timoni.sh/core/v1alpha1"

// Default health checks from the Timoni core library
// (Gateway API, Cluster API, etc.).
timoni: healthChecks: timoniv1.#HealthCheckLibrary.all

// Default health checks for custom resources included in this module.
timoni: healthChecks: {
	// The webhook serving certificate issued by cert-manager.
	"cert-manager.io/Certificate": timoniv1.#HealthCheckForCondition & {
		group: "cert-manager.io"
		kind:  "Certificate"
	}
	// VerticalPodAutoscalers created by users next to the instance
	// report readiness through the RecommendationProvided condition.
	"autoscaling.k8s.io/VerticalPodAutoscaler": timoniv1.#HealthCheckForCondition & {
		group:         "autoscaling.k8s.io"
		kind:          "VerticalPodAutoscaler"
		conditionType: "RecommendationProvided"
	}
}
