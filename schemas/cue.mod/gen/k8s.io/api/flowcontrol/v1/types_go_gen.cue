

package v1

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

#APIGroupAll:    "*"
#ResourceAll:    "*"
#VerbAll:        "*"
#NonResourceAll: "*"
#NameAll:        "*"
#NamespaceEvery: "*"

#PriorityLevelConfigurationNameExempt:   "exempt"
#PriorityLevelConfigurationNameCatchAll: "catch-all"
#FlowSchemaNameExempt:                   "exempt"
#FlowSchemaNameCatchAll:                 "catch-all"

#FlowSchemaConditionDangling:                          "Dangling"
#PriorityLevelConfigurationConditionConcurrencyShared: "ConcurrencyShared"

#FlowSchemaMaxMatchingPrecedence: int32 & 10000

#ResponseHeaderMatchedPriorityLevelConfigurationUID: "X-Kubernetes-PF-PriorityLevel-UID"
#ResponseHeaderMatchedFlowSchemaUID:                 "X-Kubernetes-PF-FlowSchema-UID"

#AutoUpdateAnnotationKey: "apf.kubernetes.io/autoupdate-spec"

#FlowSchema: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #FlowSchemaSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #FlowSchemaStatus @go(Status) @protobuf(3,bytes,opt)
}

#FlowSchemaList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#FlowSchema] @go(Items,[]FlowSchema) @protobuf(2,bytes,rep)
}

#FlowSchemaSpec: {
	priorityLevelConfiguration: #PriorityLevelConfigurationReference @go(PriorityLevelConfiguration) @protobuf(1,bytes,opt)

	matchingPrecedence?: int32 @go(MatchingPrecedence) @protobuf(2,varint,opt)

	distinguisherMethod?: #FlowDistinguisherMethod @go(DistinguisherMethod,*FlowDistinguisherMethod) @protobuf(3,bytes,opt)

	rules?: [...#PolicyRulesWithSubjects] @go(Rules,[]PolicyRulesWithSubjects) @protobuf(4,bytes,rep)
}

#FlowDistinguisherMethodType: string // #enumFlowDistinguisherMethodType

#enumFlowDistinguisherMethodType:
	#FlowDistinguisherMethodByUserType |
	#FlowDistinguisherMethodByNamespaceType

#FlowDistinguisherMethodByUserType: #FlowDistinguisherMethodType & "ByUser"

#FlowDistinguisherMethodByNamespaceType: #FlowDistinguisherMethodType & "ByNamespace"

#FlowDistinguisherMethod: {
	type: #FlowDistinguisherMethodType @go(Type) @protobuf(1,bytes,opt)
}

#PriorityLevelConfigurationReference: {
	name: string @go(Name) @protobuf(1,bytes,opt)
}

#PolicyRulesWithSubjects: {
	subjects: [...#Subject] @go(Subjects,[]Subject) @protobuf(1,bytes,rep)

	resourceRules?: [...#ResourcePolicyRule] @go(ResourceRules,[]ResourcePolicyRule) @protobuf(2,bytes,opt)

	nonResourceRules?: [...#NonResourcePolicyRule] @go(NonResourceRules,[]NonResourcePolicyRule) @protobuf(3,bytes,opt)
}

#Subject: {
	kind: #SubjectKind @go(Kind) @protobuf(1,bytes,opt)

	user?: #UserSubject @go(User,*UserSubject) @protobuf(2,bytes,opt)

	group?: #GroupSubject @go(Group,*GroupSubject) @protobuf(3,bytes,opt)

	serviceAccount?: #ServiceAccountSubject @go(ServiceAccount,*ServiceAccountSubject) @protobuf(4,bytes,opt)
}

#SubjectKind: string // #enumSubjectKind

#enumSubjectKind:
	#SubjectKindUser |
	#SubjectKindGroup |
	#SubjectKindServiceAccount

#SubjectKindUser:           #SubjectKind & "User"
#SubjectKindGroup:          #SubjectKind & "Group"
#SubjectKindServiceAccount: #SubjectKind & "ServiceAccount"

#UserSubject: {
	name: string @go(Name) @protobuf(1,bytes,opt)
}

#GroupSubject: {
	name: string @go(Name) @protobuf(1,bytes,opt)
}

#ServiceAccountSubject: {
	namespace: string @go(Namespace) @protobuf(1,bytes,opt)

	name: string @go(Name) @protobuf(2,bytes,opt)
}

#ResourcePolicyRule: {
	verbs: [...string] @go(Verbs,[]string) @protobuf(1,bytes,rep)

	apiGroups: [...string] @go(APIGroups,[]string) @protobuf(2,bytes,rep)

	resources: [...string] @go(Resources,[]string) @protobuf(3,bytes,rep)

	clusterScope?: bool @go(ClusterScope) @protobuf(4,varint,opt)

	namespaces?: [...string] @go(Namespaces,[]string) @protobuf(5,bytes,rep)
}

