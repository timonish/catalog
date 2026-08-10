

package v1

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

#CoordinatedLeaseStrategy: string // #enumCoordinatedLeaseStrategy

#enumCoordinatedLeaseStrategy:
	#OldestEmulationVersion

#OldestEmulationVersion: #CoordinatedLeaseStrategy & "OldestEmulationVersion"

#Lease: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #LeaseSpec @go(Spec) @protobuf(2,bytes,opt)
}

#LeaseSpec: {
	holderIdentity?: string @go(HolderIdentity,*string) @protobuf(1,bytes,opt)

	leaseDurationSeconds?: int32 @go(LeaseDurationSeconds,*int32) @protobuf(2,varint,opt)

	acquireTime?: metav1.#MicroTime @go(AcquireTime,*metav1.MicroTime) @protobuf(3,bytes,opt)

	renewTime?: metav1.#MicroTime @go(RenewTime,*metav1.MicroTime) @protobuf(4,bytes,opt)

	leaseTransitions?: int32 @go(LeaseTransitions,*int32) @protobuf(5,varint,opt)

	strategy?: #CoordinatedLeaseStrategy @go(Strategy,*CoordinatedLeaseStrategy) @protobuf(6,bytes,opt)

	preferredHolder?: string @go(PreferredHolder,*string) @protobuf(7,bytes,opt)
}

#LeaseList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Lease] @go(Items,[]Lease) @protobuf(2,bytes,rep)
}
