package controller

import (
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/external-secrets/templates/config"
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

// Metadata of the controller cluster-scoped objects (and the RBAC
// roles created in other namespaces).
#ClusterObjectMeta: {
	#config:      config.#Config
	name!:        string
	namespace?:   string & =~".+"
	annotations?: timoniv1.#Annotations
	labels:       #config.metadata.labels
	labels: (timoniv1.#StdLabelComponent): _component
	if #config.metadata.annotations != _|_ {
		annotations: #config.metadata.annotations
	}
}

// Label selector of the controller pods.
#SelectorLabels: {
	#config:                       config.#Config
	[string]:                      string
	(timoniv1.#StdLabelName):      #config.metadata.name
	(timoniv1.#StdLabelComponent): _component
}
