

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	"k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

#ControllerRevisionHashLabelKey: "controller-revision-hash"
#StatefulSetRevisionLabel:       "controller-revision-hash"
#DeprecatedRollbackTo:           "deprecated.deployment.rollback.to"
#DeprecatedTemplateGeneration:   "deprecated.daemonset.template.generation"
#StatefulSetPodNameLabel:        "statefulset.kubernetes.io/pod-name"
#PodIndexLabel:                  "apps.kubernetes.io/pod-index"

#StatefulSet: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #StatefulSetSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #StatefulSetStatus @go(Status) @protobuf(3,bytes,opt)
}

#PodManagementPolicyType: string // #enumPodManagementPolicyType

#enumPodManagementPolicyType:
	#OrderedReadyPodManagement |
	#ParallelPodManagement

#OrderedReadyPodManagement: #PodManagementPolicyType & "OrderedReady"

#ParallelPodManagement: #PodManagementPolicyType & "Parallel"

#StatefulSetUpdateStrategy: {
	type?: #StatefulSetUpdateStrategyType @go(Type) @protobuf(1,bytes,opt,casttype=StatefulSetStrategyType)

	rollingUpdate?: #RollingUpdateStatefulSetStrategy @go(RollingUpdate,*RollingUpdateStatefulSetStrategy) @protobuf(2,bytes,opt)
}

#StatefulSetUpdateStrategyType: string // #enumStatefulSetUpdateStrategyType

#enumStatefulSetUpdateStrategyType:
	#RollingUpdateStatefulSetStrategyType |
	#OnDeleteStatefulSetStrategyType

#RollingUpdateStatefulSetStrategyType: #StatefulSetUpdateStrategyType & "RollingUpdate"

#OnDeleteStatefulSetStrategyType: #StatefulSetUpdateStrategyType & "OnDelete"

#RollingUpdateStatefulSetStrategy: {
	partition?: int32 @go(Partition,*int32) @protobuf(1,varint,opt)

	maxUnavailable?: intstr.#IntOrString @go(MaxUnavailable,*intstr.IntOrString) @protobuf(2,varint,opt)
}

#PersistentVolumeClaimRetentionPolicyType: string // #enumPersistentVolumeClaimRetentionPolicyType

#enumPersistentVolumeClaimRetentionPolicyType:
	#RetainPersistentVolumeClaimRetentionPolicyType |
	#DeletePersistentVolumeClaimRetentionPolicyType

#RetainPersistentVolumeClaimRetentionPolicyType: #PersistentVolumeClaimRetentionPolicyType & "Retain"

#DeletePersistentVolumeClaimRetentionPolicyType: #PersistentVolumeClaimRetentionPolicyType & "Delete"

#StatefulSetPersistentVolumeClaimRetentionPolicy: {
	whenDeleted?: #PersistentVolumeClaimRetentionPolicyType @go(WhenDeleted) @protobuf(1,bytes,opt,casttype=PersistentVolumeClaimRetentionPolicyType)

	whenScaled?: #PersistentVolumeClaimRetentionPolicyType @go(WhenScaled) @protobuf(2,bytes,opt,casttype=PersistentVolumeClaimRetentionPolicyType)
}

#StatefulSetOrdinals: {
	start?: int32 @go(Start) @protobuf(1,varint,opt)
}

#StatefulSetSpec: {
	replicas?: int32 @go(Replicas,*int32) @protobuf(1,varint,opt)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(2,bytes,opt)

	template: v1.#PodTemplateSpec @go(Template) @protobuf(3,bytes,opt)

	volumeClaimTemplates?: [...v1.#PersistentVolumeClaim] @go(VolumeClaimTemplates,[]v1.PersistentVolumeClaim) @protobuf(4,bytes,rep)

	serviceName?: string @go(ServiceName) @protobuf(5,bytes,opt)

	podManagementPolicy?: #PodManagementPolicyType @go(PodManagementPolicy) @protobuf(6,bytes,opt,casttype=PodManagementPolicyType)

	updateStrategy?: #StatefulSetUpdateStrategy @go(UpdateStrategy) @protobuf(7,bytes,opt)

	revisionHistoryLimit?: int32 @go(RevisionHistoryLimit,*int32) @protobuf(8,varint,opt)

	minReadySeconds?: int32 @go(MinReadySeconds) @protobuf(9,varint,opt)

	persistentVolumeClaimRetentionPolicy?: #StatefulSetPersistentVolumeClaimRetentionPolicy @go(PersistentVolumeClaimRetentionPolicy,*StatefulSetPersistentVolumeClaimRetentionPolicy) @protobuf(10,bytes,opt)

	ordinals?: #StatefulSetOrdinals @go(Ordinals,*StatefulSetOrdinals) @protobuf(11,bytes,opt)
}

