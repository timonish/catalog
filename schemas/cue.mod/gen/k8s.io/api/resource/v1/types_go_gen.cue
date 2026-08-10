

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
)

#Finalizer: "resource.kubernetes.io/delete-protection"

#ExtendedResourceClaimAnnotation: "resource.kubernetes.io/extended-resource-claim"

#PodResourceClaimAnnotation: "resource.kubernetes.io/pod-claim-name"

#ResourceDeviceClassPrefix: "deviceclass.resource.kubernetes.io/"

#SubresourceBinding: "binding"

#SubresourceDriver: "driver"

#VerbPrefixAssociatedNode: "associated-node:"

#VerbPrefixArbitraryNode: "arbitrary-node:"

#ResourceSlice: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #ResourceSliceSpec @go(Spec) @protobuf(2,bytes)
}

#ResourceSliceSelectorNodeName: "spec.nodeName"

#ResourceSliceSelectorDriver: "spec.driver"

#ResourceSliceSpec: {
	driver: string @go(Driver) @protobuf(1,bytes)

	pool: #ResourcePool @go(Pool) @protobuf(2,bytes)

	nodeName?: string @go(NodeName,*string) @protobuf(3,bytes,opt)

	nodeSelector?: v1.#NodeSelector @go(NodeSelector,*v1.NodeSelector) @protobuf(4,bytes,opt)

	allNodes?: bool @go(AllNodes,*bool) @protobuf(5,bytes,opt)

	devices?: [...#Device] @go(Devices,[]Device) @protobuf(6,bytes)

	perDeviceNodeSelection?: bool @go(PerDeviceNodeSelection,*bool) @protobuf(7,bytes)

	sharedCounters?: [...#CounterSet] @go(SharedCounters,[]CounterSet) @protobuf(8,bytes)
}

#CounterSet: {
	name: string @go(Name) @protobuf(1,bytes)

	counters: {[string]: #Counter} @go(Counters,map[string]Counter) @protobuf(2,bytes)
}

#DriverNameMaxLength: 63

#ResourcePool: {
	name: string @go(Name) @protobuf(1,bytes)

	generation: int64 @go(Generation) @protobuf(2,bytes)

	resourceSliceCount: int64 @go(ResourceSliceCount) @protobuf(3,bytes)
}

#ResourceSliceMaxSharedCapacity: 128

#ResourceSliceMaxDevices: 128

#ResourceSliceMaxDevicesWithAdvancedFeatures: 64

#PoolNameMaxLength: int & 253

#BindingConditionsMaxSize: 4

#BindingFailureConditionsMaxSize: 4

#ResourceSliceMaxCounterSets: 8

#ResourceSliceMaxCountersPerCounterSet: 32

#ResourceSliceMaxDeviceCounterConsumptionsPerDevice: 2

#ResourceSliceMaxCountersPerDeviceCounterConsumption: 32

