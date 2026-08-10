

package v1

import (
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/runtime"
)

#TypeMeta: {
	kind?: string @go(Kind) @protobuf(1,bytes,opt)

	apiVersion?: string @go(APIVersion) @protobuf(2,bytes,opt)
}

#ListMeta: {
	selfLink?: string @go(SelfLink) @protobuf(1,bytes,opt)

	resourceVersion?: string @go(ResourceVersion) @protobuf(2,bytes,opt)

	continue?: string @go(Continue) @protobuf(3,bytes,opt)

	remainingItemCount?: int64 @go(RemainingItemCount,*int64) @protobuf(4,bytes,opt)

	shardInfo?: #ShardInfo @go(ShardInfo,*ShardInfo) @protobuf(5,bytes,opt)
}

#ShardInfo: {
	selector: string @go(Selector) @protobuf(1,bytes,opt)
}

#ObjectNameField: "metadata.name"

#FinalizerOrphanDependents: "orphan"
#FinalizerDeleteDependents: "foregroundDeletion"

#ObjectMeta: {
	name?: string @go(Name) @protobuf(1,bytes,opt)

	generateName?: string @go(GenerateName) @protobuf(2,bytes,opt)

	namespace?: string @go(Namespace) @protobuf(3,bytes,opt)

	selfLink?: string @go(SelfLink) @protobuf(4,bytes,opt)

	uid?: types.#UID @go(UID) @protobuf(5,bytes,opt,casttype=k8s.io/kubernetes/pkg/types.UID)

	resourceVersion?: string @go(ResourceVersion) @protobuf(6,bytes,opt)

	generation?: int64 @go(Generation) @protobuf(7,varint,opt)

	creationTimestamp?: #Time @go(CreationTimestamp) @protobuf(8,bytes,opt)

	deletionTimestamp?: #Time @go(DeletionTimestamp,*Time) @protobuf(9,bytes,opt)

	deletionGracePeriodSeconds?: int64 @go(DeletionGracePeriodSeconds,*int64) @protobuf(10,varint,opt)

	labels?: {[string]: string} @go(Labels,map[string]string) @protobuf(11,bytes,rep)

	annotations?: {[string]: string} @go(Annotations,map[string]string) @protobuf(12,bytes,rep)

	ownerReferences?: [...#OwnerReference] @go(OwnerReferences,[]OwnerReference) @protobuf(13,bytes,rep)

	finalizers?: [...string] @go(Finalizers,[]string) @protobuf(14,bytes,rep)

	managedFields?: [...#ManagedFieldsEntry] @go(ManagedFields,[]ManagedFieldsEntry) @protobuf(17,bytes,rep)
}

#NamespaceDefault: "default"

#NamespaceAll: ""

#NamespaceNone: ""

#NamespaceSystem: "kube-system"

#NamespacePublic: "kube-public"

#OwnerReference: {
	apiVersion: string @go(APIVersion) @protobuf(5,bytes,opt)

	kind: string @go(Kind) @protobuf(1,bytes,opt)

	name: string @go(Name) @protobuf(3,bytes,opt)

	uid: types.#UID @go(UID) @protobuf(4,bytes,opt,casttype=k8s.io/apimachinery/pkg/types.UID)

	controller?: bool @go(Controller,*bool) @protobuf(6,varint,opt)

	blockOwnerDeletion?: bool @go(BlockOwnerDeletion,*bool) @protobuf(7,varint,opt)
}

#ListOptions: {
	#TypeMeta

	labelSelector?: string @go(LabelSelector) @protobuf(1,bytes,opt)

	fieldSelector?: string @go(FieldSelector) @protobuf(2,bytes,opt)

	watch?: bool @go(Watch) @protobuf(3,varint,opt)

	allowWatchBookmarks?: bool @go(AllowWatchBookmarks) @protobuf(9,varint,opt)

	resourceVersion?: string @go(ResourceVersion) @protobuf(4,bytes,opt)

	resourceVersionMatch?: #ResourceVersionMatch @go(ResourceVersionMatch) @protobuf(10,bytes,opt,casttype=ResourceVersionMatch)

	timeoutSeconds?: int64 @go(TimeoutSeconds,*int64) @protobuf(5,varint,opt)

	limit?: int64 @go(Limit) @protobuf(7,varint,opt)

	continue?: string @go(Continue) @protobuf(8,bytes,opt)

	sendInitialEvents?: bool @go(SendInitialEvents,*bool) @protobuf(11,varint,opt)

	shardSelector?: string @go(ShardSelector) @protobuf(15,bytes,opt)
}

