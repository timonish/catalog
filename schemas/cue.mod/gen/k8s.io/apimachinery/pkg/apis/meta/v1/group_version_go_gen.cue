

package v1

#GroupResource: {
	group:    string @go(Group) @protobuf(1,bytes,opt)
	resource: string @go(Resource) @protobuf(2,bytes,opt)
}

#GroupVersionResource: {
	group:    string @go(Group) @protobuf(1,bytes,opt)
	version:  string @go(Version) @protobuf(2,bytes,opt)
	resource: string @go(Resource) @protobuf(3,bytes,opt)
}

#GroupKind: {
	group: string @go(Group) @protobuf(1,bytes,opt)
	kind:  string @go(Kind) @protobuf(2,bytes,opt)
}

#GroupVersionKind: {
	group:   string @go(Group) @protobuf(1,bytes,opt)
	version: string @go(Version) @protobuf(2,bytes,opt)
	kind:    string @go(Kind) @protobuf(3,bytes,opt)
}

#GroupVersion: _
