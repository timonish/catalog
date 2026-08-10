package templates

import (
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
)

// CertgenJob runs the upstream certificate generator, creating the
// control plane certificate secrets that do not exist yet: the Job is
// idempotent and never overwrites existing secrets. The
// `timoni.sh/force` annotation recreates the immutable Job on every
// apply. In cert-manager TLS mode the certificates are issued by
// cert-manager and the Job only maintains the `envoy-oidc-hmac`
// secret; the webhook CA patching is disabled as cert-manager injects
// the CA bundle declaratively.
#CertgenJob: batchv1.#Job & {
	_config: #Config

	_args: [
		if _config.tls.mode == "cert-manager" || !_config.topologyInjector.enabled {
			"--disable-topology-injector"
		},
		for a in _config.certgen.args {a},
	]

	apiVersion: "batch/v1"
	kind:       "Job"
	metadata: {
		name:      "\(_config.metadata.name)-certgen"
		namespace: _config.metadata.namespace
		labels:    _config.metadata.labels
		annotations: "timoni.sh/force": "enabled"
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
		if _config.certgen.annotations != _|_ {
			annotations: _config.certgen.annotations
		}
	}
	spec: batchv1.#JobSpec & {
		backoffLimit: 1
		completions:  1
		parallelism:  1
		if _config.certgen.ttlSecondsAfterFinished >= 0 {
			ttlSecondsAfterFinished: _config.certgen.ttlSecondsAfterFinished
		}
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: app: "certgen"
				if _config.certgen.podLabels != _|_ {
					labels: _config.certgen.podLabels
				}
				if _config.certgen.podAnnotations != _|_ {
					annotations: _config.certgen.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName: "\(_config.metadata.name)-certgen"
				// The generator needs API access to create the secrets;
				// the token mount is disabled on the ServiceAccount
				// itself.
				automountServiceAccountToken: true
				restartPolicy:                "Never"
				securityContext:              _config.podSecurityContext
				nodeSelector:                 _config.certgen.nodeSelector
				if _config.imagePullSecrets != _|_ {
					imagePullSecrets: _config.imagePullSecrets
				}
				if _config.certgen.affinity != _|_ {
					affinity: _config.certgen.affinity
				}
				if _config.certgen.tolerations != _|_ {
					tolerations: _config.certgen.tolerations
				}
				containers: [{
					name:            "envoy-gateway-certgen"
					image:           _config.image.reference
					imagePullPolicy: _config.image.pullPolicy
					command: ["envoy-gateway", "certgen"]
					if len(_args) > 0 {
						args: _args
					}
					env: [{
						name: "ENVOY_GATEWAY_NAMESPACE"
						valueFrom: fieldRef: fieldPath: "metadata.namespace"
					}, {
						name:  "KUBERNETES_CLUSTER_DOMAIN"
						value: _config.kubernetesClusterDomain
					}]
					if _config.certgen.resources != _|_ {
						resources: _config.certgen.resources
					}
					securityContext: _config.securityContext
				}]
			}
		}
	}
}