#InitialEventsAnnotationKey: "k8s.io/initial-events-end"

#ResourceVersionMatch: string // #enumResourceVersionMatch

#enumResourceVersionMatch:
	#ResourceVersionMatchNotOlderThan |
	#ResourceVersionMatchExact

#ResourceVersionMatchNotOlderThan: #ResourceVersionMatch & "NotOlderThan"

#ResourceVersionMatchExact: #ResourceVersionMatch & "Exact"

#GetOptions: {
	#TypeMeta

	resourceVersion?: string @go(ResourceVersion) @protobuf(1,bytes,opt)
}

#DeletionPropagation: string // #enumDeletionPropagation

#enumDeletionPropagation:
	#DeletePropagationOrphan |
	#DeletePropagationBackground |
	#DeletePropagationForeground

#DeletePropagationOrphan: #DeletionPropagation & "Orphan"

#DeletePropagationBackground: #DeletionPropagation & "Background"

#DeletePropagationForeground: #DeletionPropagation & "Foreground"

#DryRunAll: "All"

#DeleteOptions: {
	#TypeMeta

	gracePeriodSeconds?: int64 @go(GracePeriodSeconds,*int64) @protobuf(1,varint,opt)

	preconditions?: #Preconditions @go(Preconditions,*Preconditions) @protobuf(2,bytes,opt)

	orphanDependents?: bool @go(OrphanDependents,*bool) @protobuf(3,varint,opt)

	propagationPolicy?: #DeletionPropagation @go(PropagationPolicy,*DeletionPropagation) @protobuf(4,varint,opt)

	dryRun?: [...string] @go(DryRun,[]string) @protobuf(5,bytes,rep)

	ignoreStoreReadErrorWithClusterBreakingPotential?: bool @go(IgnoreStoreReadErrorWithClusterBreakingPotential,*bool) @protobuf(6,varint,opt)
}

#FieldValidationIgnore: "Ignore"

#FieldValidationWarn: "Warn"

#FieldValidationStrict: "Strict"

#CreateOptions: {
	#TypeMeta

	dryRun?: [...string] @go(DryRun,[]string) @protobuf(1,bytes,rep)

	fieldManager?: string @go(FieldManager) @protobuf(3,bytes)

	fieldValidation?: string @go(FieldValidation) @protobuf(4,bytes)
}

#PatchOptions: {
	#TypeMeta

	dryRun?: [...string] @go(DryRun,[]string) @protobuf(1,bytes,rep)

	force?: bool @go(Force,*bool) @protobuf(2,varint,opt)

	fieldManager?: string @go(FieldManager) @protobuf(3,bytes)

	fieldValidation?: string @go(FieldValidation) @protobuf(4,bytes)
}

#ApplyOptions: {
	#TypeMeta

	dryRun?: [...string] @go(DryRun,[]string) @protobuf(1,bytes,rep)

	force: bool @go(Force) @protobuf(2,varint,opt)

	fieldManager: string @go(FieldManager) @protobuf(3,bytes)
}

#UpdateOptions: {
	#TypeMeta

	dryRun?: [...string] @go(DryRun,[]string) @protobuf(1,bytes,rep)

	fieldManager?: string @go(FieldManager) @protobuf(2,bytes)

	fieldValidation?: string @go(FieldValidation) @protobuf(3,bytes)
}

#Preconditions: {
	uid?: types.#UID @go(UID,*types.UID) @protobuf(1,bytes,opt,casttype=k8s.io/apimachinery/pkg/types.UID)

	resourceVersion?: string @go(ResourceVersion,*string) @protobuf(2,bytes,opt)
}

#Status: {
	#TypeMeta

	metadata?: #ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	status?: string @go(Status) @protobuf(2,bytes,opt)

	message?: string @go(Message) @protobuf(3,bytes,opt)

	reason?: #StatusReason @go(Reason) @protobuf(4,bytes,opt,casttype=StatusReason)

	details?: #StatusDetails @go(Details,*StatusDetails) @protobuf(5,bytes,opt)

	code?: int32 @go(Code) @protobuf(6,varint,opt)
}

#StatusDetails: {
	name?: string @go(Name) @protobuf(1,bytes,opt)

	group?: string @go(Group) @protobuf(2,bytes,opt)

	kind?: string @go(Kind) @protobuf(3,bytes,opt)

	uid?: types.#UID @go(UID) @protobuf(6,bytes,opt,casttype=k8s.io/apimachinery/pkg/types.UID)

	causes?: [...#StatusCause] @go(Causes,[]StatusCause) @protobuf(4,bytes,rep)

	retryAfterSeconds?: int32 @go(RetryAfterSeconds) @protobuf(5,varint,opt)
}

