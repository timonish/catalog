

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/api/core/v1"
)

#EndpointSlice: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	addressType: #AddressType @go(AddressType) @protobuf(4,bytes,rep)

	endpoints?: [...#Endpoint] @go(Endpoints,[]Endpoint) @protobuf(2,bytes,rep)

	ports?: [...#EndpointPort] @go(Ports,[]EndpointPort) @protobuf(3,bytes,rep)
}

#AddressType: string // #enumAddressType

#enumAddressType:
	#AddressTypeIPv4 |
	#AddressTypeIPv6 |
	#AddressTypeFQDN

#AddressTypeIPv4: #AddressType & "IPv4"

#AddressTypeIPv6: #AddressType & "IPv6"

#AddressTypeFQDN: #AddressType & "FQDN"

#Endpoint: {
	addresses: [...string] @go(Addresses,[]string) @protobuf(1,bytes,rep)

	conditions?: #EndpointConditions @go(Conditions) @protobuf(2,bytes,opt)

	hostname?: string @go(Hostname,*string) @protobuf(3,bytes,opt)

	targetRef?: v1.#ObjectReference @go(TargetRef,*v1.ObjectReference) @protobuf(4,bytes,opt)

	deprecatedTopology?: {[string]: string} @go(DeprecatedTopology,map[string]string) @protobuf(5,bytes,opt)

	nodeName?: string @go(NodeName,*string) @protobuf(6,bytes,opt)

	zone?: string @go(Zone,*string) @protobuf(7,bytes,opt)

	hints?: #EndpointHints @go(Hints,*EndpointHints) @protobuf(8,bytes,opt)
}

#EndpointConditions: {
	ready?: bool @go(Ready,*bool) @protobuf(1,bytes)

	serving?: bool @go(Serving,*bool) @protobuf(2,bytes)

	terminating?: bool @go(Terminating,*bool) @protobuf(3,bytes)
}

#EndpointHints: {
	forZones?: [...#ForZone] @go(ForZones,[]ForZone) @protobuf(1,bytes)

	forNodes?: [...#ForNode] @go(ForNodes,[]ForNode) @protobuf(2,bytes)
}

#ForZone: {
	name: string @go(Name) @protobuf(1,bytes)
}

#ForNode: {
	name: string @go(Name) @protobuf(1,bytes)
}

#EndpointPort: {
	name?: string @go(Name,*string) @protobuf(1,bytes)

	protocol?: v1.#Protocol @go(Protocol,*v1.Protocol) @protobuf(2,bytes)

	port?: int32 @go(Port,*int32) @protobuf(3,bytes,opt)

	appProtocol?: string @go(AppProtocol,*string) @protobuf(4,bytes)
}

#EndpointSliceList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#EndpointSlice] @go(Items,[]EndpointSlice) @protobuf(2,bytes,rep)
}
