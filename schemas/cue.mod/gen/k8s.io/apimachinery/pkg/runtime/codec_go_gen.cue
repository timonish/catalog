

package runtime

_#codec: {
	Encoder: #Encoder
	Decoder: #Decoder
}

#NoopEncoder: {
	Decoder: #Decoder
}

_#noopEncoderIdentifier: #Identifier & "noop"

#NoopDecoder: {
	Encoder: #Encoder
}

_#base64Serializer: {
	Encoder: #Encoder
	Decoder: #Decoder
}

_#internalGroupVersionerIdentifier: "internal"
_#disabledGroupVersionerIdentifier: "disabled"

_#internalGroupVersioner: {}

_#disabledGroupVersioner: {}