#StatusSuccess: "Success"
#StatusFailure: "Failure"

#StatusReason: string // #enumStatusReason

#enumStatusReason:
	#StatusReasonUnknown |
	#StatusReasonUnauthorized |
	#StatusReasonForbidden |
	#StatusReasonNotFound |
	#StatusReasonAlreadyExists |
	#StatusReasonConflict |
	#StatusReasonGone |
	#StatusReasonInvalid |
	#StatusReasonServerTimeout |
	#StatusReasonStoreReadError |
	#StatusReasonTimeout |
	#StatusReasonTooManyRequests |
	#StatusReasonBadRequest |
	#StatusReasonMethodNotAllowed |
	#StatusReasonNotAcceptable |
	#StatusReasonRequestEntityTooLarge |
	#StatusReasonUnsupportedMediaType |
	#StatusReasonInternalError |
	#StatusReasonExpired |
	#StatusReasonServiceUnavailable

#StatusReasonUnknown: #StatusReason & ""

#StatusReasonUnauthorized: #StatusReason & "Unauthorized"

#StatusReasonForbidden: #StatusReason & "Forbidden"

#StatusReasonNotFound: #StatusReason & "NotFound"

#StatusReasonAlreadyExists: #StatusReason & "AlreadyExists"

#StatusReasonConflict: #StatusReason & "Conflict"

#StatusReasonGone: #StatusReason & "Gone"

#StatusReasonInvalid: #StatusReason & "Invalid"

#StatusReasonServerTimeout: #StatusReason & "ServerTimeout"

#StatusReasonStoreReadError: #StatusReason & "StorageReadError"

#StatusReasonTimeout: #StatusReason & "Timeout"

#StatusReasonTooManyRequests: #StatusReason & "TooManyRequests"

#StatusReasonBadRequest: #StatusReason & "BadRequest"

#StatusReasonMethodNotAllowed: #StatusReason & "MethodNotAllowed"

#StatusReasonNotAcceptable: #StatusReason & "NotAcceptable"

#StatusReasonRequestEntityTooLarge: #StatusReason & "RequestEntityTooLarge"

#StatusReasonUnsupportedMediaType: #StatusReason & "UnsupportedMediaType"

#StatusReasonInternalError: #StatusReason & "InternalError"

#StatusReasonExpired: #StatusReason & "Expired"

#StatusReasonServiceUnavailable: #StatusReason & "ServiceUnavailable"

#StatusCause: {
	reason?: #CauseType @go(Type) @protobuf(1,bytes,opt,casttype=CauseType)

	message?: string @go(Message) @protobuf(2,bytes,opt)

	field?: string @go(Field) @protobuf(3,bytes,opt)
}

#CauseType: string // #enumCauseType

#enumCauseType:
	#CauseTypeFieldValueNotFound |
	#CauseTypeFieldValueRequired |
	#CauseTypeFieldValueDuplicate |
	#CauseTypeFieldValueInvalid |
	#CauseTypeFieldValueNotSupported |
	#CauseTypeForbidden |
	#CauseTypeTooLong |
	#CauseTypeTooMany |
	#CauseTypeInternal |
	#CauseTypeTypeInvalid |
	#CauseTypeUnexpectedServerResponse |
	#CauseTypeFieldManagerConflict |
	#CauseTypeResourceVersionTooLarge

#CauseTypeFieldValueNotFound: #CauseType & "FieldValueNotFound"

#CauseTypeFieldValueRequired: #CauseType & "FieldValueRequired"

#CauseTypeFieldValueDuplicate: #CauseType & "FieldValueDuplicate"

#CauseTypeFieldValueInvalid: #CauseType & "FieldValueInvalid"

#CauseTypeFieldValueNotSupported: #CauseType & "FieldValueNotSupported"

#CauseTypeForbidden: #CauseType & "FieldValueForbidden"

#CauseTypeTooLong: #CauseType & "FieldValueTooLong"

#CauseTypeTooMany: #CauseType & "FieldValueTooMany"

#CauseTypeInternal: #CauseType & "InternalError"

#CauseTypeTypeInvalid: #CauseType & "FieldValueTypeInvalid"

#CauseTypeUnexpectedServerResponse: #CauseType & "UnexpectedServerResponse"

#CauseTypeFieldManagerConflict: #CauseType & "FieldManagerConflict"

