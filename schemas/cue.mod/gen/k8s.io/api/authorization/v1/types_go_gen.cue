

package v1

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

#SubjectAccessReview: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #SubjectAccessReviewSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #SubjectAccessReviewStatus @go(Status) @protobuf(3,bytes,opt)
}

#SelfSubjectAccessReview: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #SelfSubjectAccessReviewSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #SubjectAccessReviewStatus @go(Status) @protobuf(3,bytes,opt)
}

#LocalSubjectAccessReview: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #SubjectAccessReviewSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #SubjectAccessReviewStatus @go(Status) @protobuf(3,bytes,opt)
}

#ResourceAttributes: {
	namespace?: string @go(Namespace) @protobuf(1,bytes,opt)

	verb?: string @go(Verb) @protobuf(2,bytes,opt)

	group?: string @go(Group) @protobuf(3,bytes,opt)

	version?: string @go(Version) @protobuf(4,bytes,opt)

	resource?: string @go(Resource) @protobuf(5,bytes,opt)

	subresource?: string @go(Subresource) @protobuf(6,bytes,opt)

	name?: string @go(Name) @protobuf(7,bytes,opt)

	fieldSelector?: #FieldSelectorAttributes @go(FieldSelector,*FieldSelectorAttributes) @protobuf(8,bytes,opt)

	labelSelector?: #LabelSelectorAttributes @go(LabelSelector,*LabelSelectorAttributes) @protobuf(9,bytes,opt)
}

#LabelSelectorAttributes: {
	rawSelector?: string @go(RawSelector) @protobuf(1,bytes,opt)

	requirements?: [...metav1.#LabelSelectorRequirement] @go(Requirements,[]metav1.LabelSelectorRequirement) @protobuf(2,bytes,rep)
}

#FieldSelectorAttributes: {
	rawSelector?: string @go(RawSelector) @protobuf(1,bytes,opt)

	requirements?: [...metav1.#FieldSelectorRequirement] @go(Requirements,[]metav1.FieldSelectorRequirement) @protobuf(2,bytes,rep)
}

#NonResourceAttributes: {
	path?: string @go(Path) @protobuf(1,bytes,opt)

	verb?: string @go(Verb) @protobuf(2,bytes,opt)
}

#SubjectAccessReviewSpec: {
	resourceAttributes?: #ResourceAttributes @go(ResourceAttributes,*ResourceAttributes) @protobuf(1,bytes,opt)

	nonResourceAttributes?: #NonResourceAttributes @go(NonResourceAttributes,*NonResourceAttributes) @protobuf(2,bytes,opt)

	user?: string @go(User) @protobuf(3,bytes,opt)

	groups?: [...string] @go(Groups,[]string) @protobuf(4,bytes,rep)

	extra?: {[string]: #ExtraValue} @go(Extra,map[string]ExtraValue) @protobuf(5,bytes,rep)

	uid?: string @go(UID) @protobuf(6,bytes,opt)
}

#ExtraValue: [...string]

#SelfSubjectAccessReviewSpec: {
	resourceAttributes?: #ResourceAttributes @go(ResourceAttributes,*ResourceAttributes) @protobuf(1,bytes,opt)

	nonResourceAttributes?: #NonResourceAttributes @go(NonResourceAttributes,*NonResourceAttributes) @protobuf(2,bytes,opt)
}

#SubjectAccessReviewStatus: {
	allowed: bool @go(Allowed) @protobuf(1,varint,opt)

	denied?: bool @go(Denied) @protobuf(4,varint,opt)

	reason?: string @go(Reason) @protobuf(2,bytes,opt)

	evaluationError?: string @go(EvaluationError) @protobuf(3,bytes,opt)
}

#SelfSubjectRulesReview: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #SelfSubjectRulesReviewSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #SubjectRulesReviewStatus @go(Status) @protobuf(3,bytes,opt)
}

#SelfSubjectRulesReviewSpec: {
	namespace?: string @go(Namespace) @protobuf(1,bytes,opt)
}

#SubjectRulesReviewStatus: {
	resourceRules: [...#ResourceRule] @go(ResourceRules,[]ResourceRule) @protobuf(1,bytes,rep)

	nonResourceRules: [...#NonResourceRule] @go(NonResourceRules,[]NonResourceRule) @protobuf(2,bytes,rep)

	incomplete: bool @go(Incomplete) @protobuf(3,bytes,rep)

	evaluationError?: string @go(EvaluationError) @protobuf(4,bytes,opt)
}

#ResourceRule: {
	verbs: [...string] @go(Verbs,[]string) @protobuf(1,bytes,rep)

	apiGroups?: [...string] @go(APIGroups,[]string) @protobuf(2,bytes,rep)

	resources?: [...string] @go(Resources,[]string) @protobuf(3,bytes,rep)

	resourceNames?: [...string] @go(ResourceNames,[]string) @protobuf(4,bytes,rep)
}

#NonResourceRule: {
	verbs: [...string] @go(Verbs,[]string) @protobuf(1,bytes,rep)

	nonResourceURLs?: [...string] @go(NonResourceURLs,[]string) @protobuf(2,bytes,rep)
}
