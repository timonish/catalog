

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
)

#DisruptionBudgetCause: metav1.#CauseType & "DisruptionBudget"

#PodDisruptionBudgetSpec: {
	minAvailable?: intstr.#IntOrString @go(MinAvailable,*intstr.IntOrString) @protobuf(1,bytes,opt)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(2,bytes,opt)

	maxUnavailable?: intstr.#IntOrString @go(MaxUnavailable,*intstr.IntOrString) @protobuf(3,bytes,opt)

	unhealthyPodEvictionPolicy?: #UnhealthyPodEvictionPolicyType @go(UnhealthyPodEvictionPolicy,*UnhealthyPodEvictionPolicyType) @protobuf(4,bytes,opt)
}

#UnhealthyPodEvictionPolicyType: string // #enumUnhealthyPodEvictionPolicyType

#enumUnhealthyPodEvictionPolicyType:
	#IfHealthyBudget |
	#AlwaysAllow

#IfHealthyBudget: #UnhealthyPodEvictionPolicyType & "IfHealthyBudget"

#AlwaysAllow: #UnhealthyPodEvictionPolicyType & "AlwaysAllow"

#PodDisruptionBudgetStatus: {
	observedGeneration?: int64 @go(ObservedGeneration) @protobuf(1,varint,opt)

	disruptedPods?: {[string]: metav1.#Time} @go(DisruptedPods,map[string]metav1.Time) @protobuf(2,bytes,rep)

	disruptionsAllowed?: int32 @go(DisruptionsAllowed) @protobuf(3,varint,opt)

	currentHealthy?: int32 @go(CurrentHealthy) @protobuf(4,varint,opt)

	desiredHealthy?: int32 @go(DesiredHealthy) @protobuf(5,varint,opt)

	expectedPods?: int32 @go(ExpectedPods) @protobuf(6,varint,opt)

	conditions?: [...metav1.#Condition] @go(Conditions,[]metav1.Condition) @protobuf(7,bytes,rep)
}

#DisruptionAllowedCondition: "DisruptionAllowed"

#SyncFailedReason: "SyncFailed"

#SufficientPodsReason: "SufficientPods"

#InsufficientPodsReason: "InsufficientPods"

#PodDisruptionBudget: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #PodDisruptionBudgetSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #PodDisruptionBudgetStatus @go(Status) @protobuf(3,bytes,opt)
}

#PodDisruptionBudgetList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#PodDisruptionBudget] @go(Items,[]PodDisruptionBudget) @protobuf(2,bytes,rep)
}

#Eviction: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	deleteOptions?: metav1.#DeleteOptions @go(DeleteOptions,*metav1.DeleteOptions) @protobuf(2,bytes,opt)
}