#StatefulSetStatus: {
	observedGeneration?: int64 @go(ObservedGeneration) @protobuf(1,varint,opt)

	replicas: int32 @go(Replicas) @protobuf(2,varint,opt)

	readyReplicas?: int32 @go(ReadyReplicas) @protobuf(3,varint,opt)

	currentReplicas?: int32 @go(CurrentReplicas) @protobuf(4,varint,opt)

	updatedReplicas?: int32 @go(UpdatedReplicas) @protobuf(5,varint,opt)

	currentRevision?: string @go(CurrentRevision) @protobuf(6,bytes,opt)

	updateRevision?: string @go(UpdateRevision) @protobuf(7,bytes,opt)

	collisionCount?: int32 @go(CollisionCount,*int32) @protobuf(9,varint,opt)

	conditions?: [...#StatefulSetCondition] @go(Conditions,[]StatefulSetCondition) @protobuf(10,bytes,rep)

	availableReplicas?: int32 @go(AvailableReplicas) @protobuf(11,varint,opt)
}

#StatefulSetConditionType: string

#StatefulSetCondition: {
	type: #StatefulSetConditionType @go(Type) @protobuf(1,bytes,opt,casttype=StatefulSetConditionType)

	status: v1.#ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=k8s.io/api/core/v1.ConditionStatus)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(3,bytes,opt)

	reason?: string @go(Reason) @protobuf(4,bytes,opt)

	message?: string @go(Message) @protobuf(5,bytes,opt)
}

#StatefulSetList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#StatefulSet] @go(Items,[]StatefulSet) @protobuf(2,bytes,rep)
}

#Deployment: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #DeploymentSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #DeploymentStatus @go(Status) @protobuf(3,bytes,opt)
}

#DeploymentSpec: {
	replicas?: int32 @go(Replicas,*int32) @protobuf(1,varint,opt)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(2,bytes,opt)

	template: v1.#PodTemplateSpec @go(Template) @protobuf(3,bytes,opt)

	strategy?: #DeploymentStrategy @go(Strategy) @protobuf(4,bytes,opt)

	minReadySeconds?: int32 @go(MinReadySeconds) @protobuf(5,varint,opt)

	revisionHistoryLimit?: int32 @go(RevisionHistoryLimit,*int32) @protobuf(6,varint,opt)

	paused?: bool @go(Paused) @protobuf(7,varint,opt)

	progressDeadlineSeconds?: int32 @go(ProgressDeadlineSeconds,*int32) @protobuf(9,varint,opt)
}

#DefaultDeploymentUniqueLabelKey: "pod-template-hash"

#DeploymentStrategy: {
	type?: #DeploymentStrategyType @go(Type) @protobuf(1,bytes,opt,casttype=DeploymentStrategyType)

	rollingUpdate?: #RollingUpdateDeployment @go(RollingUpdate,*RollingUpdateDeployment) @protobuf(2,bytes,opt)
}

#DeploymentStrategyType: string // #enumDeploymentStrategyType

#enumDeploymentStrategyType:
	#RecreateDeploymentStrategyType |
	#RollingUpdateDeploymentStrategyType

#RecreateDeploymentStrategyType: #DeploymentStrategyType & "Recreate"

#RollingUpdateDeploymentStrategyType: #DeploymentStrategyType & "RollingUpdate"

