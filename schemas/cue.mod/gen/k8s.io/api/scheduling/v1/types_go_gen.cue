

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	apiv1 "k8s.io/api/core/v1"
)

#PriorityClass: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	value?: int32 @go(Value) @protobuf(2,bytes,opt)

	globalDefault?: bool @go(GlobalDefault) @protobuf(3,bytes,opt)

	description?: string @go(Description) @protobuf(4,bytes,opt)

	preemptionPolicy?: apiv1.#PreemptionPolicy @go(PreemptionPolicy,*apiv1.PreemptionPolicy) @protobuf(5,bytes,opt)
}

#PriorityClassList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#PriorityClass] @go(Items,[]PriorityClass) @protobuf(2,bytes,rep)
}