#Device: {
	name: string @go(Name) @protobuf(1,bytes)

	attributes?: {[string]: #DeviceAttribute} @go(Attributes,map[QualifiedName]DeviceAttribute) @protobuf(2,bytes,rep)

	capacity?: {[string]: #DeviceCapacity} @go(Capacity,map[QualifiedName]DeviceCapacity) @protobuf(3,bytes,rep)

	consumesCounters?: [...#DeviceCounterConsumption] @go(ConsumesCounters,[]DeviceCounterConsumption) @protobuf(4,bytes,rep)

	nodeName?: string @go(NodeName,*string) @protobuf(5,bytes,opt)

	nodeSelector?: v1.#NodeSelector @go(NodeSelector,*v1.NodeSelector) @protobuf(6,bytes,opt)

	allNodes?: bool @go(AllNodes,*bool) @protobuf(7,bytes,opt)

	taints?: [...#DeviceTaint] @go(Taints,[]DeviceTaint) @protobuf(8,bytes,rep)

	bindsToNode?: bool @go(BindsToNode,*bool) @protobuf(9,varint,opt)

	bindingConditions?: [...string] @go(BindingConditions,[]string) @protobuf(10,bytes,rep)

	bindingFailureConditions?: [...string] @go(BindingFailureConditions,[]string) @protobuf(11,bytes,rep)

	allowMultipleAllocations?: bool @go(AllowMultipleAllocations,*bool) @protobuf(12,bytes,opt)

	nodeAllocatableResourceMappings?: {[string]: #NodeAllocatableResourceMapping} @go(NodeAllocatableResourceMappings,map[v1.ResourceName]NodeAllocatableResourceMapping) @protobuf(13,bytes,opt)
}

#NodeAllocatableResourceMapping: {
	capacityKey?: #QualifiedName @go(CapacityKey,*QualifiedName) @protobuf(1,bytes,opt)

	allocationMultiplier?: resource.#Quantity @go(AllocationMultiplier,*resource.Quantity) @protobuf(2,bytes,opt)
}

#DeviceCounterConsumption: {
	counterSet: string @go(CounterSet) @protobuf(1,bytes,opt)

	counters: {[string]: #Counter} @go(Counters,map[string]Counter) @protobuf(2,bytes,opt)
}

#DeviceCapacity: {
	value: resource.#Quantity @go(Value) @protobuf(1,bytes,rep)

	requestPolicy?: #CapacityRequestPolicy @go(RequestPolicy,*CapacityRequestPolicy) @protobuf(2,bytes,opt)
}

#Counter: {
	value: resource.#Quantity @go(Value) @protobuf(1,bytes,rep)
}

#CapacityRequestPolicy: {
	default?: resource.#Quantity @go(Default,*resource.Quantity) @protobuf(1,bytes,opt)

	validValues?: [...resource.#Quantity] @go(ValidValues,[]resource.Quantity) @protobuf(3,bytes,opt)

	validRange?: #CapacityRequestPolicyRange @go(ValidRange,*CapacityRequestPolicyRange) @protobuf(4,bytes,opt)
}

#CapacityRequestPolicyRange: {
	min: resource.#Quantity @go(Min,*resource.Quantity) @protobuf(1,bytes,opt)

	max?: resource.#Quantity @go(Max,*resource.Quantity) @protobuf(2,bytes,opt)

	step?: resource.#Quantity @go(Step,*resource.Quantity) @protobuf(3,bytes,opt)
}

#ResourceSliceMaxAttributesAndCapacitiesPerDevice: 32

#ResourceSliceMaxAttributeValuesPerDevice: 48

#QualifiedName: string

#FullyQualifiedName: string

#DeviceMaxDomainLength: 63

#DeviceMaxIDLength: 32

#DeviceAttribute: {
	int?: int64 @go(IntValue,*int64) @protobuf(2,varint,opt)

	bool?: bool @go(BoolValue,*bool) @protobuf(3,varint,opt)

	string?: string @go(StringValue,*string) @protobuf(4,bytes,opt)

	version?: string @go(VersionValue,*string) @protobuf(5,bytes,opt)

	ints?: [...int64] @go(IntValues,[]int64) @protobuf(6,varint,opt)

	bools?: [...bool] @go(BoolValues,[]bool) @protobuf(7,varint,opt)

	strings?: [...string] @go(StringValues,[]string) @protobuf(8,bytes,opt)

	versions?: [...string] @go(VersionValues,[]string) @protobuf(9,bytes,opt)
}

#DeviceAttributeMaxValueLength: 64

#DeviceTaintsMaxLength: 16

#DeviceTaint: {
	key: string @go(Key) @protobuf(1,bytes)

	value?: string @go(Value) @protobuf(2,bytes,opt)

	effect: #DeviceTaintEffect @go(Effect) @protobuf(3,bytes,casttype=DeviceTaintEffect)

	timeAdded?: metav1.#Time @go(TimeAdded,*metav1.Time) @protobuf(4,bytes,opt)
}

#DeviceTaintEffect: string // #enumDeviceTaintEffect

#enumDeviceTaintEffect:
	#DeviceTaintEffectNone |
	#DeviceTaintEffectNoSchedule |
	#DeviceTaintEffectNoExecute