#RollingUpdateDeployment: {
	maxUnavailable?: intstr.#IntOrString @go(MaxUnavailable,*intstr.IntOrString) @protobuf(1,bytes,opt)

	maxSurge?: intstr.#IntOrString @go(MaxSurge,*intstr.IntOrString) @protobuf(2,bytes,opt)
}

#DeploymentStatus: {
	observedGeneration?: int64 @go(ObservedGeneration) @protobuf(1,varint,opt)

	replicas?: int32 @go(Replicas) @protobuf(2,varint,opt)

	updatedReplicas?: int32 @go(UpdatedReplicas) @protobuf(3,varint,opt)

	readyReplicas?: int32 @go(ReadyReplicas) @protobuf(7,varint,opt)

	availableReplicas?: int32 @go(AvailableReplicas) @protobuf(4,varint,opt)

	unavailableReplicas?: int32 @go(UnavailableReplicas) @protobuf(5,varint,opt)

	terminatingReplicas?: int32 @go(TerminatingReplicas,*int32) @protobuf(9,varint,opt)

	conditions?: [...#DeploymentCondition] @go(Conditions,[]DeploymentCondition) @protobuf(6,bytes,rep)

	collisionCount?: int32 @go(CollisionCount,*int32) @protobuf(8,varint,opt)
}

#DeploymentConditionType: string // #enumDeploymentConditionType

#enumDeploymentConditionType:
	#DeploymentAvailable |
	#DeploymentProgressing |
	#DeploymentReplicaFailure

#DeploymentAvailable: #DeploymentConditionType & "Available"

#DeploymentProgressing: #DeploymentConditionType & "Progressing"

#DeploymentReplicaFailure: #DeploymentConditionType & "ReplicaFailure"

#DeploymentCondition: {
	type: #DeploymentConditionType @go(Type) @protobuf(1,bytes,opt,casttype=DeploymentConditionType)

	status: v1.#ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=k8s.io/api/core/v1.ConditionStatus)

	lastUpdateTime?: metav1.#Time @go(LastUpdateTime) @protobuf(6,bytes,opt)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(7,bytes,opt)

	reason?: string @go(Reason) @protobuf(4,bytes,opt)

	message?: string @go(Message) @protobuf(5,bytes,opt)
}

#DeploymentList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Deployment] @go(Items,[]Deployment) @protobuf(2,bytes,rep)
}

#DaemonSetUpdateStrategy: {
	type?: #DaemonSetUpdateStrategyType @go(Type) @protobuf(1,bytes,opt)

	rollingUpdate?: #RollingUpdateDaemonSet @go(RollingUpdate,*RollingUpdateDaemonSet) @protobuf(2,bytes,opt)
}

#DaemonSetUpdateStrategyType: string // #enumDaemonSetUpdateStrategyType

#enumDaemonSetUpdateStrategyType:
	#RollingUpdateDaemonSetStrategyType |
	#OnDeleteDaemonSetStrategyType

#RollingUpdateDaemonSetStrategyType: #DaemonSetUpdateStrategyType & "RollingUpdate"

#OnDeleteDaemonSetStrategyType: #DaemonSetUpdateStrategyType & "OnDelete"

#RollingUpdateDaemonSet: {
	maxUnavailable?: intstr.#IntOrString @go(MaxUnavailable,*intstr.IntOrString) @protobuf(1,bytes,opt)

	maxSurge?: intstr.#IntOrString @go(MaxSurge,*intstr.IntOrString) @protobuf(2,bytes,opt)
}

#DaemonSetSpec: {
	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(1,bytes,opt)

	template: v1.#PodTemplateSpec @go(Template) @protobuf(2,bytes,opt)

	updateStrategy?: #DaemonSetUpdateStrategy @go(UpdateStrategy) @protobuf(3,bytes,opt)

	minReadySeconds?: int32 @go(MinReadySeconds) @protobuf(4,varint,opt)

	revisionHistoryLimit?: int32 @go(RevisionHistoryLimit,*int32) @protobuf(6,varint,opt)
}

