

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	"k8s.io/api/core/v1"
)

#CrossVersionObjectReference: {
	kind: string @go(Kind) @protobuf(1,bytes,opt)

	name: string @go(Name) @protobuf(2,bytes,opt)

	apiVersion?: string @go(APIVersion) @protobuf(3,bytes,opt)
}

#HorizontalPodAutoscalerSpec: {
	scaleTargetRef: #CrossVersionObjectReference @go(ScaleTargetRef) @protobuf(1,bytes,opt)

	minReplicas?: int32 @go(MinReplicas,*int32) @protobuf(2,varint,opt)

	maxReplicas: int32 @go(MaxReplicas) @protobuf(3,varint,opt)

	targetCPUUtilizationPercentage?: int32 @go(TargetCPUUtilizationPercentage,*int32) @protobuf(4,varint,opt)
}

#HorizontalPodAutoscalerStatus: {
	observedGeneration?: int64 @go(ObservedGeneration,*int64) @protobuf(1,varint,opt)

	lastScaleTime?: metav1.#Time @go(LastScaleTime,*metav1.Time) @protobuf(2,bytes,opt)

	currentReplicas: int32 @go(CurrentReplicas) @protobuf(3,varint,opt)

	desiredReplicas: int32 @go(DesiredReplicas) @protobuf(4,varint,opt)

	currentCPUUtilizationPercentage?: int32 @go(CurrentCPUUtilizationPercentage,*int32) @protobuf(5,varint,opt)
}

#HorizontalPodAutoscaler: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #HorizontalPodAutoscalerSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #HorizontalPodAutoscalerStatus @go(Status) @protobuf(3,bytes,opt)
}

#HorizontalPodAutoscalerList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#HorizontalPodAutoscaler] @go(Items,[]HorizontalPodAutoscaler) @protobuf(2,bytes,rep)
}

#Scale: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #ScaleSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #ScaleStatus @go(Status) @protobuf(3,bytes,opt)
}

#ScaleSpec: {
	replicas?: int32 @go(Replicas) @protobuf(1,varint,opt)
}

#ScaleStatus: {
	replicas: int32 @go(Replicas) @protobuf(1,varint,opt)

	selector?: string @go(Selector) @protobuf(2,bytes,opt)
}

#MetricSourceType: string // #enumMetricSourceType

#enumMetricSourceType:
	#ObjectMetricSourceType |
	#PodsMetricSourceType |
	#ResourceMetricSourceType |
	#ContainerResourceMetricSourceType |
	#ExternalMetricSourceType

#ObjectMetricSourceType: #MetricSourceType & "Object"

#PodsMetricSourceType: #MetricSourceType & "Pods"

#ResourceMetricSourceType: #MetricSourceType & "Resource"

#ContainerResourceMetricSourceType: #MetricSourceType & "ContainerResource"

#ExternalMetricSourceType: #MetricSourceType & "External"

#MetricSpec: {
	type: #MetricSourceType @go(Type) @protobuf(1,bytes)

	object?: #ObjectMetricSource @go(Object,*ObjectMetricSource) @protobuf(2,bytes,opt)

	pods?: #PodsMetricSource @go(Pods,*PodsMetricSource) @protobuf(3,bytes,opt)

	resource?: #ResourceMetricSource @go(Resource,*ResourceMetricSource) @protobuf(4,bytes,opt)

	containerResource?: #ContainerResourceMetricSource @go(ContainerResource,*ContainerResourceMetricSource) @protobuf(7,bytes,opt)

	external?: #ExternalMetricSource @go(External,*ExternalMetricSource) @protobuf(5,bytes,opt)
}

#ObjectMetricSource: {
	target: #CrossVersionObjectReference @go(Target) @protobuf(1,bytes)

	metricName: string @go(MetricName) @protobuf(2,bytes)

	targetValue: resource.#Quantity @go(TargetValue) @protobuf(3,bytes)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(4,bytes)

	averageValue?: resource.#Quantity @go(AverageValue,*resource.Quantity) @protobuf(5,bytes)
}

#PodsMetricSource: {
	metricName: string @go(MetricName) @protobuf(1,bytes)

	targetAverageValue: resource.#Quantity @go(TargetAverageValue) @protobuf(2,bytes)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(3,bytes)
}

#ResourceMetricSource: {
	name: v1.#ResourceName @go(Name) @protobuf(1,bytes)

	targetAverageUtilization?: int32 @go(TargetAverageUtilization,*int32) @protobuf(2,varint,opt)

	targetAverageValue?: resource.#Quantity @go(TargetAverageValue,*resource.Quantity) @protobuf(3,bytes,opt)
}