#DeviceTaintEffectNone: #DeviceTaintEffect & "None"

#DeviceTaintEffectNoSchedule: #DeviceTaintEffect & "NoSchedule"

#DeviceTaintEffectNoExecute: #DeviceTaintEffect & "NoExecute"

#ResourceSliceList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ResourceSlice] @go(Items,[]ResourceSlice) @protobuf(2,bytes,rep)
}

#ResourceClaim: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #ResourceClaimSpec @go(Spec) @protobuf(2,bytes)

	status?: #ResourceClaimStatus @go(Status) @protobuf(3,bytes,opt)
}

#ResourceClaimSpec: {
	devices?: #DeviceClaim @go(Devices) @protobuf(1,bytes)
}

#DeviceClaim: {
	requests?: [...#DeviceRequest] @go(Requests,[]DeviceRequest) @protobuf(1,bytes)

	constraints?: [...#DeviceConstraint] @go(Constraints,[]DeviceConstraint) @protobuf(2,bytes,opt)

	config?: [...#DeviceClaimConfiguration] @go(Config,[]DeviceClaimConfiguration) @protobuf(3,bytes,opt)
}

#DeviceRequestsMaxSize:    32
#DeviceConstraintsMaxSize: 32
#DeviceConfigMaxSize:      32

#DRAAdminNamespaceLabelKey: "resource.kubernetes.io/admin-access"

#DeviceRequest: {
	name: string @go(Name) @protobuf(1,bytes)

	exactly?: #ExactDeviceRequest @go(Exactly,*ExactDeviceRequest) @protobuf(2,bytes)

	firstAvailable?: [...#DeviceSubRequest] @go(FirstAvailable,[]DeviceSubRequest) @protobuf(3,bytes)
}

#ExactDeviceRequest: {
	deviceClassName: string @go(DeviceClassName) @protobuf(1,bytes)

	selectors?: [...#DeviceSelector] @go(Selectors,[]DeviceSelector) @protobuf(2,bytes)

	allocationMode?: #DeviceAllocationMode @go(AllocationMode) @protobuf(3,bytes,opt)

	count?: int64 @go(Count) @protobuf(4,bytes,opt)

	adminAccess?: bool @go(AdminAccess,*bool) @protobuf(5,bytes,opt)

	tolerations?: [...#DeviceToleration] @go(Tolerations,[]DeviceToleration) @protobuf(6,bytes,opt)

	capacity?: #CapacityRequirements @go(Capacity,*CapacityRequirements) @protobuf(7,bytes,opt)
}

#DeviceSubRequest: {
	name: string @go(Name) @protobuf(1,bytes)

	deviceClassName: string @go(DeviceClassName) @protobuf(2,bytes)

	selectors?: [...#DeviceSelector] @go(Selectors,[]DeviceSelector) @protobuf(3,bytes)

	allocationMode?: #DeviceAllocationMode @go(AllocationMode) @protobuf(4,bytes,opt)

	count?: int64 @go(Count) @protobuf(5,bytes,opt)

	tolerations?: [...#DeviceToleration] @go(Tolerations,[]DeviceToleration) @protobuf(6,bytes,opt)

	capacity?: #CapacityRequirements @go(Capacity,*CapacityRequirements) @protobuf(7,bytes,opt)
}

#CapacityRequirements: {
	requests?: {[string]: resource.#Quantity} @go(Requests,map[QualifiedName]resource.Quantity) @protobuf(1,bytes,rep,castkey=QualifiedName)
}

#DeviceSelectorsMaxSize:             32
#FirstAvailableDeviceRequestMaxSize: 8
#DeviceTolerationsMaxLength:         16

#DeviceAllocationMode: string // #enumDeviceAllocationMode

#enumDeviceAllocationMode:
	#DeviceAllocationModeExactCount |
	#DeviceAllocationModeAll

#DeviceAllocationModeExactCount: #DeviceAllocationMode & "ExactCount"
#DeviceAllocationModeAll:        #DeviceAllocationMode & "All"

#DeviceSelector: {
	cel?: #CELDeviceSelector @go(CEL,*CELDeviceSelector) @protobuf(1,bytes,opt)
}

#CELDeviceSelector: {
	expression: string @go(Expression) @protobuf(1,bytes)
}

#CELSelectorExpressionMaxCost: 1000000

#CELSelectorExpressionMaxLength: 10240

#DeviceConstraint: {
	requests?: [...string] @go(Requests,[]string) @protobuf(1,bytes,opt)

	matchAttribute?: #FullyQualifiedName @go(MatchAttribute,*FullyQualifiedName) @protobuf(2,bytes,opt)

	distinctAttribute?: #FullyQualifiedName @go(DistinctAttribute,*FullyQualifiedName) @protobuf(3,bytes,opt)
}

#DeviceClaimConfiguration: {
	requests?: [...string] @go(Requests,[]string) @protobuf(1,bytes,opt)

	#DeviceConfiguration
}

