package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#DaemonSet: appsv1.#DaemonSet & {
	_config:    #Config
	apiVersion: "apps/v1"
	kind:       "DaemonSet"
	metadata:   _config.metadata
	if _config.daemonsetLabels != _|_ {
		metadata: labels: _config.daemonsetLabels
	}
	if _config.daemonsetAnnotations != _|_ {
		metadata: annotations: _config.daemonsetAnnotations
	}

	// The exporter binds to all interfaces, or to the node address
	// resolved through the downward API.
	_env: [
		if _config.listenOnAllInterfaces {
			{name: "HOST_IP", value: "0.0.0.0"}
		},
		if !_config.listenOnAllInterfaces {
			{name: "HOST_IP", valueFrom: fieldRef: fieldPath: "status.hostIP"}
		},
		if _config.env != _|_ for e in _config.env {e},
	]

	_volumeMounts: [
		{
			name:      "proc"
			mountPath: "/host/proc"
			readOnly:  true
			if _config.hostProcFsMount.mountPropagation != _|_ {
				mountPropagation: _config.hostProcFsMount.mountPropagation
			}
		},
		{
			name:      "sys"
			mountPath: "/host/sys"
			readOnly:  true
			if _config.hostSysFsMount.mountPropagation != _|_ {
				mountPropagation: _config.hostSysFsMount.mountPropagation
			}
		},
		if _config.hostRootFsMount.enabled {
			{
				name:             "root"
				mountPath:        "/host/root"
				readOnly:         true
				mountPropagation: _config.hostRootFsMount.mountPropagation
			}
		},
		if _config.extraVolumeMounts != _|_ for m in _config.extraVolumeMounts {m},
	]

	_volumes: [
		{
			name: "proc"
			hostPath: path: "/proc"
		},
		{
			name: "sys"
			hostPath: path: "/sys"
		},
		if _config.hostRootFsMount.enabled {
			{
				name: "root"
				hostPath: path: "/"
			}
		},
		if _config.extraVolumes != _|_ for v in _config.extraVolumes {v},
	]

	spec: appsv1.#DaemonSetSpec & {
		if _config.strategy != _|_ {
			updateStrategy: _config.strategy
		}
		if _config.revisionHistoryLimit != _|_ {
			revisionHistoryLimit: _config.revisionHistoryLimit
		}
		selector: matchLabels: _config.selector.labels
		template: corev1.#PodTemplateSpec & {
			metadata: {
				labels: _config.selector.labels
				if _config.podLabels != _|_ {
					labels: _config.podLabels
				}
				annotations: "kubectl.kubernetes.io/default-container": "node-exporter"
				annotations: _config.podAnnotations
			}
			spec: corev1.#PodSpec & {
				serviceAccountName:           _config.serviceAccount.name
				automountServiceAccountToken: _config.automountServiceAccountToken
				securityContext:              _config.podSecurityContext
				nodeSelector:                 _config.nodeSelector
				tolerations:                  _config.tolerations
				affinity:                     _config.affinity
				dnsPolicy:                    _config.dnsPolicy
				if _config.hostNetwork {
					hostNetwork: true
				}
				if _config.hostPID {
					hostPID: true
				}
				if _config.hostIPC {
					hostIPC: true
				}
				if _config.hostUsers != _|_ {
					hostUsers: _config.hostUsers
				}
				if _config.dnsConfig != _|_ {
					dnsConfig: _config.dnsConfig
				}
				if _config.imagePullSecrets != _|_ {
					imagePullSecrets: _config.imagePullSecrets
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
				if _config.initContainers != _|_ {
					initContainers: _config.initContainers
				}
				containers: [
					{
						name:            "node-exporter"
						image:           _config.image.reference
						imagePullPolicy: _config.image.pullPolicy
						securityContext: _config.securityContext
						args: [
							"--path.procfs=/host/proc",
							"--path.sysfs=/host/sys",
							if _config.hostRootFsMount.enabled {
								"--path.rootfs=/host/root"
							},
							if _config.hostRootFsMount.enabled {
								"--path.udev.data=/host/root/run/udev/data"
							},
							"--web.listen-address=[$(HOST_IP)]:\(_config.service.targetPort)",
							for a in _config.extraArgs {a},
						]
						env: _env
						ports: [{
							name:          _config.service.portName
							protocol:      "TCP"
							containerPort: _config.service.targetPort
						}]
						livenessProbe:  _config.livenessProbe
						readinessProbe: _config.readinessProbe
						if _config.resources != _|_ {
							resources: _config.resources
						}
						if _config.terminationMessagePath != _|_ {
							terminationMessagePath: _config.terminationMessagePath
						}
						if _config.terminationMessagePolicy != _|_ {
							terminationMessagePolicy: _config.terminationMessagePolicy
						}
						volumeMounts: _volumeMounts
					},
					if _config.extraContainers != _|_ for c in _config.extraContainers {c},
				]
				volumes: _volumes
			}
		}
	}
}
