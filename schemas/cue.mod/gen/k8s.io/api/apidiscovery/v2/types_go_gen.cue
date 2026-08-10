

package v2

import "k8s.io/apimachinery/pkg/apis/meta/v1"

#APIGroupDiscoveryList: {
	v1.#TypeMeta

	metadata?: v1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#APIGroupDiscovery] @go(Items,[]APIGroupDiscovery) @protobuf(2,bytes,rep)
}

#APIGroupDiscovery: {
	v1.#TypeMeta

	metadata?: v1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	versions?: [...#APIVersionDiscovery] @go(Versions,[]APIVersionDiscovery) @protobuf(2,bytes,rep)
}

#APIVersionDiscovery: {
	version: string @go(Version) @protobuf(1,bytes,opt)

	resources?: [...#APIResourceDiscovery] @go(Resources,[]APIResourceDiscovery) @protobuf(2,bytes,rep)

	freshness?: #DiscoveryFreshness @go(Freshness) @protobuf(3,bytes,opt)
}

#APIResourceDiscovery: {
	resource: string @go(Resource) @protobuf(1,bytes,opt)

	responseKind?: v1.#GroupVersionKind @go(ResponseKind,*v1.GroupVersionKind) @protobuf(2,bytes,opt)

	scope: #ResourceScope @go(Scope) @protobuf(3,bytes,opt)

	singularResource: string @go(SingularResource) @protobuf(4,bytes,opt)

	verbs: [...string] @go(Verbs,[]string) @protobuf(5,bytes,opt)

	shortNames?: [...string] @go(ShortNames,[]string) @protobuf(6,bytes,rep)

	categories?: [...string] @go(Categories,[]string) @protobuf(7,bytes,rep)

	subresources?: [...#APISubresourceDiscovery] @go(Subresources,[]APISubresourceDiscovery) @protobuf(8,bytes,rep)
}

#ResourceScope: string // #enumResourceScope

#enumResourceScope:
	#ScopeCluster |
	#ScopeNamespace

#ScopeCluster:   #ResourceScope & "Cluster"
#ScopeNamespace: #ResourceScope & "Namespaced"

#DiscoveryFreshness: string // #enumDiscoveryFreshness

#enumDiscoveryFreshness:
	#DiscoveryFreshnessCurrent |
	#DiscoveryFreshnessStale

#DiscoveryFreshnessCurrent: #DiscoveryFreshness & "Current"
#DiscoveryFreshnessStale:   #DiscoveryFreshness & "Stale"

#APISubresourceDiscovery: {
	subresource: string @go(Subresource) @protobuf(1,bytes,opt)

	responseKind?: v1.#GroupVersionKind @go(ResponseKind,*v1.GroupVersionKind) @protobuf(2,bytes,opt)

	acceptedTypes?: [...v1.#GroupVersionKind] @go(AcceptedTypes,[]v1.GroupVersionKind) @protobuf(3,bytes,rep)

	verbs: [...string] @go(Verbs,[]string) @protobuf(4,bytes,opt)
}
