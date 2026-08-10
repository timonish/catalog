

package v2

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	"k8s.io/api/core/v1"
)

#HorizontalPodAutoscaler: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #HorizontalPodAutoscalerSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #HorizontalPodAutoscalerStatus @go(Status) @protobuf(3,bytes,opt)
}

#HorizontalPodAutoscalerSpec: {
	scaleTargetRef: #CrossVersionObjectReference @go(ScaleTargetRef) @protobuf(1,bytes,opt)

	minReplicas?: int32 @go(MinReplicas,*int32) @protobuf(2,varint,opt)

	maxReplicas: int32 @go(MaxReplicas) @protobuf(3,varint,opt)

	metrics?: [...#MetricSpec] @go(Metrics,[]MetricSpec) @protobuf(4,bytes,rep)

	behavior?: #HorizontalPodAutoscalerBehavior @go(Behavior,*HorizontalPodAutoscalerBehavior) @protobuf(5,bytes,opt)
}

#CrossVersionObjectReference: {
	kind: string @go(Kind) @protobuf(1,bytes,opt)

	name: string @go(Name) @protobuf(2,bytes,opt)

	apiVersion?: string @go(APIVersion) @protobuf(3,bytes,opt)
}

#MetricSpec: {
	type: #MetricSourceType @go(Type) @protobuf(1,bytes)

	object?: #ObjectMetricSource @go(Object,*ObjectMetricSource) @protobuf(2,bytes,opt)

	pods?: #PodsMetricSource @go(Pods,*PodsMetricSource) @protobuf(3,bytes,opt)

	resource?: #ResourceMetricSource @go(Resource,*ResourceMetricSource) @protobuf(4,bytes,opt)

	containerResource?: #ContainerResourceMetricSource @go(ContainerResource,*ContainerResourceMetricSource) @protobuf(7,bytes,opt)

	external?: #ExternalMetricSource @go(External,*ExternalMetricSource) @protobuf(5,bytes,opt)
}

#HorizontalPodAutoscalerBehavior: {
	scaleUp?: #HPAScalingRules @go(ScaleUp,*HPAScalingRules) @protobuf(1,bytes,opt)

	scaleDown?: #HPAScalingRules @go(ScaleDown,*HPAScalingRules) @protobuf(2,bytes,opt)
}

#ScalingPolicySelect: string // #enumScalingPolicySelect

#enumScalingPolicySelect:
	#MaxChangePolicySelect |
	#MinChangePolicySelect |
	#DisabledPolicySelect

#MaxChangePolicySelect: #ScalingPolicySelect & "Max"

#MinChangePolicySelect: #ScalingPolicySelect & "Min"

#DisabledPolicySelect: #ScalingPolicySelect & "Disabled"

#HPAScalingRules: {
	stabilizationWindowSeconds?: int32 @go(StabilizationWindowSeconds,*int32) @protobuf(3,varint,opt)

	selectPolicy?: #ScalingPolicySelect @go(SelectPolicy,*ScalingPolicySelect) @protobuf(1,bytes,opt)

	policies?: [...#HPAScalingPolicy] @go(Policies,[]HPAScalingPolicy) @protobuf(2,bytes,rep)

	tolerance?: resource.#Quantity @go(Tolerance,*resource.Quantity) @protobuf(4,bytes,opt)
}

#HPAScalingPolicyType: string // #enumHPAScalingPolicyType

#enumHPAScalingPolicyType:
	#PodsScalingPolicy |
	#PercentScalingPolicy

#PodsScalingPolicy: #HPAScalingPolicyType & "Pods"

#PercentScalingPolicy: #HPAScalingPolicyType & "Percent"

#HPAScalingPolicy: {
	type: #HPAScalingPolicyType @go(Type) @protobuf(1,bytes,opt,casttype=HPAScalingPolicyType)

	value: int32 @go(Value) @protobuf(2,varint,opt)

	periodSeconds: int32 @go(PeriodSeconds) @protobuf(3,varint,opt)
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

#ObjectMetricSource: {
	describedObject: #CrossVersionObjectReference @go(DescribedObject) @protobuf(1,bytes)

	target: #MetricTarget @go(Target) @protobuf(2,bytes)

	metric: #MetricIdentifier @go(Metric) @protobuf(3,bytes)
}

#PodsMetricSource: {
	metric: #MetricIdentifier @go(Metric) @protobuf(1,bytes)

	target: #MetricTarget @go(Target) @protobuf(2,bytes)
}

#ResourceMetricSource: {
	name: v1.#ResourceName @go(Name) @protobuf(1,bytes)

	target: #MetricTarget @go(Target) @protobuf(2,bytes)
}

