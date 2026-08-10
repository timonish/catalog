

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/types"
)

_#labelPrefix: "batch.kubernetes.io/"

#CronJobScheduledTimestampAnnotation: "batch.kubernetes.io/cronjob-scheduled-timestamp"
#JobCompletionIndexAnnotation:        "batch.kubernetes.io/job-completion-index"

#JobTrackingFinalizer: "batch.kubernetes.io/job-tracking"

#JobNameLabel: "batch.kubernetes.io/job-name"

#ControllerUidLabel: "batch.kubernetes.io/controller-uid"

#JobIndexFailureCountAnnotation: "batch.kubernetes.io/job-index-failure-count"

#JobIndexIgnoredFailureCountAnnotation: "batch.kubernetes.io/job-index-ignored-failure-count"

#JobControllerName: "kubernetes.io/job-controller"

#Job: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #JobSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #JobStatus @go(Status) @protobuf(3,bytes,opt)
}

#JobList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Job] @go(Items,[]Job) @protobuf(2,bytes,rep)
}

#CompletionMode: string // #enumCompletionMode

#enumCompletionMode:
	#NonIndexedCompletion |
	#IndexedCompletion

#NonIndexedCompletion: #CompletionMode & "NonIndexed"

#IndexedCompletion: #CompletionMode & "Indexed"

#PodFailurePolicyAction: string // #enumPodFailurePolicyAction

#enumPodFailurePolicyAction:
	#PodFailurePolicyActionFailJob |
	#PodFailurePolicyActionFailIndex |
	#PodFailurePolicyActionIgnore |
	#PodFailurePolicyActionCount

#PodFailurePolicyActionFailJob: #PodFailurePolicyAction & "FailJob"

#PodFailurePolicyActionFailIndex: #PodFailurePolicyAction & "FailIndex"

#PodFailurePolicyActionIgnore: #PodFailurePolicyAction & "Ignore"

#PodFailurePolicyActionCount: #PodFailurePolicyAction & "Count"

#PodFailurePolicyOnExitCodesOperator: string // #enumPodFailurePolicyOnExitCodesOperator

#enumPodFailurePolicyOnExitCodesOperator:
	#PodFailurePolicyOnExitCodesOpIn |
	#PodFailurePolicyOnExitCodesOpNotIn

#PodFailurePolicyOnExitCodesOpIn:    #PodFailurePolicyOnExitCodesOperator & "In"
#PodFailurePolicyOnExitCodesOpNotIn: #PodFailurePolicyOnExitCodesOperator & "NotIn"

#PodReplacementPolicy: string // #enumPodReplacementPolicy

#enumPodReplacementPolicy:
	#TerminatingOrFailed |
	#Failed

#TerminatingOrFailed: #PodReplacementPolicy & "TerminatingOrFailed"

#Failed: #PodReplacementPolicy & "Failed"

#PodFailurePolicyOnExitCodesRequirement: {
	containerName?: string @go(ContainerName,*string) @protobuf(1,bytes,opt)

	operator: #PodFailurePolicyOnExitCodesOperator @go(Operator) @protobuf(2,bytes,req)

	values: [...int32] @go(Values,[]int32) @protobuf(3,varint,rep)
}

#PodFailurePolicyOnPodConditionsPattern: {
	type: corev1.#PodConditionType @go(Type) @protobuf(1,bytes,req)

	status?: corev1.#ConditionStatus @go(Status) @protobuf(2,bytes,req)
}

#PodFailurePolicyRule: {
	action: #PodFailurePolicyAction @go(Action) @protobuf(1,bytes,req)

	onExitCodes?: #PodFailurePolicyOnExitCodesRequirement @go(OnExitCodes,*PodFailurePolicyOnExitCodesRequirement) @protobuf(2,bytes,opt)

	onPodConditions?: [...#PodFailurePolicyOnPodConditionsPattern] @go(OnPodConditions,[]PodFailurePolicyOnPodConditionsPattern) @protobuf(3,bytes,opt)
}

