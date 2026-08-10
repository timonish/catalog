

package v1

#Timestamp: {
	seconds: int64 @go(Seconds) @protobuf(1,varint,opt)

	nanos: int32 @go(Nanos) @protobuf(2,varint,opt)
}
