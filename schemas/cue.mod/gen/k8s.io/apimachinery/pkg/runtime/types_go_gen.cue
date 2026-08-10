

package runtime

#TypeMeta: {
	apiVersion?: string @go(APIVersion) @protobuf(1,bytes,opt)

	kind?: string @go(Kind) @protobuf(2,bytes,opt)
}

#ContentTypeJSON:         "application/json"
#ContentTypeYAML:         "application/yaml"
#ContentTypeProtobuf:     "application/vnd.kubernetes.protobuf"
#ContentTypeCBOR:         "application/cbor"
#ContentTypeCBORSequence: "application/cbor-seq"

#RawExtension: _

#Unknown: _
