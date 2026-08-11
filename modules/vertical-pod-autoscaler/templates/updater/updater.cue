package updater

import (
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

// The updater objects are named `<instance>-updater` and
// labeled with the component label.
_component: "updater"

// Metadata of the updater namespaced objects.
#ObjectMeta: timoniv1.#MetaComponent & {
	#config:    config.#Config
	#Meta:      #config.metadata
	#Component: _component
}

// Metadata of the updater cluster-scoped objects (and the RBAC
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

// Label selector of the updater pods.
#SelectorLabels: {
	#config:                       config.#Config
	[string]:                      string
	(timoniv1.#StdLabelName):      #config.metadata.name
	(timoniv1.#StdLabelComponent): _component
}

// The port of the updater metrics listener.
#MetricsPort: 8943