#DaemonSetStatus: {
	currentNumberScheduled: int32 @go(CurrentNumberScheduled) @protobuf(1,varint,opt)

	numberMisscheduled: int32 @go(NumberMisscheduled) @protobuf(2,varint,opt)

	desiredNumberScheduled: int32 @go(DesiredNumberScheduled) @protobuf(3,varint,opt)

	numberReady: int32 @go(NumberReady) @protobuf(4,varint,opt)

	observedGeneration?: int64 @go(ObservedGeneration) @protobuf(5,varint,opt)

	updatedNumberScheduled?: int32 @go(UpdatedNumberScheduled) @protobuf(6,varint,opt)

	numberAvailable?: int32 @go(NumberAvailable) @protobuf(7,varint,opt)

	numberUnavailable?: int32 @go(NumberUnavailable) @protobuf(8,varint,opt)

	collisionCount?: int32 @go(CollisionCount,*int32) @protobuf(9,varint,opt)

	conditions?: [...#DaemonSetCondition] @go(Conditions,[]DaemonSetCondition) @protobuf(10,bytes,rep)
}

#DaemonSetConditionType: string

#DaemonSetCondition: {
	type: #DaemonSetConditionType @go(Type) @protobuf(1,bytes,opt,casttype=DaemonSetConditionType)

	status: v1.#ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=k8s.io/api/core/v1.ConditionStatus)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(3,bytes,opt)

	reason?: string @go(Reason) @protobuf(4,bytes,opt)

	message?: string @go(Message) @protobuf(5,bytes,opt)
}

#DaemonSet: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #DaemonSetSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #DaemonSetStatus @go(Status) @protobuf(3,bytes,opt)
}

#DefaultDaemonSetUniqueLabelKey: "controller-revision-hash"

#DaemonSetList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#DaemonSet] @go(Items,[]DaemonSet) @protobuf(2,bytes,rep)
}

#ReplicaSet: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #ReplicaSetSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #ReplicaSetStatus @go(Status) @protobuf(3,bytes,opt)
}

#ReplicaSetList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ReplicaSet] @go(Items,[]ReplicaSet) @protobuf(2,bytes,rep)
}

#ReplicaSetSpec: {
	replicas?: int32 @go(Replicas,*int32) @protobuf(1,varint,opt)

	minReadySeconds?: int32 @go(MinReadySeconds) @protobuf(4,varint,opt)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(2,bytes,opt)

	template?: v1.#PodTemplateSpec @go(Template) @protobuf(3,bytes,opt)
}

#ReplicaSetStatus: {
	replicas: int32 @go(Replicas) @protobuf(1,varint,opt)

	fullyLabeledReplicas?: int32 @go(FullyLabeledReplicas) @protobuf(2,varint,opt)

	readyReplicas?: int32 @go(ReadyReplicas) @protobuf(4,varint,opt)

	availableReplicas?: int32 @go(AvailableReplicas) @protobuf(5,varint,opt)

	terminatingReplicas?: int32 @go(TerminatingReplicas,*int32) @protobuf(7,varint,opt)

	observedGeneration?: int64 @go(ObservedGeneration) @protobuf(3,varint,opt)

	conditions?: [...#ReplicaSetCondition] @go(Conditions,[]ReplicaSetCondition) @protobuf(6,bytes,rep)
}

#ReplicaSetConditionType: string // #enumReplicaSetConditionType

#enumReplicaSetConditionType:
	#ReplicaSetReplicaFailure

#ReplicaSetReplicaFailure: #ReplicaSetConditionType & "ReplicaFailure"

#ReplicaSetCondition: {
	type: #ReplicaSetConditionType @go(Type) @protobuf(1,bytes,opt,casttype=ReplicaSetConditionType)

	status: v1.#ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=k8s.io/api/core/v1.ConditionStatus)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(3,bytes,opt)

	reason?: string @go(Reason) @protobuf(4,bytes,opt)

	message?: string @go(Message) @protobuf(5,bytes,opt)
}

#ControllerRevision: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	data?: runtime.#RawExtension @go(Data) @protobuf(2,bytes,opt)

	revision: int64 @go(Revision) @protobuf(3,varint,opt)
}

#ControllerRevisionList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ControllerRevision] @go(Items,[]ControllerRevision) @protobuf(2,bytes,rep)
}
