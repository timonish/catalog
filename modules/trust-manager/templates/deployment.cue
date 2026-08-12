package templates

import (
	"strings"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	_config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   _config.metadata
	if _config.deploymentAnnotations != _|_ {
		metadata: annotations: _config.deploymentAnnotations
	}

	spec: appsv1.#DeploymentSpec & {
		replicas:             _config.replicas
		revisionHistoryLimit: _config.revisionHistoryLimit
		if _config.strategy != _|_ {
			strategy: _config.strategy
		}
		selector: matchLabels: _config.selector.labels
		template: {
			metadata: {
				labels: _config.selector.labels
				if _config.podLabels != _|_ {
					labels: _config.podLabels
				}
				if _config.podAnnotations != _|_ {
					annotations: _config.podAnnotations
				}
			}
			spec: corev1.#PodSpec & {
				automountServiceAccountToken: _config.automountServiceAccountToken
				serviceAccountName:           _config.serviceAccount.name
				securityContext:              _config.podSecurityContext
				nodeSelector:                 _config.nodeSelector
				if _config.affinity != _|_ {
					affinity: _config.affinity
				}
				if _config.tolerations != _|_ {
					tolerations: _config.tolerations
				}
				if _config.topologySpreadConstraints != _|_ {
					topologySpreadConstraints: _config.topologySpreadConstraints
				}
				if _config.priorityClassName != _|_ {
					priorityClassName: _config.priorityClassName
				}
				if _config.schedulerName != _|_ {
					schedulerName: _config.schedulerName
				}
				if _config.terminationGracePeriodSeconds != _|_ {
					terminationGracePeriodSeconds: _config.terminationGracePeriodSeconds
				}
				if _config.dnsConfig != _|_ {
					dnsConfig: _config.dnsConfig
				}
				if _config.dnsPolicy != _|_ {
					dnsPolicy: _config.dnsPolicy
				}
				if _config.webhook.hostNetwork {
					hostNetwork: true
				}

				if _config.defaultPackage.enabled {
					initContainers: [{
						name:            "cert-manager-package-debian"
						image:           _config.defaultPackage.image.reference
						imagePullPolicy: _config.defaultPackage.image.pullPolicy
						args: [
							"/copyandmaybepause",
							"/debian-package",
							"/packages",
						]
						securityContext: _config.defaultPackage.securityContext
						if _config.defaultPackage.resources != _|_ {
							resources: _config.defaultPackage.resources
						}
						volumeMounts: [{
							name:      "packages"
							mountPath: "/packages"
							readOnly:  false
						}]
					}]
				}

				containers: [{
					name:            "trust-manager"
					image:           _config.image.reference
					imagePullPolicy: _config.image.pullPolicy
					securityContext: _config.securityContext
					ports: [
						{
							name:          "webhook"
							protocol:      "TCP"
							containerPort: _config.webhook.port
						},
						{
							name:          "metrics"
							protocol:      "TCP"
							containerPort: _config.metrics.port
						},
					]
					readinessProbe: _config.readinessProbe
					if _config.env != _|_ {
						env: _config.env
					}
					args: [
						if _config.minTLSVersion != _|_ {
							"--tls-min-version=\(_config.minTLSVersion)"
						},
						if _config.cipherSuites != _|_ {
							"--tls-cipher-suites=\(_config.cipherSuites)"
						},
						"--log-format=\(_config.logFormat)",
						"--log-level=\(_config.logLevel)",
						"--metrics-port=\(_config.metrics.port)",
						"--readiness-probe-port=\(_config.readinessProbe.httpGet.port)",
						"--readiness-probe-path=\(_config.readinessProbe.httpGet.path)",
						"--leader-elect=\(_config.leaderElection.enabled)",
						"--leader-election-lease-duration=\(_config.leaderElection.leaseDuration)",
						"--leader-election-renew-deadline=\(_config.leaderElection.renewDeadline)",
						"--trust-namespace=\(_config.trust.namespace)",
						"--webhook-host=\(_config.webhook.host)",
						"--webhook-port=\(_config.webhook.port)",
						"--webhook-certificate-dir=/tls",
						if _config.defaultPackage.enabled {
							"--default-package-location=/packages/cert-manager-package-debian.json"
						},
						if _config.secretTargets.enabled {
							"--secret-targets-enabled=true"
						},
						if _config.filterExpiredCertificates {
							"--filter-expired-certificates=true"
						},
						if _config.filterNonCACerts {
							"--filter-non-ca-certs=true"
						},
						if _config.targetNamespaces != _|_ {
							"--target-namespaces=\(strings.Join(_config.targetNamespaces, ","))"
						},
						for a in _config.extraArgs {a},
					]
					if _config.resources != _|_ {
						resources: _config.resources
					}
					volumeMounts: [
						{
							name:      "tls"
							mountPath: "/tls"
							readOnly:  true
						},
						if _config.defaultPackage.enabled {
							{
								name:      "packages"
								mountPath: "/packages"
								readOnly:  true
							}
						},
						if _config.extraVolumeMounts != _|_ for m in _config.extraVolumeMounts {m},
					]
				}]
				volumes: [
					if _config.defaultPackage.enabled {
						{
							name: "packages"
							emptyDir: sizeLimit: "50M"
						}
					},
					{
						name: "tls"
						secret: {
							secretName:  "\(_config.metadata.name)-tls"
							defaultMode: 420
						}
					},
					if _config.extraVolumes != _|_ for v in _config.extraVolumes {v},
				]
			}
		}
	}
}