#DeviceConfiguration: {
	opaque?: #OpaqueDeviceConfiguration @go(Opaque,*OpaqueDeviceConfiguration) @protobuf(1,bytes,opt)
}

#OpaqueDeviceConfiguration: {
	driver: string @go(Driver) @protobuf(1,bytes)

	parameters: runtime.#RawExtension @go(Parameters) @protobuf(2,bytes)
}

#OpaqueParametersMaxLength: 10240

#DeviceToleration: {
	key?: string @go(Key) @protobuf(1,bytes,opt)

	operator?: #DeviceTolerationOperator @go(Operator) @protobuf(2,bytes,opt,casttype=DeviceTolerationOperator)

	value?: string @go(Value) @protobuf(3,bytes,opt)

	effect?: #DeviceTaintEffect @go(Effect) @protobuf(4,bytes,opt,casttype=DeviceTaintEffect)

	tolerationSeconds?: int64 @go(TolerationSeconds,*int64) @protobuf(5,varint,opt)
}

#DeviceTolerationOperator: string // #enumDeviceTolerationOperator

#enumDeviceTolerationOperator:
	#DeviceTolerationOpExists |
	#DeviceTolerationOpEqual

#DeviceTolerationOpExists: #DeviceTolerationOperator & "Exists"
#DeviceTolerationOpEqual:  #DeviceTolerationOperator & "Equal"

#ResourceClaimStatus: {
	allocation?: #AllocationResult @go(Allocation,*AllocationResult) @protobuf(1,bytes,opt)

	reservedFor?: [...#ResourceClaimConsumerReference] @go(ReservedFor,[]ResourceClaimConsumerReference) @protobuf(2,bytes,opt)

	devices?: [...#AllocatedDeviceStatus] @go(Devices,[]AllocatedDeviceStatus) @protobuf(4,bytes,opt)
}

#ResourceClaimReservedForMaxSize: 256

#ResourceClaimConsumerReference: {
	apiGroup?: string @go(APIGroup) @protobuf(1,bytes,opt)

	resource: string @go(Resource) @protobuf(3,bytes)

	name: string @go(Name) @protobuf(4,bytes)

	uid: types.#UID @go(UID) @protobuf(5,bytes)
}

#AllocationResult: {
	devices?: #DeviceAllocationResult @go(Devices) @protobuf(1,bytes,opt)

	nodeSelector?: v1.#NodeSelector @go(NodeSelector,*v1.NodeSelector) @protobuf(3,bytes,opt)

	allocationTimestamp?: metav1.#Time @go(AllocationTimestamp,*metav1.Time) @protobuf(5,bytes,opt)
}

