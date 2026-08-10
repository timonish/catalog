

package v1

import (
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/watch"
)

#WatchEvent: {
	type: string @go(Type) @protobuf(1,bytes,opt)

	object: runtime.#RawExtension @go(Object) @protobuf(2,bytes,opt)
}

#InternalEvent: watch.#Event
