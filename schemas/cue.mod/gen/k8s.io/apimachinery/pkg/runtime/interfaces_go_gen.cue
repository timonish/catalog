

package runtime

#APIVersionInternal: "__internal"

#GroupVersioner: _

#Identifier: string // #enumIdentifier

#enumIdentifier:
	_#noopEncoderIdentifier

#Encoder: _

#NondeterministicEncoder: _

#MemoryAllocator: _

#EncoderWithAllocator: _

#Decoder: _

#Serializer: _

#Codec: #Serializer

#ParameterCodec: _

#Framer: _

#SerializerInfo: {
	MediaType: string

	MediaTypeType: string

	MediaTypeSubType: string

	EncodesAsText: bool

	Serializer: #Serializer

	PrettySerializer: #Serializer

	StrictSerializer: #Serializer

	StreamSerializer?: #StreamSerializerInfo @go(,*StreamSerializerInfo)
}

#StreamSerializerInfo: {
	EncodesAsText: bool

	Serializer: #Serializer

	Framer: #Framer
}

#NegotiatedSerializer: _

#ClientNegotiator: _

#StorageSerializer: _

#NestedObjectEncoder: _

#NestedObjectDecoder: _

#ObjectDefaulter: _

#ObjectVersioner: _

#ObjectConvertor: _

#ObjectTyper: _

#ObjectCreater: _

#EquivalentResourceMapper: _

#EquivalentResourceRegistry: _

#ResourceVersioner: _

#Namer: _

#Object: _

#CacheableObject: _

#Unstructured: _

#ApplyConfiguration: _