#DeviceAllocationResult: {
	results?: [...#DeviceRequestAllocationResult] @go(Results,[]DeviceRequestAllocationResult) @protobuf(1,bytes,opt)

	config?: [...#DeviceAllocationConfiguration] @go(Config,[]DeviceAllocationConfiguration) @protobuf(2,bytes,opt)
}

#AllocationResultsMaxSize: 32

#DeviceRequestAllocationResult: {
	request: string @go(Request) @protobuf(1,bytes)

	driver: string @go(Driver) @protobuf(2,bytes)

	pool: string @go(Pool) @protobuf(3,bytes)

	device: string @go(Device) @protobuf(4,bytes)

	adminAccess?: bool @go(AdminAccess,*bool) @protobuf(5,bytes,opt)

	tolerations?: [...#DeviceToleration] @go(Tolerations,[]DeviceToleration) @protobuf(6,bytes,opt)

	bindingConditions?: [...string] @go(BindingConditions,[]string) @protobuf(7,bytes,rep)

	bindingFailureConditions?: [...string] @go(BindingFailureConditions,[]string) @protobuf(8,bytes,rep)

	shareID?: types.#UID @go(ShareID,*types.UID) @protobuf(9,bytes,opt)

	consumedCapacity?: {[string]: resource.#Quantity} @go(ConsumedCapacity,map[QualifiedName]resource.Quantity) @protobuf(10,bytes,rep)
}

#DeviceAllocationConfiguration: {
	source: #AllocationConfigSource @go(Source) @protobuf(1,bytes)

	requests?: [...string] @go(Requests,[]string) @protobuf(2,bytes,opt)

	#DeviceConfiguration
}

#AllocationConfigSource: string // #enumAllocationConfigSource

#enumAllocationConfigSource:
	#AllocationConfigSourceClass |
	#AllocationConfigSourceClaim

#AllocationConfigSourceClass: #AllocationConfigSource & "FromClass"
#AllocationConfigSourceClaim: #AllocationConfigSource & "FromClaim"

#ResourceClaimList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ResourceClaim] @go(Items,[]ResourceClaim) @protobuf(2,bytes,rep)
}

#DeviceClass: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #DeviceClassSpec @go(Spec) @protobuf(2,bytes)
}

#DeviceClassSpec: {
	selectors?: [...#DeviceSelector] @go(Selectors,[]DeviceSelector) @protobuf(1,bytes,opt)

	config?: [...#DeviceClassConfiguration] @go(Config,[]DeviceClassConfiguration) @protobuf(2,bytes,opt)

	extendedResourceName?: string @go(ExtendedResourceName,*string) @protobuf(4,bytes,opt)
}

#DeviceClassConfiguration: {
	#DeviceConfiguration
}

#DeviceClassList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#DeviceClass] @go(Items,[]DeviceClass) @protobuf(2,bytes,rep)
}

#ResourceClaimTemplate: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #ResourceClaimTemplateSpec @go(Spec) @protobuf(2,bytes)
}

#ResourceClaimTemplateSpec: {
	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #ResourceClaimSpec @go(Spec) @protobuf(2,bytes)
}

#ResourceClaimTemplateList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ResourceClaimTemplate] @go(Items,[]ResourceClaimTemplate) @protobuf(2,bytes,rep)
}

#AllocatedDeviceStatusMaxConditions: int & 8

#AllocatedDeviceStatusDataMaxLength: int & 10240

#NetworkDeviceDataMaxIPs: int & 16

#NetworkDeviceDataInterfaceNameMaxLength: int & 256

#NetworkDeviceDataHardwareAddressMaxLength: int & 128

#AllocatedDeviceStatus: {
	driver: string @go(Driver) @protobuf(1,bytes,rep)

	pool: string @go(Pool) @protobuf(2,bytes,rep)

	device: string @go(Device) @protobuf(3,bytes,rep)

	shareID?: string @go(ShareID,*string) @protobuf(7,bytes,opt)

	conditions?: [...metav1.#Condition] @go(Conditions,[]metav1.Condition) @protobuf(4,bytes,opt)

	data?: runtime.#RawExtension @go(Data,*runtime.RawExtension) @protobuf(5,bytes,opt)

	networkData?: #NetworkDeviceData @go(NetworkData,*NetworkDeviceData) @protobuf(6,bytes,opt)
}

#NetworkDeviceData: {
	interfaceName?: string @go(InterfaceName) @protobuf(1,bytes,opt)

	ips?: [...string] @go(IPs,[]string) @protobuf(2,bytes,opt)

	hardwareAddress?: string @go(HardwareAddress) @protobuf(3,bytes,opt)
}