#CauseTypeResourceVersionTooLarge: #CauseType & "ResourceVersionTooLarge"

#List: {
	#TypeMeta

	metadata?: #ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...runtime.#RawExtension] @go(Items,[]runtime.RawExtension) @protobuf(2,bytes,rep)
}

#APIVersions: {
	#TypeMeta

	versions: [...string] @go(Versions,[]string) @protobuf(1,bytes,rep)

	serverAddressByClientCIDRs: [...#ServerAddressByClientCIDR] @go(ServerAddressByClientCIDRs,[]ServerAddressByClientCIDR) @protobuf(2,bytes,rep)
}

#APIGroupList: {
	#TypeMeta

	groups: [...#APIGroup] @go(Groups,[]APIGroup) @protobuf(1,bytes,rep)
}

#APIGroup: {
	#TypeMeta

	name: string @go(Name) @protobuf(1,bytes,opt)

	versions: [...#GroupVersionForDiscovery] @go(Versions,[]GroupVersionForDiscovery) @protobuf(2,bytes,rep)

	preferredVersion?: #GroupVersionForDiscovery @go(PreferredVersion) @protobuf(3,bytes,opt)

	serverAddressByClientCIDRs?: [...#ServerAddressByClientCIDR] @go(ServerAddressByClientCIDRs,[]ServerAddressByClientCIDR) @protobuf(4,bytes,rep)
}

#ServerAddressByClientCIDR: {
	clientCIDR: string @go(ClientCIDR) @protobuf(1,bytes,opt)

	serverAddress: string @go(ServerAddress) @protobuf(2,bytes,opt)
}

#GroupVersionForDiscovery: {
	groupVersion: string @go(GroupVersion) @protobuf(1,bytes,opt)

	version: string @go(Version) @protobuf(2,bytes,opt)
}

#APIResource: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	singularName: string @go(SingularName) @protobuf(6,bytes,opt)

	namespaced: bool @go(Namespaced) @protobuf(2,varint,opt)

	group?: string @go(Group) @protobuf(8,bytes,opt)

	version?: string @go(Version) @protobuf(9,bytes,opt)

	kind: string @go(Kind) @protobuf(3,bytes,opt)

	verbs: #Verbs @go(Verbs) @protobuf(4,bytes,opt)

	shortNames?: [...string] @go(ShortNames,[]string) @protobuf(5,bytes,rep)

	categories?: [...string] @go(Categories,[]string) @protobuf(7,bytes,rep)

	storageVersionHash?: string @go(StorageVersionHash) @protobuf(10,bytes,opt)
}

#Verbs: [...string]

#APIResourceList: {
	#TypeMeta

	groupVersion: string @go(GroupVersion) @protobuf(1,bytes,opt)

	resources: [...#APIResource] @go(APIResources,[]APIResource) @protobuf(2,bytes,rep)
}

#RootPaths: {
	paths: [...string] @go(Paths,[]string) @protobuf(1,bytes,rep)
}

#Patch: {}

#LabelSelector: {
	matchLabels?: {[string]: string} @go(MatchLabels,map[string]string) @protobuf(1,bytes,rep)

	matchExpressions?: [...#LabelSelectorRequirement] @go(MatchExpressions,[]LabelSelectorRequirement) @protobuf(2,bytes,rep)
}

#LabelSelectorRequirement: {
	key: string @go(Key) @protobuf(1,bytes,opt)

	operator: #LabelSelectorOperator @go(Operator) @protobuf(2,bytes,opt,casttype=LabelSelectorOperator)

	values?: [...string] @go(Values,[]string) @protobuf(3,bytes,rep)
}

#LabelSelectorOperator: string // #enumLabelSelectorOperator

#enumLabelSelectorOperator:
	#LabelSelectorOpIn |
	#LabelSelectorOpNotIn |
	#LabelSelectorOpExists |
	#LabelSelectorOpDoesNotExist

#LabelSelectorOpIn:           #LabelSelectorOperator & "In"
#LabelSelectorOpNotIn:        #LabelSelectorOperator & "NotIn"
#LabelSelectorOpExists:       #LabelSelectorOperator & "Exists"
#LabelSelectorOpDoesNotExist: #LabelSelectorOperator & "DoesNotExist"

#FieldSelectorRequirement: {
	key: string @go(Key) @protobuf(1,bytes,opt)

	operator: #FieldSelectorOperator @go(Operator) @protobuf(2,bytes,opt,casttype=FieldSelectorOperator)

	values?: [...string] @go(Values,[]string) @protobuf(3,bytes,rep)
}