#ContainerResourceMetricSource: {
	name: v1.#ResourceName @go(Name) @protobuf(1,bytes)

	target: #MetricTarget @go(Target) @protobuf(2,bytes)

	container: string @go(Container) @protobuf(3,bytes,opt)
}

#ExternalMetricSource: {
	metric: #MetricIdentifier @go(Metric) @protobuf(1,bytes)

	target: #MetricTarget @go(Target) @protobuf(2,bytes)
}

#MetricIdentifier: {
	name: string @go(Name) @protobuf(1,bytes)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(2,bytes)
}

#MetricTarget: {
	type: #MetricTargetType @go(Type) @protobuf(1,bytes)

	value?: resource.#Quantity @go(Value,*resource.Quantity) @protobuf(2,bytes,opt)

	averageValue?: resource.#Quantity @go(AverageValue,*resource.Quantity) @protobuf(3,bytes,opt)

	averageUtilization?: int32 @go(AverageUtilization,*int32) @protobuf(4,bytes,opt)
}

#MetricTargetType: string // #enumMetricTargetType

#enumMetricTargetType:
	#UtilizationMetricType |
	#ValueMetricType |
	#AverageValueMetricType

#UtilizationMetricType: #MetricTargetType & "Utilization"

#ValueMetricType: #MetricTargetType & "Value"

#AverageValueMetricType: #MetricTargetType & "AverageValue"

#HorizontalPodAutoscalerStatus: {
	observedGeneration?: int64 @go(ObservedGeneration,*int64) @protobuf(1,varint,opt)

	lastScaleTime?: metav1.#Time @go(LastScaleTime,*metav1.Time) @protobuf(2,bytes,opt)

	currentReplicas?: int32 @go(CurrentReplicas) @protobuf(3,varint,opt)

	desiredReplicas: int32 @go(DesiredReplicas) @protobuf(4,varint,opt)

	currentMetrics?: [...#MetricStatus] @go(CurrentMetrics,[]MetricStatus) @protobuf(5,bytes,rep)

	conditions?: [...#HorizontalPodAutoscalerCondition] @go(Conditions,[]HorizontalPodAutoscalerCondition) @protobuf(6,bytes,rep)
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

#MetricStatus: {
	type: #MetricSourceType @go(Type) @protobuf(1,bytes)

	object?: #ObjectMetricStatus @go(Object,*ObjectMetricStatus) @protobuf(2,bytes,opt)

	pods?: #PodsMetricStatus @go(Pods,*PodsMetricStatus) @protobuf(3,bytes,opt)

	resource?: #ResourceMetricStatus @go(Resource,*ResourceMetricStatus) @protobuf(4,bytes,opt)

	containerResource?: #ContainerResourceMetricStatus @go(ContainerResource,*ContainerResourceMetricStatus) @protobuf(7,bytes,opt)

	external?: #ExternalMetricStatus @go(External,*ExternalMetricStatus) @protobuf(5,bytes,opt)
}

#ObjectMetricStatus: {
	metric: #MetricIdentifier @go(Metric) @protobuf(1,bytes)

	current: #MetricValueStatus @go(Current) @protobuf(2,bytes)

	describedObject: #CrossVersionObjectReference @go(DescribedObject) @protobuf(3,bytes)
}

#PodsMetricStatus: {
	metric: #MetricIdentifier @go(Metric) @protobuf(1,bytes)

	current: #MetricValueStatus @go(Current) @protobuf(2,bytes)
}

#ResourceMetricStatus: {
	name: v1.#ResourceName @go(Name) @protobuf(1,bytes)

	current: #MetricValueStatus @go(Current) @protobuf(2,bytes)
}

#ContainerResourceMetricStatus: {
	name: v1.#ResourceName @go(Name) @protobuf(1,bytes)

	current: #MetricValueStatus @go(Current) @protobuf(2,bytes)

	container: string @go(Container) @protobuf(3,bytes,opt)
}

#ExternalMetricStatus: {
	metric: #MetricIdentifier @go(Metric) @protobuf(1,bytes)

	current: #MetricValueStatus @go(Current) @protobuf(2,bytes)
}

#MetricValueStatus: {
	value?: resource.#Quantity @go(Value,*resource.Quantity) @protobuf(1,bytes,opt)

	averageValue?: resource.#Quantity @go(AverageValue,*resource.Quantity) @protobuf(2,bytes,opt)

	averageUtilization?: int32 @go(AverageUtilization,*int32) @protobuf(3,bytes,opt)
}

#HorizontalPodAutoscalerList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#HorizontalPodAutoscaler] @go(Items,[]HorizontalPodAutoscaler) @protobuf(2,bytes,rep)
}
