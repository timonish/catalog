package templates

import (
	"list"

	rbacv1 "k8s.io/api/rbac/v1"
)

// The RBAC rules derived from the enabled sources: each rule is granted
// only when a source that reads those resources is configured.
#SourcesRules: {
	_config: #Config

	_has: {
		for s in [
			"node", "pod", "service", "ingress",
			"contour-httpproxy", "gloo-proxy", "openshift-route",
			"skipper-routegroup", "istio-gateway", "istio-virtualservice",
			"ambassador-host", "crd",
			"gateway-httproute", "gateway-grpcroute", "gateway-tlsroute",
			"gateway-tcproute", "gateway-udproute",
			"kong-tcpingress", "traefik-proxy",
			"f5-virtualserver", "f5-transportserver",
		] {
			"\(s)": list.Contains(_config.sources, s)
		}
	}

	_podReaders: _has."pod" || _has."service" || _has."contour-httpproxy" ||
		_has."gloo-proxy" || _has."openshift-route" || _has."skipper-routegroup"

	rules: [...rbacv1.#PolicyRule]
	rules: [
		if !_config.namespaced && (_has."node" || _podReaders) {
			{
				apiGroups: [""]
				resources: ["nodes"]
				verbs: ["list", "watch"]
			}
		},
		if _podReaders {
			{
				apiGroups: [""]
				resources: ["pods"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."service" || _has."contour-httpproxy" || _has."gloo-proxy" ||
			_has."istio-gateway" || _has."istio-virtualservice" ||
			_has."openshift-route" || _has."skipper-routegroup" {
			{
				apiGroups: [""]
				resources: ["services"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."service" {
			{
				apiGroups: ["discovery.k8s.io"]
				resources: ["endpointslices"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."ingress" || _has."istio-gateway" || _has."istio-virtualservice" ||
			_has."contour-httpproxy" || _has."openshift-route" ||
			_has."skipper-routegroup" || _has."gloo-proxy" {
			{
				apiGroups: ["extensions", "networking.k8s.io"]
				resources: ["ingresses"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."istio-gateway" || _has."istio-virtualservice" {
			{
				apiGroups: ["networking.istio.io"]
				resources: ["gateways"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."istio-virtualservice" {
			{
				apiGroups: ["networking.istio.io"]
				resources: ["virtualservices"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."ambassador-host" {
			{
				apiGroups: ["getambassador.io"]
				resources: ["hosts", "ingresses"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."contour-httpproxy" {
			{
				apiGroups: ["projectcontour.io"]
				resources: ["httpproxies"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."crd" {
			{
				apiGroups: ["externaldns.k8s.io"]
				resources: ["dnsendpoints"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."crd" {
			{
				apiGroups: ["externaldns.k8s.io"]
				resources: ["dnsendpoints/status"]
				verbs: ["update"]
			}
		},
		if _config._hasGatewaySources && (!_config.namespaced || _config.gatewayNamespace == _|_) {
			{
				apiGroups: ["gateway.networking.k8s.io"]
				resources: ["gateways"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _config._hasGatewaySources && (!_config.namespaced || _config.gatewayNamespace == _|_) &&
			_config.enableGatewayListenerSets {
			{
				apiGroups: ["gateway.networking.k8s.io"]
				resources: ["listenersets"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _config._hasGatewaySources && !_config.namespaced {
			{
				apiGroups: [""]
				resources: ["namespaces"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."gateway-httproute" {
			{
				apiGroups: ["gateway.networking.k8s.io"]
				resources: ["httproutes"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."gateway-grpcroute" {
			{
				apiGroups: ["gateway.networking.k8s.io"]
				resources: ["grpcroutes"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."gateway-tlsroute" {
			{
				apiGroups: ["gateway.networking.k8s.io"]
				resources: ["tlsroutes"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."gateway-tcproute" {
			{
				apiGroups: ["gateway.networking.k8s.io"]
				resources: ["tcproutes"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."gateway-udproute" {
			{
				apiGroups: ["gateway.networking.k8s.io"]
				resources: ["udproutes"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."gloo-proxy" {
			{
				apiGroups: ["gloo.solo.io", "gateway.solo.io"]
				resources: ["proxies", "virtualservices", "gateways"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."kong-tcpingress" {
			{
				apiGroups: ["configuration.konghq.com"]
				resources: ["tcpingresses"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."traefik-proxy" {
			{
				apiGroups: ["traefik.containo.us", "traefik.io"]
				resources: ["ingressroutes", "ingressroutetcps", "ingressrouteudps"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."openshift-route" {
			{
				apiGroups: ["route.openshift.io"]
				resources: ["routes"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."skipper-routegroup" {
			{
				apiGroups: ["zalando.org"]
				resources: ["routegroups"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _has."skipper-routegroup" {
			{
				apiGroups: ["zalando.org"]
				resources: ["routegroups/status"]
				verbs: ["patch", "update"]
			}
		},
		if _has."f5-virtualserver" || _has."f5-transportserver" {
			{
				apiGroups: ["cis.f5.com"]
				resources: ["virtualservers", "transportservers"]
				verbs: ["get", "watch", "list"]
			}
		},
		if _config.rbac.extraRules != _|_ for r in _config.rbac.extraRules {r},
	]
}

// ClusterRole granting access to the enabled sources cluster-wide.
#SourcesClusterRole: rbacv1.#ClusterRole & {
	_config: #Config
	let cfg = _config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   _config.metadata.name
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: (#SourcesRules & {_config: cfg}).rules
}

#SourcesClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   "\(_config.metadata.name)-viewer"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     _config.metadata.name
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// Role granting access to the enabled sources in the watched namespace,
// used in the namespaced scope.
#SourcesRole: rbacv1.#Role & {
	_config: #Config
	let cfg = _config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name: _config.metadata.name
		namespace: [
			if _config.sourceNamespace != _|_ {_config.sourceNamespace},
			_config.metadata.namespace,
		][0]
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: (#SourcesRules & {_config: cfg}).rules
}

#SourcesRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name: "\(_config.metadata.name)-viewer"
		namespace: [
			if _config.sourceNamespace != _|_ {_config.sourceNamespace},
			_config.metadata.namespace,
		][0]
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     _config.metadata.name
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// ClusterRole for namespace discovery, needed to find Gateway API
// gateways across the cluster when running namespaced without a
// pinned gateway namespace.
#NamespacesClusterRole: rbacv1.#ClusterRole & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRole"
	metadata: {
		name:   "\(_config.metadata.name)-namespaces"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [{
		apiGroups: [""]
		resources: ["namespaces"]
		verbs: ["get", "watch", "list"]
	}]
}

#NamespacesClusterRoleBinding: rbacv1.#ClusterRoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "ClusterRoleBinding"
	metadata: {
		name:   "\(_config.metadata.name)-namespaces"
		labels: _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "ClusterRole"
		name:     "\(_config.metadata.name)-namespaces"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}

// Role granting access to Gateway API gateways in the pinned gateway
// namespace, used in the fully namespaced scope.
#GatewayRole: rbacv1.#Role & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "Role"
	metadata: {
		name:      "\(_config.metadata.name)-gateway"
		namespace: _config.gatewayNamespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	rules: [
		{
			apiGroups: ["gateway.networking.k8s.io"]
			resources: ["gateways"]
			verbs: ["get", "watch", "list"]
		},
		if _config.enableGatewayListenerSets {
			{
				apiGroups: ["gateway.networking.k8s.io"]
				resources: ["listenersets"]
				verbs: ["get", "watch", "list"]
			}
		},
	]
}

#GatewayRoleBinding: rbacv1.#RoleBinding & {
	_config:    #Config
	apiVersion: "rbac.authorization.k8s.io/v1"
	kind:       "RoleBinding"
	metadata: {
		name:      "\(_config.metadata.name)-gateway"
		namespace: _config.gatewayNamespace
		labels:    _config.metadata.labels
		if _config.metadata.annotations != _|_ {
			annotations: _config.metadata.annotations
		}
	}
	roleRef: {
		apiGroup: "rbac.authorization.k8s.io"
		kind:     "Role"
		name:     "\(_config.metadata.name)-gateway"
	}
	subjects: [{
		kind:      "ServiceAccount"
		name:      _config.serviceAccount.name
		namespace: _config.metadata.namespace
	}]
}
