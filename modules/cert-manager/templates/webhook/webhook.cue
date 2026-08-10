package webhook

import (
	"encoding/yaml"

	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/cert-manager/templates/config"
)

// The webhook objects are named `<instance>-webhook` and labeled with
// the component label.
_component: "webhook"

// Metadata of the webhook namespaced objects.
#ObjectMeta: timoniv1.#MetaComponent & {
	#config:    config.#Config
	#Meta:      #config.metadata
	#Component: _component
}

// Metadata of the webhook cluster-scoped objects (and the RBAC roles
// created in other namespaces).
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

// Label selector of the webhook pods.
#SelectorLabels: {
	#config:                       config.#Config
	[string]:                      string
	(timoniv1.#StdLabelName):      #config.metadata.name
	(timoniv1.#StdLabelComponent): _component
}

// The port of the metrics listener (0 when disabled).
#MetricsPort: {
	#config: config.#Config
	port: (config.#ListenPort & {#Address: #config.webhook.config.metricsListenAddress}).port
}

// The webhook configuration file rendered into an immutable ConfigMap;
// the hash-suffixed name rolls the deployment on changes.
#ConfigMap: config.#ImmutableConfigMap & {
	#config: config.#Config
	_config: #config
	#Meta: #ObjectMeta & {#config: _config}
	#Data: "config.yaml": yaml.Marshal(_config.webhook.config)
}
