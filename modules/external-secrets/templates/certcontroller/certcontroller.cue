package certcontroller

import (
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/external-secrets/templates/config"
)

// The cert-controller objects are named `<instance>-cert-controller`
// and labeled with the component label.
_component: "cert-controller"

// Metadata of the cert-controller namespaced objects.
#ObjectMeta: timoniv1.#MetaComponent & {
	#config:    config.#Config
	#Meta:      #config.metadata
	#Component: _component
}

// Metadata of the cert-controller cluster-scoped objects.
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

// Label selector of the cert-controller pods.
#SelectorLabels: {
	#config:                       config.#Config
	[string]:                      string
	(timoniv1.#StdLabelName):      #config.metadata.name
	(timoniv1.#StdLabelComponent): _component
}
