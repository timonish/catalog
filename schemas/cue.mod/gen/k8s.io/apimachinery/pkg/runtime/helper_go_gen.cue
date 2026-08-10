

package runtime

#MultiObjectTyper: [...#ObjectTyper]

_#defaultFramer: {}

#WithVersionEncoder: {
	Version:     #GroupVersioner
	Encoder:     #Encoder
	ObjectTyper: #ObjectTyper
}

#WithoutVersionDecoder: {
	Decoder: #Decoder
}

_#nondeterministicEncoderToEncoderAdapter: NondeterministicEncoder: #NondeterministicEncoder
