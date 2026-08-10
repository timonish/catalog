package controller

import (
	"encoding/yaml"

	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/cert-manager/templates/config"
)

// The controller keeps the bare instance name (its objects are the
// module's primary resources) and adds the component label to its
// objects and pod selector.
_component: "controller"

// Metadata of the controller objects: the instance metadata plus the
// component label.
#ObjectMeta: {
	#config: config.#Config
	#config.metadata
	labels: (timoniv1.#StdLabelComponent): _component
}

// Label selector of the controller pods.
#SelectorLabels: {
	#config:                       config.#Config
	[string]:                      string
	(timoniv1.#StdLabelName):      #config.metadata.name
	(timoniv1.#StdLabelComponent): _component
}

// The port of the metrics listener (0 when disabled) and the healthz
// listener.
#MetricsPort: {
	#config: config.#Config
	port: (config.#ListenPort & {#Address: #config.controller.config.metricsListenAddress}).port
}

#HealthzPort: {
	#config: config.#Config
	port: (config.#ListenPort & {#Address: #config.controller.config.healthzListenAddress}).port
}

// The controller configuration file rendered into an immutable
// ConfigMap; the hash-suffixed name rolls the deployment on changes.
#ConfigMap: config.#ImmutableConfigMap & {
	#config: config.#Config
	_config: #config
	#Meta: #ObjectMeta & {#config: _config}
	#Data: "config.yaml": yaml.Marshal(_config.controller.config)
}
