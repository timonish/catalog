

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	corev1 "k8s.io/api/core/v1"
)

#Event: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	eventTime: metav1.#MicroTime @go(EventTime) @protobuf(2,bytes,opt)

	series?: #EventSeries @go(Series,*EventSeries) @protobuf(3,bytes,opt)

	reportingController?: string @go(ReportingController) @protobuf(4,bytes,opt)

	reportingInstance?: string @go(ReportingInstance) @protobuf(5,bytes,opt)

	action?: string @go(Action) @protobuf(6,bytes)

	reason?: string @go(Reason) @protobuf(7,bytes)

	regarding?: corev1.#ObjectReference @go(Regarding) @protobuf(8,bytes,opt)

	related?: corev1.#ObjectReference @go(Related,*corev1.ObjectReference) @protobuf(9,bytes,opt)

	note?: string @go(Note) @protobuf(10,bytes,opt)

	type?: string @go(Type) @protobuf(11,bytes,opt)

	deprecatedSource?: corev1.#EventSource @go(DeprecatedSource) @protobuf(12,bytes,opt)

	deprecatedFirstTimestamp?: metav1.#Time @go(DeprecatedFirstTimestamp) @protobuf(13,bytes,opt)

	deprecatedLastTimestamp?: metav1.#Time @go(DeprecatedLastTimestamp) @protobuf(14,bytes,opt)

	deprecatedCount?: int32 @go(DeprecatedCount) @protobuf(15,varint,opt)
}

#EventSeries: {
	count: int32 @go(Count) @protobuf(1,varint,opt)

	lastObservedTime: metav1.#MicroTime @go(LastObservedTime) @protobuf(2,bytes,opt)
}

#EventList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Event] @go(Items,[]Event) @protobuf(2,bytes,rep)
}
