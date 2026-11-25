

package v1alpha3

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

#Workload: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #WorkloadSpec @go(Spec) @protobuf(2,bytes,opt)
}

#WorkloadList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Workload] @go(Items,[]Workload) @protobuf(2,bytes,rep)
}

#WorkloadMaxPodGroupTemplates: 8

#WorkloadMaxTreeDepth: 4

#WorkloadSpec: {
	controllerRef?: #TypedLocalObjectReference @go(ControllerRef,*TypedLocalObjectReference) @protobuf(1,bytes,opt)

	podGroupTemplates?: [...#PodGroupTemplate] @go(PodGroupTemplates,[]PodGroupTemplate) @protobuf(2,bytes,rep)

	compositePodGroupTemplates?: [...#CompositePodGroupTemplate] @go(CompositePodGroupTemplates,[]CompositePodGroupTemplate) @protobuf(3,bytes,rep)
}

#TypedLocalObjectReference: {
	apiGroup?: string @go(APIGroup) @protobuf(1,bytes,opt)

	kind: string @go(Kind) @protobuf(2,bytes,opt)

	name: string @go(Name) @protobuf(3,bytes,opt)
}

#MaxPodGroupResourceClaims: 4

#PodGroupTemplate: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	schedulingPolicy: #PodGroupSchedulingPolicy @go(SchedulingPolicy) @protobuf(2,bytes,opt)

	schedulingConstraints?: #PodGroupSchedulingConstraints @go(SchedulingConstraints,*PodGroupSchedulingConstraints) @protobuf(3,bytes,opt)

	resourceClaims?: [...#PodGroupResourceClaim] @go(ResourceClaims,[]PodGroupResourceClaim) @protobuf(4,bytes,rep)

	disruptionMode?: #DisruptionMode @go(DisruptionMode,*DisruptionMode) @protobuf(5,bytes,opt)

	priorityClassName?: string @go(PriorityClassName) @protobuf(6,bytes,opt)

	priority?: int32 @go(Priority,*int32) @protobuf(7,varint,opt)

	preemptionPolicy?: #PreemptionPolicy @go(PreemptionPolicy,*PreemptionPolicy) @protobuf(8,bytes,opt)
}

#CompositePodGroupTemplate: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	schedulingPolicy: #CompositePodGroupSchedulingPolicy @go(SchedulingPolicy) @protobuf(2,bytes,opt)

	schedulingConstraints?: #CompositePodGroupSchedulingConstraints @go(SchedulingConstraints,*CompositePodGroupSchedulingConstraints) @protobuf(3,bytes,opt)

	disruptionMode?: #CompositeDisruptionMode @go(DisruptionMode,*CompositeDisruptionMode) @protobuf(4,bytes,opt)

	priorityClassName?: string @go(PriorityClassName) @protobuf(5,bytes,opt)

	priority?: int32 @go(Priority,*int32) @protobuf(6,varint,opt)

	preemptionPolicy?: #PreemptionPolicy @go(PreemptionPolicy,*PreemptionPolicy) @protobuf(7,bytes,opt)

	podGroupTemplates?: [...#PodGroupTemplate] @go(PodGroupTemplates,[]PodGroupTemplate) @protobuf(8,bytes,rep)

	compositePodGroupTemplates?: [...#CompositePodGroupTemplate] @go(CompositePodGroupTemplates,[]CompositePodGroupTemplate) @protobuf(9,bytes,rep)
}

#PodGroupSchedulingPolicy: {
	basic?: #BasicSchedulingPolicy @go(Basic,*BasicSchedulingPolicy) @protobuf(1,bytes,opt)

	gang?: #GangSchedulingPolicy @go(Gang,*GangSchedulingPolicy) @protobuf(2,bytes,opt)
}

#BasicSchedulingPolicy: {}

#GangSchedulingPolicy: {
	minCount: int32 @go(MinCount) @protobuf(1,varint,opt)
}

#PodGroupResourceClaim: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	resourceClaimName?: string @go(ResourceClaimName,*string) @protobuf(2,bytes,opt)

	resourceClaimTemplateName?: string @go(ResourceClaimTemplateName,*string) @protobuf(3,bytes,opt)
}

#DisruptionMode: {
	single?: #SingleDisruptionMode @go(Single,*SingleDisruptionMode) @protobuf(1,bytes,opt)

	all?: #AllDisruptionMode @go(All,*AllDisruptionMode) @protobuf(2,bytes,opt)
}

#SingleDisruptionMode: {}

#AllDisruptionMode: {}

