@if(debug)

package main

// Values used by `timoni mod vet --debug`.
// They enable the experimental channel so the x-k8s.io CRDs and the
// experimental schema variants of the shared CRDs are validated too;
// the default `timoni build` guard covers the standard channel.
values: {
	channel: "experimental"

	commonLabels: "app.kubernetes.io/part-of": "networking"

	crds: keep: true
}