#NonResourcePolicyRule: {
	verbs: [...string] @go(Verbs,[]string) @protobuf(1,bytes,rep)

	nonResourceURLs: [...string] @go(NonResourceURLs,[]string) @protobuf(6,bytes,rep)
}

#FlowSchemaStatus: {
	conditions?: [...#FlowSchemaCondition] @go(Conditions,[]FlowSchemaCondition) @protobuf(1,bytes,rep)
}

#FlowSchemaCondition: {
	type?: #FlowSchemaConditionType @go(Type) @protobuf(1,bytes,opt)

	status?: #ConditionStatus @go(Status) @protobuf(2,bytes,opt)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(3,bytes,opt)

	reason?: string @go(Reason) @protobuf(4,bytes,opt)

	message?: string @go(Message) @protobuf(5,bytes,opt)
}

#FlowSchemaConditionType: string

#PriorityLevelConfiguration: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #PriorityLevelConfigurationSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #PriorityLevelConfigurationStatus @go(Status) @protobuf(3,bytes,opt)
}

#PriorityLevelConfigurationList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#PriorityLevelConfiguration] @go(Items,[]PriorityLevelConfiguration) @protobuf(2,bytes,rep)
}

#PriorityLevelConfigurationSpec: {
	type: #PriorityLevelEnablement @go(Type) @protobuf(1,bytes,opt)

	limited?: #LimitedPriorityLevelConfiguration @go(Limited,*LimitedPriorityLevelConfiguration) @protobuf(2,bytes,opt)

	exempt?: #ExemptPriorityLevelConfiguration @go(Exempt,*ExemptPriorityLevelConfiguration) @protobuf(3,bytes,opt)
}

#PriorityLevelEnablement: string // #enumPriorityLevelEnablement

#enumPriorityLevelEnablement:
	#PriorityLevelEnablementExempt |
	#PriorityLevelEnablementLimited

#PriorityLevelEnablementExempt: #PriorityLevelEnablement & "Exempt"

#PriorityLevelEnablementLimited: #PriorityLevelEnablement & "Limited"

#LimitedPriorityLevelConfiguration: {
	nominalConcurrencyShares?: int32 @go(NominalConcurrencyShares,*int32) @protobuf(1,varint,opt)

	limitResponse?: #LimitResponse @go(LimitResponse) @protobuf(2,bytes,opt)

	lendablePercent?: int32 @go(LendablePercent,*int32) @protobuf(3,varint,opt)

	borrowingLimitPercent?: int32 @go(BorrowingLimitPercent,*int32) @protobuf(4,varint,opt)
}

#ExemptPriorityLevelConfiguration: {
	nominalConcurrencyShares?: int32 @go(NominalConcurrencyShares,*int32) @protobuf(1,varint,opt)

	lendablePercent?: int32 @go(LendablePercent,*int32) @protobuf(2,varint,opt)
}

#LimitResponse: {
	type: #LimitResponseType @go(Type) @protobuf(1,bytes,opt)

	queuing?: #QueuingConfiguration @go(Queuing,*QueuingConfiguration) @protobuf(2,bytes,opt)
}

#LimitResponseType: string // #enumLimitResponseType

#enumLimitResponseType:
	#LimitResponseTypeQueue |
	#LimitResponseTypeReject

#LimitResponseTypeQueue: #LimitResponseType & "Queue"

#LimitResponseTypeReject: #LimitResponseType & "Reject"

#QueuingConfiguration: {
	queues?: int32 @go(Queues) @protobuf(1,varint,opt)

	handSize?: int32 @go(HandSize) @protobuf(2,varint,opt)

	queueLengthLimit?: int32 @go(QueueLengthLimit) @protobuf(3,varint,opt)
}

#PriorityLevelConfigurationConditionType: string

#PriorityLevelConfigurationStatus: {
	conditions?: [...#PriorityLevelConfigurationCondition] @go(Conditions,[]PriorityLevelConfigurationCondition) @protobuf(1,bytes,rep)
}

#PriorityLevelConfigurationCondition: {
	type?: #PriorityLevelConfigurationConditionType @go(Type) @protobuf(1,bytes,opt)

	status?: #ConditionStatus @go(Status) @protobuf(2,bytes,opt)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(3,bytes,opt)

	reason?: string @go(Reason) @protobuf(4,bytes,opt)

	message?: string @go(Message) @protobuf(5,bytes,opt)
}

#ConditionStatus: string // #enumConditionStatus

#enumConditionStatus:
	#ConditionTrue |
	#ConditionFalse |
	#ConditionUnknown

#ConditionTrue:    #ConditionStatus & "True"
#ConditionFalse:   #ConditionStatus & "False"
#ConditionUnknown: #ConditionStatus & "Unknown"