#PreemptionPolicy: string // #enumPreemptionPolicy

#enumPreemptionPolicy:
	#PreemptLowerPriority |
	#PreemptNever

#PreemptLowerPriority: #PreemptionPolicy & "PreemptLowerPriority"

#PreemptNever: #PreemptionPolicy & "Never"

#PodGroup: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #PodGroupSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #PodGroupStatus @go(Status) @protobuf(3,bytes,opt)
}

#PodGroupList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#PodGroup] @go(Items,[]PodGroup) @protobuf(2,bytes,rep)
}

#PodGroupSpec: {
	parentCompositePodGroupName?: string @go(ParentCompositePodGroupName,*string) @protobuf(1,bytes,opt)

	workloadRef?: #WorkloadReference @go(WorkloadRef,*WorkloadReference) @protobuf(2,bytes,opt)

	schedulingPolicy: #PodGroupSchedulingPolicy @go(SchedulingPolicy) @protobuf(3,bytes,opt)

	schedulingConstraints?: #PodGroupSchedulingConstraints @go(SchedulingConstraints,*PodGroupSchedulingConstraints) @protobuf(4,bytes,opt)

	resourceClaims?: [...#PodGroupResourceClaim] @go(ResourceClaims,[]PodGroupResourceClaim) @protobuf(5,bytes,rep)

	disruptionMode?: #DisruptionMode @go(DisruptionMode,*DisruptionMode) @protobuf(6,bytes,opt)

	priorityClassName?: string @go(PriorityClassName) @protobuf(7,bytes,opt)

	priority?: int32 @go(Priority,*int32) @protobuf(8,varint,opt)

	preemptionPolicy?: #PreemptionPolicy @go(PreemptionPolicy,*PreemptionPolicy) @protobuf(9,bytes,opt)
}

#PodGroupStatus: {
	conditions?: [...metav1.#Condition] @go(Conditions,[]metav1.Condition) @protobuf(1,bytes,rep)

	resourceClaimStatuses?: [...#PodGroupResourceClaimStatus] @go(ResourceClaimStatuses,[]PodGroupResourceClaimStatus) @protobuf(2,bytes,rep)
}

#PodGroupInitiallyScheduled: "PodGroupInitiallyScheduled"

#DisruptionTarget: "DisruptionTarget"

#PodGroupReasonUnschedulable: "Unschedulable"

#PodGroupReasonSchedulerError: "SchedulerError"

#PodGroupReasonPreemptionByScheduler: "PreemptionByScheduler"

#PodGroupResourceClaimStatus: {
	name: string @go(Name) @protobuf(1,bytes)

	resourceClaimName?: string @go(ResourceClaimName,*string) @protobuf(2,bytes,opt)
}

#WorkloadReference: {
	workloadName: string @go(WorkloadName) @protobuf(1,bytes,opt)

	templateName: string @go(TemplateName) @protobuf(2,bytes,opt)
}

#PodGroupSchedulingConstraints: {
	topology?: [...#TopologyConstraint] @go(Topology,[]TopologyConstraint) @protobuf(1,bytes,rep)
}

#TopologyConstraint: {
	key: string @go(Key) @protobuf(1,bytes,opt)
}

#WorkloadPodGroupSchedulingPolicy: {
	basic?: #WorkloadPodGroupBasicSchedulingPolicy @go(Basic,*WorkloadPodGroupBasicSchedulingPolicy) @protobuf(1,bytes,opt)

	gang?: #WorkloadPodGroupGangSchedulingPolicy @go(Gang,*WorkloadPodGroupGangSchedulingPolicy) @protobuf(2,bytes,opt)
}

#WorkloadPodGroupBasicSchedulingPolicy: {}

#WorkloadPodGroupGangSchedulingPolicy: {
	minCount?: int32 @go(MinCount,*int32) @protobuf(1,varint,opt)
}

#WorkloadPodGroupSchedulingConstraints: {
	topology?: [...#TopologyConstraint] @go(Topology,[]TopologyConstraint) @protobuf(1,bytes,rep)
}

#WorkloadPodGroupResourceClaim: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	resourceClaimName?: string @go(ResourceClaimName,*string) @protobuf(2,bytes,opt)

	resourceClaimTemplateName?: string @go(ResourceClaimTemplateName,*string) @protobuf(3,bytes,opt)
}

#WorkloadPodGroupDisruptionMode: {
	single?: #WorkloadPodGroupSingleDisruptionMode @go(Single,*WorkloadPodGroupSingleDisruptionMode) @protobuf(1,bytes,opt)

	all?: #WorkloadPodGroupAllDisruptionMode @go(All,*WorkloadPodGroupAllDisruptionMode) @protobuf(2,bytes,opt)
}