#PodFailurePolicy: {
	rules: [...#PodFailurePolicyRule] @go(Rules,[]PodFailurePolicyRule) @protobuf(1,bytes,opt)
}

#SuccessPolicy: {
	rules: [...#SuccessPolicyRule] @go(Rules,[]SuccessPolicyRule) @protobuf(1,bytes,opt)
}

#SuccessPolicyRule: {
	succeededIndexes?: string @go(SucceededIndexes,*string) @protobuf(1,bytes,opt)

	succeededCount?: int32 @go(SucceededCount,*int32) @protobuf(2,varint,opt)
}

#JobSpec: {
	parallelism?: int32 @go(Parallelism,*int32) @protobuf(1,varint,opt)

	completions?: int32 @go(Completions,*int32) @protobuf(2,varint,opt)

	activeDeadlineSeconds?: int64 @go(ActiveDeadlineSeconds,*int64) @protobuf(3,varint,opt)

	podFailurePolicy?: #PodFailurePolicy @go(PodFailurePolicy,*PodFailurePolicy) @protobuf(11,bytes,opt)

	successPolicy?: #SuccessPolicy @go(SuccessPolicy,*SuccessPolicy) @protobuf(16,bytes,opt)

	backoffLimit?: int32 @go(BackoffLimit,*int32) @protobuf(7,varint,opt)

	backoffLimitPerIndex?: int32 @go(BackoffLimitPerIndex,*int32) @protobuf(12,varint,opt)

	maxFailedIndexes?: int32 @go(MaxFailedIndexes,*int32) @protobuf(13,varint,opt)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(4,bytes,opt)

	manualSelector?: bool @go(ManualSelector,*bool) @protobuf(5,varint,opt)

	template: corev1.#PodTemplateSpec @go(Template) @protobuf(6,bytes,opt)

	ttlSecondsAfterFinished?: int32 @go(TTLSecondsAfterFinished,*int32) @protobuf(8,varint,opt)

	completionMode?: #CompletionMode @go(CompletionMode,*CompletionMode) @protobuf(9,bytes,opt,casttype=CompletionMode)

	suspend?: bool @go(Suspend,*bool) @protobuf(10,varint,opt)

	podReplacementPolicy?: #PodReplacementPolicy @go(PodReplacementPolicy,*PodReplacementPolicy) @protobuf(14,bytes,opt,casttype=podReplacementPolicy)

	managedBy?: string @go(ManagedBy,*string) @protobuf(15,bytes,opt)
}

#JobStatus: {
	conditions?: [...#JobCondition] @go(Conditions,[]JobCondition) @protobuf(1,bytes,rep)

	startTime?: metav1.#Time @go(StartTime,*metav1.Time) @protobuf(2,bytes,opt)

	completionTime?: metav1.#Time @go(CompletionTime,*metav1.Time) @protobuf(3,bytes,opt)

	active?: int32 @go(Active) @protobuf(4,varint,opt)

	succeeded?: int32 @go(Succeeded) @protobuf(5,varint,opt)

	failed?: int32 @go(Failed) @protobuf(6,varint,opt)

	terminating?: int32 @go(Terminating,*int32) @protobuf(11,varint,opt)

	completedIndexes?: string @go(CompletedIndexes) @protobuf(7,bytes,opt)

	failedIndexes?: string @go(FailedIndexes,*string) @protobuf(10,bytes,opt)

	uncountedTerminatedPods?: #UncountedTerminatedPods @go(UncountedTerminatedPods,*UncountedTerminatedPods) @protobuf(8,bytes,opt)

	ready?: int32 @go(Ready,*int32) @protobuf(9,varint,opt)
}

