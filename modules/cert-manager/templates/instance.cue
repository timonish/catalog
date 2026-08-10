package templates

import (
	cfgpkg "timoni.sh/cert-manager/templates/config"
	"timoni.sh/cert-manager/templates/controller"
	"timoni.sh/cert-manager/templates/webhook"
	"timoni.sh/cert-manager/templates/cainjector"
)

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: cfgpkg.#Config
	let cfg = config

	// The immutable ConfigMaps are created up front so their generated
	// names can be passed to the deployments: a config change rolls the
	// component pods.
	_controllerCM: controller.#ConfigMap & {#config: cfg}
	_webhookCM: webhook.#ConfigMap & {#config: cfg}
	_cainjectorCM: cainjector.#ConfigMap & {#config: cfg}

	objects: {
		if config.crds.install {
			for name, crd in customresourcedefinition {
				"crd-\(name)": crd
				"crd-\(name)": metadata: labels: config.metadata.labels
				if config.metadata.annotations != _|_ {
					"crd-\(name)": metadata: annotations: config.metadata.annotations
				}

				// Keep the CRDs (and thus all cert-manager custom
				// resources) around when the instance is deleted.
				if config.crds.keep {
					"crd-\(name)": metadata: annotations: "timoni.sh/prune": "disabled"
				}
			}
		}

		// Controller.
		"controller-cm": _controllerCM
		"controller-deploy": controller.#Deployment & {
			#config: cfg
			#cmName: _controllerCM.metadata.name
		}
		if config.controller.serviceAccount.create {
			"controller-sa": controller.#ServiceAccount & {#config: cfg}
		}
		if config.prometheus.enabled && !config.prometheus.podMonitor.enabled {
			"controller-svc": controller.#Service & {#config: cfg}
		}
		if config.rbac.create {
			for k, o in (controller.#RBACObjects & {#config: cfg}).objects {
				(k): o
			}
		}
		if config.controller.podDisruptionBudget.enabled {
			"controller-pdb": controller.#PodDisruptionBudget & {#config: cfg}
		}
		if config.controller.networkPolicy.enabled {
			"controller-netpol-ingress": controller.#NetworkPolicyIngress & {#config: cfg}
			"controller-netpol-egress": controller.#NetworkPolicyEgress & {#config: cfg}
		}

		// Webhook.
		"webhook-cm": _webhookCM
		"webhook-deploy": webhook.#Deployment & {
			#config: cfg
			#cmName: _webhookCM.metadata.name
		}
		"webhook-svc": webhook.#Service & {#config: cfg}
		"webhook-validating": webhook.#ValidatingWebhookConfiguration & {#config: cfg}
		"webhook-mutating": webhook.#MutatingWebhookConfiguration & {#config: cfg}
		if config.webhook.serviceAccount.create {
			"webhook-sa": webhook.#ServiceAccount & {#config: cfg}
		}
		if config.rbac.create {
			for k, o in (webhook.#RBACObjects & {#config: cfg}).objects {
				(k): o
			}
		}
		if config.webhook.podDisruptionBudget.enabled {
			"webhook-pdb": webhook.#PodDisruptionBudget & {#config: cfg}
		}
		if config.webhook.networkPolicy.enabled {
			"webhook-netpol-ingress": webhook.#NetworkPolicyIngress & {#config: cfg}
			"webhook-netpol-egress": webhook.#NetworkPolicyEgress & {#config: cfg}
		}

		// CAInjector.
		if config.cainjector.enabled {
			"cainjector-cm": _cainjectorCM
			"cainjector-deploy": cainjector.#Deployment & {
				#config: cfg
				#cmName: _cainjectorCM.metadata.name
			}
			if config.cainjector.serviceAccount.create {
				"cainjector-sa": cainjector.#ServiceAccount & {#config: cfg}
			}
			if config.prometheus.enabled && !config.prometheus.podMonitor.enabled {
				"cainjector-svc": cainjector.#Service & {#config: cfg}
			}
			if config.rbac.create {
				for k, o in (cainjector.#RBACObjects & {#config: cfg}).objects {
					(k): o
				}
			}
			if config.cainjector.podDisruptionBudget.enabled {
				"cainjector-pdb": cainjector.#PodDisruptionBudget & {#config: cfg}
			}
			if config.cainjector.networkPolicy.enabled {
				"cainjector-netpol-ingress": cainjector.#NetworkPolicyIngress & {#config: cfg}
				"cainjector-netpol-egress": cainjector.#NetworkPolicyEgress & {#config: cfg}
			}
		}

		// Monitoring.
		if config.prometheus.enabled && config.prometheus.serviceMonitor.enabled {
			"service-monitor": #ServiceMonitor & {#config: cfg}
		}
		if config.prometheus.enabled && config.prometheus.podMonitor.enabled {
			"pod-monitor": #PodMonitor & {#config: cfg}
		}
	}
}
