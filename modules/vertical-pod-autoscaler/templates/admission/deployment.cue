package admission

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

#Deployment: appsv1.#Deployment & {
	#config: config.#Config
	_config: #config

	_ac: _config.admissionController
	_selectorLabels: #SelectorLabels & {#config: _config}

	// The serving certificate files mounted into the container; the
	// cert-manager Secret keys differ from the pre-provisioned layout.
	_tlsVolume: corev1.#Volume & {
		name: "tls-certs"
		secret: {
			defaultMode: 420
			secretName:  _ac.tls.secretName
			if _ac.certManager.enabled {
				items: [
					{key: "ca.crt", path: "caCert.pem"},
					{key: "tls.crt", path: "serverCert.pem"},
					{key: "tls.key", path: "serverKey.pem"},
				]
			}
			if !_ac.certManager.enabled {
				items: [
					{key: "ca", path: "caCert.pem"},
					{key: "cert", path: "serverCert.pem"},
					{key: "key", path: "serverKey.pem"},
				]
			}
		}
	}

	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata: #ObjectMeta & {#config: _config}
	if _ac.deploymentAnnotations != _|_ {
		metadata: annotations: _ac.deploymentAnnotations
	}

	spec: appsv1.#DeploymentSpec & {
		replicas:             _ac.replicas
		revisionHistoryLimit: _ac.revisionHistoryLimit
		if _ac.strategy != _|_ {
			strategy: _ac.strategy
		}
		selector: matchLabels: _selectorLabels
		template: {
			metadata: {
				labels: _selectorLabels
				if _ac.podLabels != _|_ {
					labels: _ac.podLabels
				}
				if _ac.podAnnotations != _|_ {
					annotations: _ac.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _ac.serviceAccount.name
				automountServiceAccountToken: _ac.automountServiceAccountToken
				if !_ac.serviceAccount.create {
					if _config.imagePullSecrets != _|_ {
						imagePullSecrets: _config.imagePullSecrets
					}
				}
				securityContext: _ac.podSecurityContext
				if _ac.priorityClassName != _|_ {
					priorityClassName: _ac.priorityClassName
				}
				if _ac.hostNetwork {
					hostNetwork: true
				}
				if _ac.dnsPolicy != _|_ {
					dnsPolicy: _ac.dnsPolicy
				}
				if _ac.dnsConfig != _|_ {
					dnsConfig: _ac.dnsConfig
				}
				if _ac.schedulerName != _|_ {
					schedulerName: _ac.schedulerName
				}
				if _ac.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: _ac.terminationGracePeriodSeconds
				}
				containers: [{
					name:            "admission-controller"
					image:           _ac.image.reference
					imagePullPolicy: _ac.image.pullPolicy
					securityContext: _ac.securityContext
					env: [
						{
							name: "NAMESPACE"
							valueFrom: fieldRef: fieldPath: "metadata.namespace"
						},
						if _ac.env != _|_ for e in _ac.env {e},
					]
					args: [
						"--v=4",
						"--stderrthreshold=info",
						"--register-webhook=\(_ac.registerWebhook)",
						"--webhook-service=\(_ac.service.name)",
						"--reload-cert=true",
						for a in _ac.extraArgs {a},
					]
					ports: [
						{
							containerPort: 8000
							protocol:      "TCP"
						},
						{
							name:          "prometheus"
							containerPort: #MetricsPort
							protocol:      "TCP"
						},
					]
					livenessProbe:  _ac.livenessProbe
					readinessProbe: _ac.readinessProbe
					volumeMounts: [
						if _ac.certManager.enabled || _ac.volumeMounts == _|_ {
							{
								name:      "tls-certs"
								mountPath: "/etc/tls-certs"
								readOnly:  true
							}
						},
						if !_ac.certManager.enabled if _ac.volumeMounts != _|_ for m in _ac.volumeMounts {m},
					]
					if _ac.resources != _|_ {
						resources: _ac.resources
					}
				}]
				volumes: [
					if _ac.certManager.enabled || _ac.volumes == _|_ {
						_tlsVolume
					},
					if !_ac.certManager.enabled if _ac.volumes != _|_ for v in _ac.volumes {v},
				]
				nodeSelector: _ac.nodeSelector
				affinity:     _ac.affinity
				if _ac.tolerations != _|_ {
					tolerations: _ac.tolerations
				}
				if _ac.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _ac.topologySpreadConstraints
				}
			}
		}
	}
}
