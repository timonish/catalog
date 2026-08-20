package templates

import (
	cfgpkg "timoni.sh/external-secrets/templates/config"
	"timoni.sh/external-secrets/templates/controller"
	"timoni.sh/external-secrets/templates/webhook"
	"timoni.sh/external-secrets/templates/certcontroller"
)

// Instance takes the config values and outputs the Kubernetes objects.
#Instance: {
	config: cfgpkg.#Config
	let cfg = config

	// The cert-controller runs only when it owns the webhook
	// certificate.
	_certController: config.webhook.enabled && config.webhook.tls.type == "cert-controller"

	objects: {
		if config.crds.install {
			for name, crd in customresourcedefinition {
				"crd-\(name)": crd
				"crd-\(name)": metadata: labels: config.metadata.labels
				if config.metadata.annotations != _|_ {
					"crd-\(name)": metadata: annotations: config.metadata.annotations
				}

				// Keep the CRDs (and thus all External Secrets custom
				// resources) around when the instance is deleted.
				if config.crds.keep {
					"crd-\(name)": metadata: annotations: "timoni.sh/prune": "disabled"
				}
			}
		}

		// Controller.
		"controller-deploy": controller.#Deployment & {#config: cfg}
		if config.controller.serviceAccount.create {
			"controller-sa": controller.#ServiceAccount & {#config: cfg}
		}
		if config.controller.metrics.service.enabled || config.serviceMonitor.enabled {
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
		if config.webhook.enabled {
			"webhook-deploy": webhook.#Deployment & {#config: cfg}
			"webhook-svc": webhook.#Service & {#config: cfg}
			"webhook-validating-secretstore": webhook.#SecretStoreWebhookConfiguration & {#config: cfg}
			"webhook-validating-externalsecret": webhook.#ExternalSecretWebhookConfiguration & {#config: cfg}
			if _certController {
				"webhook-secret": webhook.#Secret & {#config: cfg}
			}
			if config.webhook.tls.type == "cert-manager" && config.webhook.tls.certManager.createCertificate {
				if !config.webhook.tls.certManager.existingIssuer.enabled {
					"webhook-issuer": webhook.#Issuer & {#config: cfg}
				}
				"webhook-certificate": webhook.#Certificate & {#config: cfg}
			}
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
		}

		// Cert-controller.
		if _certController {
			"cert-controller-deploy": certcontroller.#Deployment & {#config: cfg}
			if config.certController.serviceAccount.create {
				"cert-controller-sa": certcontroller.#ServiceAccount & {#config: cfg}
			}
			if config.certController.metrics.service.enabled || config.serviceMonitor.enabled {
				"cert-controller-svc": certcontroller.#Service & {#config: cfg}
			}
			if config.rbac.create {
				for k, o in (certcontroller.#RBACObjects & {#config: cfg}).objects {
					(k): o
				}
			}
			if config.certController.podDisruptionBudget.enabled {
				"cert-controller-pdb": certcontroller.#PodDisruptionBudget & {#config: cfg}
			}
			if config.certController.networkPolicy.enabled {
				"cert-controller-netpol-ingress": certcontroller.#NetworkPolicyIngress & {#config: cfg}
				"cert-controller-netpol-egress": certcontroller.#NetworkPolicyEgress & {#config: cfg}
			}
		}

		// Monitoring.
		if config.serviceMonitor.enabled {
			"service-monitor": #ServiceMonitor & {#config: cfg}
		}
	}
}
