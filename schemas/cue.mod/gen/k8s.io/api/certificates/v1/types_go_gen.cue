

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/api/core/v1"
)

#CertificateSigningRequest: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #CertificateSigningRequestSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #CertificateSigningRequestStatus @go(Status) @protobuf(3,bytes,opt)
}

#CertificateSigningRequestSpec: {
	request: bytes @go(Request,[]byte) @protobuf(1,bytes,opt)

	signerName: string @go(SignerName) @protobuf(7,bytes,opt)

	expirationSeconds?: int32 @go(ExpirationSeconds,*int32) @protobuf(8,varint,opt)

	usages?: [...#KeyUsage] @go(Usages,[]KeyUsage) @protobuf(5,bytes,opt)

	username?: string @go(Username) @protobuf(2,bytes,opt)

	uid?: string @go(UID) @protobuf(3,bytes,opt)

	groups?: [...string] @go(Groups,[]string) @protobuf(4,bytes,rep)

	extra?: {[string]: #ExtraValue} @go(Extra,map[string]ExtraValue) @protobuf(6,bytes,rep)
}

#KubeAPIServerClientSignerName: "kubernetes.io/kube-apiserver-client"

#KubeAPIServerClientKubeletSignerName: "kubernetes.io/kube-apiserver-client-kubelet"

#KubeletServingSignerName: "kubernetes.io/kubelet-serving"

#ExtraValue: [...string]

#CertificateSigningRequestStatus: {
	conditions?: [...#CertificateSigningRequestCondition] @go(Conditions,[]CertificateSigningRequestCondition) @protobuf(1,bytes,rep)

	certificate?: bytes @go(Certificate,[]byte) @protobuf(2,bytes,opt)
}

#RequestConditionType: string // #enumRequestConditionType

#enumRequestConditionType:
	#CertificateApproved |
	#CertificateDenied |
	#CertificateFailed

#CertificateApproved: #RequestConditionType & "Approved"

#CertificateDenied: #RequestConditionType & "Denied"

#CertificateFailed: #RequestConditionType & "Failed"

#CertificateSigningRequestCondition: {
	type: #RequestConditionType @go(Type) @protobuf(1,bytes,opt,casttype=RequestConditionType)

	status: v1.#ConditionStatus @go(Status) @protobuf(6,bytes,opt,casttype=k8s.io/api/core/v1.ConditionStatus)

	reason?: string @go(Reason) @protobuf(2,bytes,opt)

	message?: string @go(Message) @protobuf(3,bytes,opt)

	lastUpdateTime?: metav1.#Time @go(LastUpdateTime) @protobuf(4,bytes,opt)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(5,bytes,opt)
}

#CertificateSigningRequestList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#CertificateSigningRequest] @go(Items,[]CertificateSigningRequest) @protobuf(2,bytes,rep)
}

#KeyUsage: string // #enumKeyUsage

#enumKeyUsage:
	#UsageSigning |
	#UsageDigitalSignature |
	#UsageContentCommitment |
	#UsageKeyEncipherment |
	#UsageKeyAgreement |
	#UsageDataEncipherment |
	#UsageCertSign |
	#UsageCRLSign |
	#UsageEncipherOnly |
	#UsageDecipherOnly |
	#UsageAny |
	#UsageServerAuth |
	#UsageClientAuth |
	#UsageCodeSigning |
	#UsageEmailProtection |
	#UsageSMIME |
	#UsageIPsecEndSystem |
	#UsageIPsecTunnel |
	#UsageIPsecUser |
	#UsageTimestamping |
	#UsageOCSPSigning |
	#UsageMicrosoftSGC |
	#UsageNetscapeSGC

#UsageSigning:           #KeyUsage & "signing"
#UsageDigitalSignature:  #KeyUsage & "digital signature"
#UsageContentCommitment: #KeyUsage & "content commitment"
#UsageKeyEncipherment:   #KeyUsage & "key encipherment"
#UsageKeyAgreement:      #KeyUsage & "key agreement"
#UsageDataEncipherment:  #KeyUsage & "data encipherment"
#UsageCertSign:          #KeyUsage & "cert sign"
#UsageCRLSign:           #KeyUsage & "crl sign"
#UsageEncipherOnly:      #KeyUsage & "encipher only"
#UsageDecipherOnly:      #KeyUsage & "decipher only"
#UsageAny:               #KeyUsage & "any"
#UsageServerAuth:        #KeyUsage & "server auth"
#UsageClientAuth:        #KeyUsage & "client auth"
#UsageCodeSigning:       #KeyUsage & "code signing"
#UsageEmailProtection:   #KeyUsage & "email protection"
#UsageSMIME:             #KeyUsage & "s/mime"
#UsageIPsecEndSystem:    #KeyUsage & "ipsec end system"
#UsageIPsecTunnel:       #KeyUsage & "ipsec tunnel"
#UsageIPsecUser:         #KeyUsage & "ipsec user"
#UsageTimestamping:      #KeyUsage & "timestamping"
#UsageOCSPSigning:       #KeyUsage & "ocsp signing"
#UsageMicrosoftSGC:      #KeyUsage & "microsoft sgc"
#UsageNetscapeSGC:       #KeyUsage & "netscape sgc"
