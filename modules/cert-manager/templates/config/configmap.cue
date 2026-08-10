package config

import (
	"encoding/json"
	"strings"
	"uuid"
)

// ImmutableConfigMap generates an immutable ConfigMap whose name is
// suffixed with the hash of the data, so referencing workloads roll on
// config changes. Unlike the Timoni core #ImmutableConfig it accepts
// component metadata, where the object name carries the component
// suffix while the name label stays the instance name.
#ImmutableConfigMap: {
	#Meta: {
		name!:      string
		namespace!: string
		labels: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	#Data: {[string]: string}

	let hash = strings.Split(uuid.SHA1(uuid.ns.DNS, json.Marshal(#Data)), "-")[0]

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #Meta.name + "-" + hash
		namespace: #Meta.namespace
		labels:    #Meta.labels
		if #Meta.annotations != _|_ {
			annotations: #Meta.annotations
		}
	}
	immutable: true
	data:      #Data
}
