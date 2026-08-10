

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	authenticationv1 "k8s.io/api/authentication/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

#AdmissionReview: {
	metav1.#TypeMeta

	request?: null | #AdmissionRequest @go(Request,*AdmissionRequest) @protobuf(1,bytes,opt)

	response?: null | #AdmissionResponse @go(Response,*AdmissionResponse) @protobuf(2,bytes,opt)
}

#AdmissionRequest: {
	uid?: types.#UID @go(UID) @protobuf(1,bytes,opt)

	kind?: metav1.#GroupVersionKind @go(Kind) @protobuf(2,bytes,opt)

	resource?: metav1.#GroupVersionResource @go(Resource) @protobuf(3,bytes,opt)

	subResource?: string @go(SubResource) @protobuf(4,bytes,opt)

	requestKind?: null | metav1.#GroupVersionKind @go(RequestKind,*metav1.GroupVersionKind) @protobuf(13,bytes,opt)

	requestResource?: null | metav1.#GroupVersionResource @go(RequestResource,*metav1.GroupVersionResource) @protobuf(14,bytes,opt)

	requestSubResource?: string @go(RequestSubResource) @protobuf(15,bytes,opt)

	name?: string @go(Name) @protobuf(5,bytes,opt)

	namespace?: string @go(Namespace) @protobuf(6,bytes,opt)

	operation?: #Operation @go(Operation) @protobuf(7,bytes,opt)

	userInfo?: authenticationv1.#UserInfo @go(UserInfo) @protobuf(8,bytes,opt)

	object?: runtime.#RawExtension @go(Object) @protobuf(9,bytes,opt)

	oldObject?: runtime.#RawExtension @go(OldObject) @protobuf(10,bytes,opt)

	dryRun?: null | bool @go(DryRun,*bool) @protobuf(11,varint,opt)

	options?: runtime.#RawExtension @go(Options) @protobuf(12,bytes,opt)
}

#AdmissionResponse: {
	uid?: types.#UID @go(UID) @protobuf(1,bytes,opt)

	allowed?: bool @go(Allowed) @protobuf(2,varint,opt)

	status?: null | metav1.#Status @go(Result,*metav1.Status) @protobuf(3,bytes,opt)

	patch?: bytes @go(Patch,[]byte) @protobuf(4,bytes,opt)

	patchType?: null | #PatchType @go(PatchType,*PatchType) @protobuf(5,bytes,opt)

	auditAnnotations?: {[string]: string} @go(AuditAnnotations,map[string]string) @protobuf(6,bytes,opt)

	warnings?: [...string] @go(Warnings,[]string) @protobuf(7,bytes,rep)
}

#PatchType: string // #enumPatchType

#enumPatchType:
	#PatchTypeJSONPatch

#PatchTypeJSONPatch: #PatchType & "JSONPatch"

#Operation: string // #enumOperation

#enumOperation:
	#Create |
	#Update |
	#Delete |
	#Connect

#Create:  #Operation & "CREATE"
#Update:  #Operation & "UPDATE"
#Delete:  #Operation & "DELETE"
#Connect: #Operation & "CONNECT"
