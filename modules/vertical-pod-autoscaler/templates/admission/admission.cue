package admission

import (
	timoniv1 "timoni.sh/core/v1alpha1"
	"timoni.sh/vertical-pod-autoscaler/templates/config"
)

// The admission-controller objects are named `<instance>-admission-controller` and
// labeled with the component label.
_component: "admission-controller"

// Metadata of the admission-controller namespaced objects.
#ObjectMeta: timoniv1.#MetaComponent & {
	#config:    config.#Config
	#Meta:      #config.metadata
	#Component: _component
}

// Metadata of the admission-controller cluster-scoped objects (and the RBAC
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

// Label selector of the admission-controller pods.
#SelectorLabels: {
	#config:                       config.#Config
	[string]:                      string
	(timoniv1.#StdLabelName):      #config.metadata.name
	(timoniv1.#StdLabelComponent): _component
}

// The port of the admission-controller metrics listener.
#MetricsPort: 8944