#FieldSelectorOperator: string // #enumFieldSelectorOperator

#enumFieldSelectorOperator:
	#FieldSelectorOpIn |
	#FieldSelectorOpNotIn |
	#FieldSelectorOpExists |
	#FieldSelectorOpDoesNotExist

#FieldSelectorOpIn:           #FieldSelectorOperator & "In"
#FieldSelectorOpNotIn:        #FieldSelectorOperator & "NotIn"
#FieldSelectorOpExists:       #FieldSelectorOperator & "Exists"
#FieldSelectorOpDoesNotExist: #FieldSelectorOperator & "DoesNotExist"

#ManagedFieldsEntry: {
	manager?: string @go(Manager) @protobuf(1,bytes,opt)

	operation?: #ManagedFieldsOperationType @go(Operation) @protobuf(2,bytes,opt,casttype=ManagedFieldsOperationType)

	apiVersion?: string @go(APIVersion) @protobuf(3,bytes,opt)

	time?: #Time @go(Time,*Time) @protobuf(4,bytes,opt)

	fieldsType?: string @go(FieldsType) @protobuf(6,bytes,opt)

	fieldsV1?: #FieldsV1 @go(FieldsV1,*FieldsV1) @protobuf(7,bytes,opt)

	subresource?: string @go(Subresource) @protobuf(8,bytes,opt)
}

#ManagedFieldsOperationType: string // #enumManagedFieldsOperationType

#enumManagedFieldsOperationType:
	#ManagedFieldsOperationApply |
	#ManagedFieldsOperationUpdate

#ManagedFieldsOperationApply:  #ManagedFieldsOperationType & "Apply"
#ManagedFieldsOperationUpdate: #ManagedFieldsOperationType & "Update"

#Table: {
	#TypeMeta

	metadata?: #ListMeta @go(ListMeta)

	columnDefinitions: [...#TableColumnDefinition] @go(ColumnDefinitions,[]TableColumnDefinition)

	rows: [...#TableRow] @go(Rows,[]TableRow)
}

#TableColumnDefinition: {
	name: string @go(Name)

	type: string @go(Type)

	format: string @go(Format)

	description: string @go(Description)

	priority: int32 @go(Priority)
}

#TableRow: {
	cells: [...] @go(Cells,[]interface{})

	conditions?: [...#TableRowCondition] @go(Conditions,[]TableRowCondition)

	object?: runtime.#RawExtension @go(Object)
}

#TableRowCondition: {
	type: #RowConditionType @go(Type)

	status: #ConditionStatus @go(Status)

	reason?: string @go(Reason)

	message?: string @go(Message)
}

#RowConditionType: string // #enumRowConditionType

#enumRowConditionType:
	#RowCompleted

#RowCompleted: #RowConditionType & "Completed"

#ConditionStatus: string // #enumConditionStatus

#enumConditionStatus:
	#ConditionTrue |
	#ConditionFalse |
	#ConditionUnknown

#ConditionTrue:    #ConditionStatus & "True"
#ConditionFalse:   #ConditionStatus & "False"
#ConditionUnknown: #ConditionStatus & "Unknown"

#IncludeObjectPolicy: string // #enumIncludeObjectPolicy

#enumIncludeObjectPolicy:
	#IncludeNone |
	#IncludeMetadata |
	#IncludeObject

#IncludeNone: #IncludeObjectPolicy & "None"

#IncludeMetadata: #IncludeObjectPolicy & "Metadata"

#IncludeObject: #IncludeObjectPolicy & "Object"

#TableOptions: {
	#TypeMeta

	includeObject?: #IncludeObjectPolicy @go(IncludeObject) @protobuf(1,bytes,opt,casttype=IncludeObjectPolicy)
}

#PartialObjectMetadata: {
	#TypeMeta

	metadata?: #ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)
}

#PartialObjectMetadataList: {
	#TypeMeta

	metadata?: #ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#PartialObjectMetadata] @go(Items,[]PartialObjectMetadata) @protobuf(2,bytes,rep)
}

#Condition: {
	type: string @go(Type) @protobuf(1,bytes,opt)

	status: #ConditionStatus @go(Status) @protobuf(2,bytes,opt)

	observedGeneration?: int64 @go(ObservedGeneration) @protobuf(3,varint,opt)

	lastTransitionTime: #Time @go(LastTransitionTime) @protobuf(4,bytes,opt)

	reason: string @go(Reason) @protobuf(5,bytes,opt)

	message: string @go(Message) @protobuf(6,bytes,opt)
}