#UncountedTerminatedPods: {
	succeeded?: [...types.#UID] @go(Succeeded,[]types.UID) @protobuf(1,bytes,rep,casttype=k8s.io/apimachinery/pkg/types.UID)

	failed?: [...types.#UID] @go(Failed,[]types.UID) @protobuf(2,bytes,rep,casttype=k8s.io/apimachinery/pkg/types.UID)
}

#JobConditionType: string // #enumJobConditionType

#enumJobConditionType:
	#JobSuspended |
	#JobComplete |
	#JobFailed |
	#JobFailureTarget |
	#JobSuccessCriteriaMet

#JobSuspended: #JobConditionType & "Suspended"

#JobComplete: #JobConditionType & "Complete"

#JobFailed: #JobConditionType & "Failed"

#JobFailureTarget: #JobConditionType & "FailureTarget"

#JobSuccessCriteriaMet: #JobConditionType & "SuccessCriteriaMet"

#JobReasonPodFailurePolicy: "PodFailurePolicy"

#JobReasonBackoffLimitExceeded: "BackoffLimitExceeded"

#JobReasonDeadlineExceeded: "DeadlineExceeded"

#JobReasonMaxFailedIndexesExceeded: "MaxFailedIndexesExceeded"

#JobReasonFailedIndexes: "FailedIndexes"

#JobReasonSuccessPolicy: "SuccessPolicy"

#JobReasonCompletionsReached: "CompletionsReached"

#JobCondition: {
	type: #JobConditionType @go(Type) @protobuf(1,bytes,opt,casttype=JobConditionType)

	status: corev1.#ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=k8s.io/api/core/v1.ConditionStatus)

	lastProbeTime?: metav1.#Time @go(LastProbeTime) @protobuf(3,bytes,opt)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(4,bytes,opt)

	reason?: string @go(Reason) @protobuf(5,bytes,opt)

	message?: string @go(Message) @protobuf(6,bytes,opt)
}

#JobTemplateSpec: {
	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #JobSpec @go(Spec) @protobuf(2,bytes,opt)
}

#CronJob: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #CronJobSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #CronJobStatus @go(Status) @protobuf(3,bytes,opt)
}

#CronJobList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#CronJob] @go(Items,[]CronJob) @protobuf(2,bytes,rep)
}

#CronJobSpec: {
	schedule: string @go(Schedule) @protobuf(1,bytes,opt)

	timeZone?: string @go(TimeZone,*string) @protobuf(8,bytes,opt)

	startingDeadlineSeconds?: int64 @go(StartingDeadlineSeconds,*int64) @protobuf(2,varint,opt)

	concurrencyPolicy?: #ConcurrencyPolicy @go(ConcurrencyPolicy) @protobuf(3,bytes,opt,casttype=ConcurrencyPolicy)

	suspend?: bool @go(Suspend,*bool) @protobuf(4,varint,opt)

	jobTemplate: #JobTemplateSpec @go(JobTemplate) @protobuf(5,bytes,opt)

	successfulJobsHistoryLimit?: int32 @go(SuccessfulJobsHistoryLimit,*int32) @protobuf(6,varint,opt)

	failedJobsHistoryLimit?: int32 @go(FailedJobsHistoryLimit,*int32) @protobuf(7,varint,opt)
}

#ConcurrencyPolicy: string // #enumConcurrencyPolicy

#enumConcurrencyPolicy:
	#AllowConcurrent |
	#ForbidConcurrent |
	#ReplaceConcurrent

#AllowConcurrent: #ConcurrencyPolicy & "Allow"

#ForbidConcurrent: #ConcurrencyPolicy & "Forbid"

#ReplaceConcurrent: #ConcurrencyPolicy & "Replace"

#CronJobStatus: {
	active?: [...corev1.#ObjectReference] @go(Active,[]corev1.ObjectReference) @protobuf(1,bytes,rep)

	lastScheduleTime?: metav1.#Time @go(LastScheduleTime,*metav1.Time) @protobuf(4,bytes,opt)

	lastSuccessfulTime?: metav1.#Time @go(LastSuccessfulTime,*metav1.Time) @protobuf(5,bytes,opt)
}
