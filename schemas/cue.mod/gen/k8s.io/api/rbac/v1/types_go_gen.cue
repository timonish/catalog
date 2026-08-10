

package v1

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

#APIGroupAll:        "*"
#ResourceAll:        "*"
#VerbAll:            "*"
#NonResourceAll:     "*"
#GroupKind:          "Group"
#ServiceAccountKind: "ServiceAccount"
#UserKind:           "User"

#AutoUpdateAnnotationKey: "rbac.authorization.kubernetes.io/autoupdate"

#PolicyRule: {
	verbs: [...string] @go(Verbs,[]string) @protobuf(1,bytes,rep)

	apiGroups?: [...string] @go(APIGroups,[]string) @protobuf(2,bytes,rep)

	resources?: [...string] @go(Resources,[]string) @protobuf(3,bytes,rep)

	resourceNames?: [...string] @go(ResourceNames,[]string) @protobuf(4,bytes,rep)

	nonResourceURLs?: [...string] @go(NonResourceURLs,[]string) @protobuf(5,bytes,rep)
}

#Subject: {
	kind: string @go(Kind) @protobuf(1,bytes,opt)

	apiGroup?: string @go(APIGroup) @protobuf(2,bytes,opt)

	name: string @go(Name) @protobuf(3,bytes,opt)

	namespace?: string @go(Namespace) @protobuf(4,bytes,opt)
}

#RoleRef: {
	apiGroup?: string @go(APIGroup) @protobuf(1,bytes,opt)

	kind: string @go(Kind) @protobuf(2,bytes,opt)

	name: string @go(Name) @protobuf(3,bytes,opt)
}

#Role: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	rules?: [...#PolicyRule] @go(Rules,[]PolicyRule) @protobuf(2,bytes,rep)
}

#RoleBinding: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	subjects?: [...#Subject] @go(Subjects,[]Subject) @protobuf(2,bytes,rep)

	roleRef: #RoleRef @go(RoleRef) @protobuf(3,bytes,opt)
}

#RoleBindingList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#RoleBinding] @go(Items,[]RoleBinding) @protobuf(2,bytes,rep)
}

#RoleList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Role] @go(Items,[]Role) @protobuf(2,bytes,rep)
}

#ClusterRole: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	rules?: [...#PolicyRule] @go(Rules,[]PolicyRule) @protobuf(2,bytes,rep)

	aggregationRule?: #AggregationRule @go(AggregationRule,*AggregationRule) @protobuf(3,bytes,opt)
}

#AggregationRule: {
	clusterRoleSelectors?: [...metav1.#LabelSelector] @go(ClusterRoleSelectors,[]metav1.LabelSelector) @protobuf(1,bytes,rep)
}

#ClusterRoleBinding: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	subjects?: [...#Subject] @go(Subjects,[]Subject) @protobuf(2,bytes,rep)

	roleRef: #RoleRef @go(RoleRef) @protobuf(3,bytes,opt)
}

#ClusterRoleBindingList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ClusterRoleBinding] @go(Items,[]ClusterRoleBinding) @protobuf(2,bytes,rep)
}

#ClusterRoleList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ClusterRole] @go(Items,[]ClusterRole) @protobuf(2,bytes,rep)
}