#WorkloadPodGroupSingleDisruptionMode: {}

#WorkloadPodGroupAllDisruptionMode: {}

#WorkloadCompositePodGroupSchedulingPolicy: {
	basic?: #WorkloadCompositePodGroupBasicSchedulingPolicy @go(Basic,*WorkloadCompositePodGroupBasicSchedulingPolicy) @protobuf(1,bytes,opt)

	gang?: #WorkloadCompositePodGroupGangSchedulingPolicy @go(Gang,*WorkloadCompositePodGroupGangSchedulingPolicy) @protobuf(2,bytes,opt)
}

#WorkloadCompositePodGroupBasicSchedulingPolicy: {}

#WorkloadCompositePodGroupGangSchedulingPolicy: {
	minGroupCount?: int32 @go(MinGroupCount,*int32) @protobuf(1,varint,opt)
}

#WorkloadCompositePodGroupSchedulingConstraints: {
	topology?: [...#TopologyConstraint] @go(Topology,[]TopologyConstraint) @protobuf(1,bytes,rep)
}

#WorkloadCompositePodGroupDisruptionMode: {
	single?: #WorkloadCompositePodGroupSingleDisruptionMode @go(Single,*WorkloadCompositePodGroupSingleDisruptionMode) @protobuf(1,bytes,opt)

	all?: #WorkloadCompositePodGroupAllDisruptionMode @go(All,*WorkloadCompositePodGroupAllDisruptionMode) @protobuf(2,bytes,opt)
}

#WorkloadCompositePodGroupSingleDisruptionMode: {}

#WorkloadCompositePodGroupAllDisruptionMode: {}

#CompositePodGroup: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #CompositePodGroupSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #CompositePodGroupStatus @go(Status) @protobuf(3,bytes,opt)
}

#CompositePodGroupList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#CompositePodGroup] @go(Items,[]CompositePodGroup) @protobuf(2,bytes,rep)
}

#CompositePodGroupSpec: {
	parentCompositePodGroupName?: string @go(ParentCompositePodGroupName,*string) @protobuf(1,bytes,opt)

	workloadRef: #WorkloadReference @go(WorkloadRef,*WorkloadReference) @protobuf(2,bytes,opt)

	schedulingPolicy: #CompositePodGroupSchedulingPolicy @go(SchedulingPolicy) @protobuf(3,bytes,opt)

	schedulingConstraints?: #CompositePodGroupSchedulingConstraints @go(SchedulingConstraints,*CompositePodGroupSchedulingConstraints) @protobuf(4,bytes,opt)

	disruptionMode?: #CompositeDisruptionMode @go(DisruptionMode,*CompositeDisruptionMode) @protobuf(5,bytes,opt)

	priorityClassName?: string @go(PriorityClassName) @protobuf(6,bytes,opt)

	priority?: int32 @go(Priority,*int32) @protobuf(7,varint,opt)

	preemptionPolicy?: #PreemptionPolicy @go(PreemptionPolicy,*PreemptionPolicy) @protobuf(8,bytes,opt)
}

#CompositePodGroupSchedulingPolicy: {
	basic?: #CompositeBasicSchedulingPolicy @go(Basic,*CompositeBasicSchedulingPolicy) @protobuf(1,bytes,opt)

	gang?: #CompositeGangSchedulingPolicy @go(Gang,*CompositeGangSchedulingPolicy) @protobuf(2,bytes,opt)
}

#CompositeBasicSchedulingPolicy: {}

#CompositeGangSchedulingPolicy: {
	minGroupCount: int32 @go(MinGroupCount) @protobuf(1,varint,req)
}

#CompositeDisruptionMode: {
	single?: #SingleCompositeDisruptionMode @go(Single,*SingleCompositeDisruptionMode) @protobuf(1,bytes,opt)

	all?: #AllCompositeDisruptionMode @go(All,*AllCompositeDisruptionMode) @protobuf(2,bytes,opt)
}

#SingleCompositeDisruptionMode: {}

#AllCompositeDisruptionMode: {}

#CompositePodGroupStatus: {
	conditions?: [...metav1.#Condition] @go(Conditions,[]metav1.Condition) @protobuf(1,bytes,rep)
}

#CompositePodGroupSchedulingConstraints: {
	topology?: [...#TopologyConstraint] @go(Topology,[]TopologyConstraint) @protobuf(1,bytes,rep)
}
