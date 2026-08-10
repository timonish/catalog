

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
)

#ImpersonateUserHeader: "Impersonate-User"

#ImpersonateGroupHeader: "Impersonate-Group"

#ImpersonateUIDHeader: "Impersonate-Uid"

#ImpersonateUserExtraHeaderPrefix: "Impersonate-Extra-"

#TokenReview: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #TokenReviewSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #TokenReviewStatus @go(Status) @protobuf(3,bytes,opt)
}

#TokenReviewSpec: {
	token: string @go(Token) @protobuf(1,bytes,opt)

	audiences?: [...string] @go(Audiences,[]string) @protobuf(2,bytes,rep)
}

#TokenReviewStatus: {
	authenticated?: bool @go(Authenticated) @protobuf(1,varint,opt)

	user?: #UserInfo @go(User) @protobuf(2,bytes,opt)

	audiences?: [...string] @go(Audiences,[]string) @protobuf(4,bytes,rep)

	error?: string @go(Error) @protobuf(3,bytes,opt)
}

#UserInfo: {
	username?: string @go(Username) @protobuf(1,bytes,opt)

	uid?: string @go(UID) @protobuf(2,bytes,opt)

	groups?: [...string] @go(Groups,[]string) @protobuf(3,bytes,rep)

	extra?: {[string]: #ExtraValue} @go(Extra,map[string]ExtraValue) @protobuf(4,bytes,rep)
}

#ExtraValue: [...string]

#TokenRequest: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #TokenRequestSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #TokenRequestStatus @go(Status) @protobuf(3,bytes,opt)
}

#TokenRequestSpec: {
	audiences?: [...string] @go(Audiences,[]string) @protobuf(1,bytes,rep)

	expirationSeconds?: int64 @go(ExpirationSeconds,*int64) @protobuf(4,varint,opt)

	boundObjectRef?: #BoundObjectReference @go(BoundObjectRef,*BoundObjectReference) @protobuf(3,bytes,opt)
}

#TokenRequestStatus: {
	token?: string @go(Token) @protobuf(1,bytes,opt)

	expirationTimestamp?: metav1.#Time @go(ExpirationTimestamp) @protobuf(2,bytes,opt)
}

#BoundObjectReference: {
	kind?: string @go(Kind) @protobuf(1,bytes,opt)

	apiVersion?: string @go(APIVersion) @protobuf(2,bytes,opt)

	name?: string @go(Name) @protobuf(3,bytes,opt)

	uid?: types.#UID @go(UID) @protobuf(4,bytes,opt,name=uID,casttype=k8s.io/apimachinery/pkg/types.UID)
}

#SelfSubjectReview: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	status?: #SelfSubjectReviewStatus @go(Status) @protobuf(2,bytes,opt)
}

#SelfSubjectReviewStatus: {
	userInfo?: #UserInfo @go(UserInfo) @protobuf(1,bytes,opt)
}
