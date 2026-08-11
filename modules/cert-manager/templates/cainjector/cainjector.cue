package cainjector

import (
	"encoding/yaml"

	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/cert-manager/templates/config"
)

// The cainjector objects are named `<instance>-cainjector` and labeled
// with the component label.
_component: "cainjector"

// Metadata of the cainjector namespaced objects.
#ObjectMeta: timoniv1.#MetaComponent & {
	#config:    config.#Config
	#Meta:      #config.metadata
	#Component: _component
}

// Metadata of the cainjector cluster-scoped objects (and the RBAC
// roles created in other namespaces).
#ClusterObjectMeta: {
	#config:      config.#Config
	name:         *"\(#config.metadata.name)-\(_component)" | string
	namespace?:   string & =~".+"
	annotations?: timoniv1.#Annotations
	labels:       #config.metadata.labels
	labels: (timoniv1.#StdLabelComponent): _component
	if #config.metadata.annotations != _|_ {
		annotations: #config.metadata.annotations
	}
}

// Label selector of the cainjector pods.
#SelectorLabels: {
	#config:                       config.#Config
	[string]:                      string
	(timoniv1.#StdLabelName):      #config.metadata.name
	(timoniv1.#StdLabelComponent): _component
}

// The port of the metrics listener (0 when disabled).
#MetricsPort: {
	#config: config.#Config
	port: (config.#ListenPort & {#Address: #config.cainjector.config.metricsListenAddress}).port
}

// The cainjector configuration file rendered into an immutable
// ConfigMap; the hash-suffixed name rolls the deployment on changes.
#ConfigMap: timoniv1.#ImmutableConfig & {
	#config: config.#Config
	_config: #config
	#Meta: #ObjectMeta & {#config: _config}
	#Data: "config.yaml": yaml.Marshal(_config.cainjector.config)
}