#ContainerResourceMetricSource: {
	name: v1.#ResourceName @go(Name) @protobuf(1,bytes)

	targetAverageUtilization?: int32 @go(TargetAverageUtilization,*int32) @protobuf(2,varint,opt)

	targetAverageValue?: resource.#Quantity @go(TargetAverageValue,*resource.Quantity) @protobuf(3,bytes,opt)

	container: string @go(Container) @protobuf(5,bytes,opt)
}

#ExternalMetricSource: {
	metricName: string @go(MetricName) @protobuf(1,bytes)

	metricSelector?: metav1.#LabelSelector @go(MetricSelector,*metav1.LabelSelector) @protobuf(2,bytes,opt)

	targetValue?: resource.#Quantity @go(TargetValue,*resource.Quantity) @protobuf(3,bytes,opt)

	targetAverageValue?: resource.#Quantity @go(TargetAverageValue,*resource.Quantity) @protobuf(4,bytes,opt)
}

#MetricStatus: {
	type: #MetricSourceType @go(Type) @protobuf(1,bytes)

	object?: #ObjectMetricStatus @go(Object,*ObjectMetricStatus) @protobuf(2,bytes,opt)

	pods?: #PodsMetricStatus @go(Pods,*PodsMetricStatus) @protobuf(3,bytes,opt)

	resource?: #ResourceMetricStatus @go(Resource,*ResourceMetricStatus) @protobuf(4,bytes,opt)

	containerResource?: #ContainerResourceMetricStatus @go(ContainerResource,*ContainerResourceMetricStatus) @protobuf(7,bytes,opt)

	external?: #ExternalMetricStatus @go(External,*ExternalMetricStatus) @protobuf(5,bytes,opt)
}

#HorizontalPodAutoscalerConditionType: string // #enumHorizontalPodAutoscalerConditionType

#enumHorizontalPodAutoscalerConditionType:
	#ScalingActive |
	#AbleToScale |
	#ScalingLimited |
	#ScaledToZero

#ScalingActive: #HorizontalPodAutoscalerConditionType & "ScalingActive"

#AbleToScale: #HorizontalPodAutoscalerConditionType & "AbleToScale"

#ScalingLimited: #HorizontalPodAutoscalerConditionType & "ScalingLimited"

#ScaledToZero: #HorizontalPodAutoscalerConditionType & "ScaledToZero"

#HorizontalPodAutoscalerCondition: {
	type: #HorizontalPodAutoscalerConditionType @go(Type) @protobuf(1,bytes)

	status: v1.#ConditionStatus @go(Status) @protobuf(2,bytes)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(3,bytes,opt)

	reason?: string @go(Reason) @protobuf(4,bytes,opt)

	message?: string @go(Message) @protobuf(5,bytes,opt)
}

#ObjectMetricStatus: {
	target: #CrossVersionObjectReference @go(Target) @protobuf(1,bytes)

	metricName: string @go(MetricName) @protobuf(2,bytes)

	currentValue: resource.#Quantity @go(CurrentValue) @protobuf(3,bytes)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(4,bytes)

	averageValue?: resource.#Quantity @go(AverageValue,*resource.Quantity) @protobuf(5,bytes)
}

#PodsMetricStatus: {
	metricName: string @go(MetricName) @protobuf(1,bytes)

	currentAverageValue: resource.#Quantity @go(CurrentAverageValue) @protobuf(2,bytes)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(3,bytes)
}

#ResourceMetricStatus: {
	name: v1.#ResourceName @go(Name) @protobuf(1,bytes)

	currentAverageUtilization?: int32 @go(CurrentAverageUtilization,*int32) @protobuf(2,bytes,opt)

	currentAverageValue: resource.#Quantity @go(CurrentAverageValue) @protobuf(3,bytes)
}

#ContainerResourceMetricStatus: {
	name: v1.#ResourceName @go(Name) @protobuf(1,bytes)

	currentAverageUtilization?: int32 @go(CurrentAverageUtilization,*int32) @protobuf(2,bytes,opt)

	currentAverageValue: resource.#Quantity @go(CurrentAverageValue) @protobuf(3,bytes)

	container: string @go(Container) @protobuf(4,bytes,opt)
}

#ExternalMetricStatus: {
	metricName: string @go(MetricName) @protobuf(1,bytes)

	metricSelector?: metav1.#LabelSelector @go(MetricSelector,*metav1.LabelSelector) @protobuf(2,bytes,opt)

	currentValue: resource.#Quantity @go(CurrentValue) @protobuf(3,bytes)

	currentAverageValue?: resource.#Quantity @go(CurrentAverageValue,*resource.Quantity) @protobuf(4,bytes,opt)
}
