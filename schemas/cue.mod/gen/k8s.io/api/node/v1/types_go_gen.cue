

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	corev1 "k8s.io/api/core/v1"
)

#RuntimeClass: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	handler: string @go(Handler) @protobuf(2,bytes,opt)

	overhead?: #Overhead @go(Overhead,*Overhead) @protobuf(3,bytes,opt)

	scheduling?: #Scheduling @go(Scheduling,*Scheduling) @protobuf(4,bytes,opt)
}

#Overhead: {
	podFixed?: corev1.#ResourceList @go(PodFixed) @protobuf(1,bytes,opt,casttype=k8s.io/api/core/v1.ResourceList,castkey=k8s.io/api/core/v1.ResourceName,castvalue=k8s.io/apimachinery/pkg/api/resource.Quantity)
}

#Scheduling: {
	nodeSelector?: {[string]: string} @go(NodeSelector,map[string]string) @protobuf(1,bytes,opt)

	tolerations?: [...corev1.#Toleration] @go(Tolerations,[]corev1.Toleration) @protobuf(2,bytes,rep)
}

#RuntimeClassList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#RuntimeClass] @go(Items,[]RuntimeClass) @protobuf(2,bytes,rep)
}
