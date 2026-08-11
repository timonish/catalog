package templates

import (
	cfgpkg "timoni.sh/vertical-pod-autoscaler/templates/config"
	"timoni.sh/vertical-pod-autoscaler/templates/recommender"
	"timoni.sh/vertical-pod-autoscaler/templates/updater"
	"timoni.sh/vertical-pod-autoscaler/templates/admission"
)

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: cfgpkg.#Config
	let cfg = config

	objects: {
		if config.crds.install {
			for name, crd in customresourcedefinition {
				"crd-\(name)": crd
				"crd-\(name)": metadata: labels: config.metadata.labels
				if config.metadata.annotations != _|_ {
					"crd-\(name)": metadata: annotations: config.metadata.annotations
				}

				// Keep the CRDs (and thus all VerticalPodAutoscaler
				// custom resources) around when the instance is
				// deleted.
				if config.crds.keep {
					"crd-\(name)": metadata: annotations: "timoni.sh/prune": "disabled"
				}
			}
		}

		// Recommender.
		if config.recommender.enabled {
			"recommender-deploy": recommender.#Deployment & {#config: cfg}
			if config.recommender.serviceAccount.create {
				"recommender-sa": recommender.#ServiceAccount & {#config: cfg}
			}
			if config.rbac.create {
				for k, o in (recommender.#RBACObjects & {#config: cfg}).objects {
					(k): o
				}
			}
			if config.recommender.podDisruptionBudget.enabled {
				"recommender-pdb": recommender.#PodDisruptionBudget & {#config: cfg}
			}
			if config.serviceMonitor.enabled {
				"recommender-metrics-svc": recommender.#MetricsService & {#config: cfg}
				"recommender-sm": recommender.#ServiceMonitor & {#config: cfg}
			}
		}

		// Updater.
		if config.updater.enabled {
			"updater-deploy": updater.#Deployment & {#config: cfg}
			if config.updater.serviceAccount.create {
				"updater-sa": updater.#ServiceAccount & {#config: cfg}
			}
			if config.rbac.create {
				for k, o in (updater.#RBACObjects & {#config: cfg}).objects {
					(k): o
				}
			}
			if config.updater.podDisruptionBudget.enabled {
				"updater-pdb": updater.#PodDisruptionBudget & {#config: cfg}
			}
			if config.serviceMonitor.enabled {
				"updater-metrics-svc": updater.#MetricsService & {#config: cfg}
				"updater-sm": updater.#ServiceMonitor & {#config: cfg}
			}
		}

		// Admission controller.
		if config.admissionController.enabled {
			"admission-deploy": admission.#Deployment & {#config: cfg}
			"admission-webhook-svc": admission.#WebhookService & {#config: cfg}
			if config.admissionController.serviceAccount.create {
				"admission-sa": admission.#ServiceAccount & {#config: cfg}
			}
			if config.rbac.create {
				for k, o in (admission.#RBACObjects & {#config: cfg}).objects {
					(k): o
				}
			}
			if config.admissionController.certManager.enabled || (config.admissionController.tls.create && !config.admissionController.registerWebhook) {
				"admission-mwc": admission.#MutatingWebhookConfiguration & {#config: cfg}
			}
			if config.admissionController.certManager.enabled {
				for k, o in (admission.#CertManagerObjects & {#config: cfg}).objects {
					(k): o
				}
			}
			if config.admissionController.tls.create {
				"admission-tls-secret": admission.#TLSSecret & {#config: cfg}
			}
			if config.admissionController.podDisruptionBudget.enabled {
				"admission-pdb": admission.#PodDisruptionBudget & {#config: cfg}
			}
			if config.serviceMonitor.enabled {
				"admission-metrics-svc": admission.#MetricsService & {#config: cfg}
				"admission-sm": admission.#ServiceMonitor & {#config: cfg}
			}
		}
	}
}
