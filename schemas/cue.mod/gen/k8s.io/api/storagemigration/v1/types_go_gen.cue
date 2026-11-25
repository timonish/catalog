

package v1

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

#StorageVersionMigration: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #StorageVersionMigrationSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #StorageVersionMigrationStatus @go(Status) @protobuf(3,bytes,opt)
}

#StorageVersionMigrationSpec: {
	resource: metav1.#GroupResource @go(Resource) @protobuf(1,bytes,opt)
}

#MigrationConditionType: string // #enumMigrationConditionType

#enumMigrationConditionType:
	#MigrationRunning |
	#MigrationSucceeded |
	#MigrationFailed

#MigrationRunning: #MigrationConditionType & "Running"

#MigrationSucceeded: #MigrationConditionType & "Succeeded"

#MigrationFailed: #MigrationConditionType & "Failed"

#StorageVersionMigrationStatus: {
	conditions?: [...metav1.#Condition] @go(Conditions,[]metav1.Condition) @protobuf(1,bytes,rep)

	resourceVersion?: string @go(ResourceVersion) @protobuf(2,bytes,opt)
}

#StorageVersionMigrationList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#StorageVersionMigration] @go(Items,[]StorageVersionMigration) @protobuf(2,bytes,rep)
}
