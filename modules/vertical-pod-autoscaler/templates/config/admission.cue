package config

import (
	"list"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	timoniv1 "timoni.sh/core/v1alpha1"
)

// AdmissionControllerValues defines the admission-controller component
// settings.
#AdmissionControllerValues: A={
	#Workload

	// The webhook Service settings. The service name is passed to the
	// admission controller through `--webhook-service` and added to the
	// serving certificate DNS names; the first port is referenced by
	// the webhook configuration.
	service: {
		name:         *"vpa-webhook" | string & =~".+"
		annotations?: timoniv1.#Annotations
		ports: *[{port: 443, protocol: "TCP", targetPort: 8000}] | [corev1.#ServicePort, ...corev1.#ServicePort]
	}

	// Run the admission controller on the host network, e.g. on
	// clusters where the control plane cannot reach the pod network.
	hostNetwork: *false | bool

	// Let the admission controller register (and remove) the
	// MutatingWebhookConfiguration itself instead of the module
	// rendering it; the webhook RBAC is extended with write access to
	// mutatingwebhookconfigurations. Requires serving certificate files
	// in the Secret referenced by `tls.secretName`.
	registerWebhook: *false | bool

	// The MutatingWebhookConfiguration settings; the object is rendered
	// unless `registerWebhook` delegates it to the application. With
	// the default `failurePolicy: Ignore` pods are admitted unmutated
	// when the webhook is unavailable; `Fail` guarantees resource
	// updates at the cost of blocking pod creation during webhook
	// downtime.
	mutatingWebhookConfiguration: {
		failurePolicy:      *"Ignore" | "Fail"
		namespaceSelector?: metav1.#LabelSelector
		objectSelector?:    metav1.#LabelSelector
		timeoutSeconds:     *5 | int & >=1 & <=30
		annotations?:       timoniv1.#Annotations
	}

	// Webhook certificate lifecycle managed by cert-manager, which must
	// be installed in the cluster. By default the module creates a
	// self-signed issuer chain (SelfSigned Issuer -> CA Certificate ->
	// CA Issuer) signing the serving certificate; set
	// `createSelfSignedIssuer.enabled: false` and `issuerRef` to use an
	// existing issuer instead. Mutually exclusive with
	// `registerWebhook` and `tls.create`.
	certManager: {
		enabled: *true | bool

		createSelfSignedIssuer: {
			enabled: *true | bool

			// Lifetime and renewal window of the intermediate CA
			// certificate.
			duration:    *"8760h" | #Duration
			renewBefore: *"720h" | #Duration
		}

		// Reference to an existing issuer for signing the serving
		// certificate; required when `createSelfSignedIssuer.enabled`
		// is false.
		issuerRef: {
			name?: string & =~".+"
			kind:  *"ClusterIssuer" | "Issuer"
			group: *"cert-manager.io" | string & =~".+"
		}

		// Lifetime and renewal window of the serving certificate.
		duration:    *"168h" | #Duration
		renewBefore: *"24h" | #Duration

		privateKey: {
			algorithm: *"RSA" | "ECDSA" | "Ed25519"

			// Key size for RSA or ECDSA; ignored for Ed25519.
			size: *2048 | int
		}

		// Annotations added to the cert-manager resources.
		annotations?: timoniv1.#Annotations
	}

	// The serving certificate Secret. With `create` the Secret is
	// rendered from the PEM-encoded `caCert`, `cert` and `key` values
	// and the webhook configuration carries `caCert` as its CA bundle;
	// otherwise `secretName` references the Secret holding the
	// cert-manager-issued certificate or pre-provisioned `ca`, `cert`
	// and `key` entries.
	tls: {
		create:     *false | bool
		secretName: *"vpa-tls-certs" | string & =~".+"
		caCert:     *"" | string
		cert:       *"" | string
		key:        *"" | string
	}

	// Override the pod volumes and volume mounts, replacing the default
	// serving certificate Secret mount at `/etc/tls-certs`.
	volumes?: [...corev1.#Volume]
	volumeMounts?: [...corev1.#VolumeMount]

	_guard: "valid"
	_guard: [
		if certManager.enabled && registerWebhook {
			"certManager and registerWebhook are mutually exclusive"
		},
		if certManager.enabled && tls.create {
			"certManager and tls.create are mutually exclusive"
		},
		if certManager.enabled && !certManager.createSelfSignedIssuer.enabled && certManager.issuerRef.name == _|_ {
			"certManager.issuerRef.name is required when createSelfSignedIssuer is disabled"
		},
		// cert-manager mode reloads the renewed certificates from disk;
		// disabling the reload would pin the initial certificate until
		// the next pod restart and break after the first renewal.
		if certManager.enabled && list.Contains(A.extraArgs, "--reload-cert=false") {
			"--reload-cert=false conflicts with certManager mode"
		},
		// Something must provide the webhook configuration and its CA:
		// cert-manager (cainjector), tls.create (caCert as the CA
		// bundle) or the application itself (registerWebhook).
		if !certManager.enabled && !tls.create && !registerWebhook {
			"one of certManager.enabled, tls.create or registerWebhook is required"
		},
		if tls.create && !registerWebhook && tls.caCert == "" {
			"tls.caCert is required to set the webhook CA bundle when registerWebhook is disabled"
		},
		"valid",
	][0]
}
