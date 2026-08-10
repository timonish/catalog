

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/api/resource"
	resource_9 "k8s.io/apimachinery/pkg/api/resource"
	"k8s.io/apimachinery/pkg/util/intstr"
	"k8s.io/apimachinery/pkg/types"
)

#NamespaceDefault: "default"

#NamespaceAll: ""

#NamespaceNodeLease: "kube-node-lease"

#Volume: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	#VolumeSource
}

#VolumeSource: {
	hostPath?: #HostPathVolumeSource @go(HostPath,*HostPathVolumeSource) @protobuf(1,bytes,opt)

	emptyDir?: #EmptyDirVolumeSource @go(EmptyDir,*EmptyDirVolumeSource) @protobuf(2,bytes,opt)

	gcePersistentDisk?: #GCEPersistentDiskVolumeSource @go(GCEPersistentDisk,*GCEPersistentDiskVolumeSource) @protobuf(3,bytes,opt)

	awsElasticBlockStore?: #AWSElasticBlockStoreVolumeSource @go(AWSElasticBlockStore,*AWSElasticBlockStoreVolumeSource) @protobuf(4,bytes,opt)

	gitRepo?: #GitRepoVolumeSource @go(GitRepo,*GitRepoVolumeSource) @protobuf(5,bytes,opt)

	secret?: #SecretVolumeSource @go(Secret,*SecretVolumeSource) @protobuf(6,bytes,opt)

	nfs?: #NFSVolumeSource @go(NFS,*NFSVolumeSource) @protobuf(7,bytes,opt)

	iscsi?: #ISCSIVolumeSource @go(ISCSI,*ISCSIVolumeSource) @protobuf(8,bytes,opt)

	glusterfs?: #GlusterfsVolumeSource @go(Glusterfs,*GlusterfsVolumeSource) @protobuf(9,bytes,opt)

	persistentVolumeClaim?: #PersistentVolumeClaimVolumeSource @go(PersistentVolumeClaim,*PersistentVolumeClaimVolumeSource) @protobuf(10,bytes,opt)

	rbd?: #RBDVolumeSource @go(RBD,*RBDVolumeSource) @protobuf(11,bytes,opt)

	flexVolume?: #FlexVolumeSource @go(FlexVolume,*FlexVolumeSource) @protobuf(12,bytes,opt)

	cinder?: #CinderVolumeSource @go(Cinder,*CinderVolumeSource) @protobuf(13,bytes,opt)

	cephfs?: #CephFSVolumeSource @go(CephFS,*CephFSVolumeSource) @protobuf(14,bytes,opt)

	flocker?: #FlockerVolumeSource @go(Flocker,*FlockerVolumeSource) @protobuf(15,bytes,opt)

	downwardAPI?: #DownwardAPIVolumeSource @go(DownwardAPI,*DownwardAPIVolumeSource) @protobuf(16,bytes,opt)

	fc?: #FCVolumeSource @go(FC,*FCVolumeSource) @protobuf(17,bytes,opt)

	azureFile?: #AzureFileVolumeSource @go(AzureFile,*AzureFileVolumeSource) @protobuf(18,bytes,opt)

	configMap?: #ConfigMapVolumeSource @go(ConfigMap,*ConfigMapVolumeSource) @protobuf(19,bytes,opt)

	vsphereVolume?: #VsphereVirtualDiskVolumeSource @go(VsphereVolume,*VsphereVirtualDiskVolumeSource) @protobuf(20,bytes,opt)

	quobyte?: #QuobyteVolumeSource @go(Quobyte,*QuobyteVolumeSource) @protobuf(21,bytes,opt)

	azureDisk?: #AzureDiskVolumeSource @go(AzureDisk,*AzureDiskVolumeSource) @protobuf(22,bytes,opt)

	photonPersistentDisk?: #PhotonPersistentDiskVolumeSource @go(PhotonPersistentDisk,*PhotonPersistentDiskVolumeSource) @protobuf(23,bytes,opt)

	projected?: #ProjectedVolumeSource @go(Projected,*ProjectedVolumeSource) @protobuf(26,bytes,opt)

	portworxVolume?: #PortworxVolumeSource @go(PortworxVolume,*PortworxVolumeSource) @protobuf(24,bytes,opt)

	scaleIO?: #ScaleIOVolumeSource @go(ScaleIO,*ScaleIOVolumeSource) @protobuf(25,bytes,opt)

	storageos?: #StorageOSVolumeSource @go(StorageOS,*StorageOSVolumeSource) @protobuf(27,bytes,opt)

	csi?: #CSIVolumeSource @go(CSI,*CSIVolumeSource) @protobuf(28,bytes,opt)

	ephemeral?: #EphemeralVolumeSource @go(Ephemeral,*EphemeralVolumeSource) @protobuf(29,bytes,opt)

	image?: #ImageVolumeSource @go(Image,*ImageVolumeSource) @protobuf(30,bytes,opt)
}

#PersistentVolumeClaimVolumeSource: {
	claimName: string @go(ClaimName) @protobuf(1,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(2,varint,opt)
}

#PersistentVolumeSource: {
	gcePersistentDisk?: #GCEPersistentDiskVolumeSource @go(GCEPersistentDisk,*GCEPersistentDiskVolumeSource) @protobuf(1,bytes,opt)

	awsElasticBlockStore?: #AWSElasticBlockStoreVolumeSource @go(AWSElasticBlockStore,*AWSElasticBlockStoreVolumeSource) @protobuf(2,bytes,opt)

	hostPath?: #HostPathVolumeSource @go(HostPath,*HostPathVolumeSource) @protobuf(3,bytes,opt)

	glusterfs?: #GlusterfsPersistentVolumeSource @go(Glusterfs,*GlusterfsPersistentVolumeSource) @protobuf(4,bytes,opt)

	nfs?: #NFSVolumeSource @go(NFS,*NFSVolumeSource) @protobuf(5,bytes,opt)

	rbd?: #RBDPersistentVolumeSource @go(RBD,*RBDPersistentVolumeSource) @protobuf(6,bytes,opt)

	iscsi?: #ISCSIPersistentVolumeSource @go(ISCSI,*ISCSIPersistentVolumeSource) @protobuf(7,bytes,opt)

	cinder?: #CinderPersistentVolumeSource @go(Cinder,*CinderPersistentVolumeSource) @protobuf(8,bytes,opt)

	cephfs?: #CephFSPersistentVolumeSource @go(CephFS,*CephFSPersistentVolumeSource) @protobuf(9,bytes,opt)

	fc?: #FCVolumeSource @go(FC,*FCVolumeSource) @protobuf(10,bytes,opt)

	flocker?: #FlockerVolumeSource @go(Flocker,*FlockerVolumeSource) @protobuf(11,bytes,opt)

	flexVolume?: #FlexPersistentVolumeSource @go(FlexVolume,*FlexPersistentVolumeSource) @protobuf(12,bytes,opt)

	azureFile?: #AzureFilePersistentVolumeSource @go(AzureFile,*AzureFilePersistentVolumeSource) @protobuf(13,bytes,opt)

	vsphereVolume?: #VsphereVirtualDiskVolumeSource @go(VsphereVolume,*VsphereVirtualDiskVolumeSource) @protobuf(14,bytes,opt)

	quobyte?: #QuobyteVolumeSource @go(Quobyte,*QuobyteVolumeSource) @protobuf(15,bytes,opt)

	azureDisk?: #AzureDiskVolumeSource @go(AzureDisk,*AzureDiskVolumeSource) @protobuf(16,bytes,opt)

	photonPersistentDisk?: #PhotonPersistentDiskVolumeSource @go(PhotonPersistentDisk,*PhotonPersistentDiskVolumeSource) @protobuf(17,bytes,opt)

	portworxVolume?: #PortworxVolumeSource @go(PortworxVolume,*PortworxVolumeSource) @protobuf(18,bytes,opt)

	scaleIO?: #ScaleIOPersistentVolumeSource @go(ScaleIO,*ScaleIOPersistentVolumeSource) @protobuf(19,bytes,opt)

	local?: #LocalVolumeSource @go(Local,*LocalVolumeSource) @protobuf(20,bytes,opt)

	storageos?: #StorageOSPersistentVolumeSource @go(StorageOS,*StorageOSPersistentVolumeSource) @protobuf(21,bytes,opt)

	csi?: #CSIPersistentVolumeSource @go(CSI,*CSIPersistentVolumeSource) @protobuf(22,bytes,opt)
}

#BetaStorageClassAnnotation: "volume.beta.kubernetes.io/storage-class"

#MountOptionAnnotation: "volume.beta.kubernetes.io/mount-options"

#PersistentVolume: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #PersistentVolumeSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #PersistentVolumeStatus @go(Status) @protobuf(3,bytes,opt)
}

#PersistentVolumeSpec: {
	capacity?: #ResourceList @go(Capacity) @protobuf(1,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	#PersistentVolumeSource

	accessModes?: [...#PersistentVolumeAccessMode] @go(AccessModes,[]PersistentVolumeAccessMode) @protobuf(3,bytes,rep,casttype=PersistentVolumeAccessMode)

	claimRef?: #ObjectReference @go(ClaimRef,*ObjectReference) @protobuf(4,bytes,opt)

	persistentVolumeReclaimPolicy?: #PersistentVolumeReclaimPolicy @go(PersistentVolumeReclaimPolicy) @protobuf(5,bytes,opt,casttype=PersistentVolumeReclaimPolicy)

	storageClassName?: string @go(StorageClassName) @protobuf(6,bytes,opt)

	mountOptions?: [...string] @go(MountOptions,[]string) @protobuf(7,bytes,opt)

	volumeMode?: #PersistentVolumeMode @go(VolumeMode,*PersistentVolumeMode) @protobuf(8,bytes,opt,casttype=PersistentVolumeMode)

	nodeAffinity?: #VolumeNodeAffinity @go(NodeAffinity,*VolumeNodeAffinity) @protobuf(9,bytes,opt)

	volumeAttributesClassName?: string @go(VolumeAttributesClassName,*string) @protobuf(10,bytes,opt)
}

#VolumeNodeAffinity: {
	required?: #NodeSelector @go(Required,*NodeSelector) @protobuf(1,bytes,opt)
}

#PersistentVolumeReclaimPolicy: string // #enumPersistentVolumeReclaimPolicy

#enumPersistentVolumeReclaimPolicy:
	#PersistentVolumeReclaimRecycle |
	#PersistentVolumeReclaimDelete |
	#PersistentVolumeReclaimRetain

#PersistentVolumeReclaimRecycle: #PersistentVolumeReclaimPolicy & "Recycle"

#PersistentVolumeReclaimDelete: #PersistentVolumeReclaimPolicy & "Delete"

#PersistentVolumeReclaimRetain: #PersistentVolumeReclaimPolicy & "Retain"

#PersistentVolumeMode: string // #enumPersistentVolumeMode

#enumPersistentVolumeMode:
	#PersistentVolumeBlock |
	#PersistentVolumeFilesystem

#PersistentVolumeBlock: #PersistentVolumeMode & "Block"

#PersistentVolumeFilesystem: #PersistentVolumeMode & "Filesystem"

#PersistentVolumeStatus: {
	phase?: #PersistentVolumePhase @go(Phase) @protobuf(1,bytes,opt,casttype=PersistentVolumePhase)

	message?: string @go(Message) @protobuf(2,bytes,opt)

	reason?: string @go(Reason) @protobuf(3,bytes,opt)

	lastPhaseTransitionTime?: metav1.#Time @go(LastPhaseTransitionTime,*metav1.Time) @protobuf(4,bytes,opt)
}

#PersistentVolumeList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#PersistentVolume] @go(Items,[]PersistentVolume) @protobuf(2,bytes,rep)
}

#PersistentVolumeClaim: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #PersistentVolumeClaimSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #PersistentVolumeClaimStatus @go(Status) @protobuf(3,bytes,opt)
}

#PersistentVolumeClaimList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#PersistentVolumeClaim] @go(Items,[]PersistentVolumeClaim) @protobuf(2,bytes,rep)
}

#PersistentVolumeClaimSpec: {
	accessModes?: [...#PersistentVolumeAccessMode] @go(AccessModes,[]PersistentVolumeAccessMode) @protobuf(1,bytes,rep,casttype=PersistentVolumeAccessMode)

	selector?: metav1.#LabelSelector @go(Selector,*metav1.LabelSelector) @protobuf(4,bytes,opt)

	resources?: #VolumeResourceRequirements @go(Resources) @protobuf(2,bytes,opt)

	volumeName?: string @go(VolumeName) @protobuf(3,bytes,opt)

	storageClassName?: string @go(StorageClassName,*string) @protobuf(5,bytes,opt)

	volumeMode?: #PersistentVolumeMode @go(VolumeMode,*PersistentVolumeMode) @protobuf(6,bytes,opt,casttype=PersistentVolumeMode)

	dataSource?: #TypedLocalObjectReference @go(DataSource,*TypedLocalObjectReference) @protobuf(7,bytes,opt)

	dataSourceRef?: #TypedObjectReference @go(DataSourceRef,*TypedObjectReference) @protobuf(8,bytes,opt)

	volumeAttributesClassName?: string @go(VolumeAttributesClassName,*string) @protobuf(9,bytes,opt)
}

#TypedObjectReference: {
	apiGroup?: string @go(APIGroup,*string) @protobuf(1,bytes,opt)

	kind: string @go(Kind) @protobuf(2,bytes,opt)

	name: string @go(Name) @protobuf(3,bytes,opt)

	namespace?: string @go(Namespace,*string) @protobuf(4,bytes,opt)
}

#PersistentVolumeClaimConditionType: string // #enumPersistentVolumeClaimConditionType

#enumPersistentVolumeClaimConditionType:
	#PersistentVolumeClaimResizing |
	#PersistentVolumeClaimFileSystemResizePending |
	#PersistentVolumeClaimControllerResizeError |
	#PersistentVolumeClaimNodeResizeError |
	#PersistentVolumeClaimVolumeModifyVolumeError |
	#PersistentVolumeClaimVolumeModifyingVolume |
	#PersistentVolumeClaimUnused

#PersistentVolumeClaimResizing: #PersistentVolumeClaimConditionType & "Resizing"

#PersistentVolumeClaimFileSystemResizePending: #PersistentVolumeClaimConditionType & "FileSystemResizePending"

#PersistentVolumeClaimControllerResizeError: #PersistentVolumeClaimConditionType & "ControllerResizeError"

#PersistentVolumeClaimNodeResizeError: #PersistentVolumeClaimConditionType & "NodeResizeError"

#PersistentVolumeClaimVolumeModifyVolumeError: #PersistentVolumeClaimConditionType & "ModifyVolumeError"

#PersistentVolumeClaimVolumeModifyingVolume: #PersistentVolumeClaimConditionType & "ModifyingVolume"

#PersistentVolumeClaimUnused: #PersistentVolumeClaimConditionType & "Unused"

#ClaimResourceStatus: string // #enumClaimResourceStatus

#enumClaimResourceStatus:
	#PersistentVolumeClaimControllerResizeInProgress |
	#PersistentVolumeClaimControllerResizeInfeasible |
	#PersistentVolumeClaimNodeResizePending |
	#PersistentVolumeClaimNodeResizeInProgress |
	#PersistentVolumeClaimNodeResizeInfeasible

#PersistentVolumeClaimControllerResizeInProgress: #ClaimResourceStatus & "ControllerResizeInProgress"

#PersistentVolumeClaimControllerResizeInfeasible: #ClaimResourceStatus & "ControllerResizeInfeasible"

#PersistentVolumeClaimNodeResizePending: #ClaimResourceStatus & "NodeResizePending"

#PersistentVolumeClaimNodeResizeInProgress: #ClaimResourceStatus & "NodeResizeInProgress"

#PersistentVolumeClaimNodeResizeInfeasible: #ClaimResourceStatus & "NodeResizeInfeasible"

#PersistentVolumeClaimModifyVolumeStatus: string // #enumPersistentVolumeClaimModifyVolumeStatus

#enumPersistentVolumeClaimModifyVolumeStatus:
	#PersistentVolumeClaimModifyVolumePending |
	#PersistentVolumeClaimModifyVolumeInProgress |
	#PersistentVolumeClaimModifyVolumeInfeasible

#PersistentVolumeClaimModifyVolumePending: #PersistentVolumeClaimModifyVolumeStatus & "Pending"

#PersistentVolumeClaimModifyVolumeInProgress: #PersistentVolumeClaimModifyVolumeStatus & "InProgress"

#PersistentVolumeClaimModifyVolumeInfeasible: #PersistentVolumeClaimModifyVolumeStatus & "Infeasible"

#ModifyVolumeStatus: {
	targetVolumeAttributesClassName?: string @go(TargetVolumeAttributesClassName) @protobuf(1,bytes,opt)

	status: #PersistentVolumeClaimModifyVolumeStatus @go(Status) @protobuf(2,bytes,opt,casttype=PersistentVolumeClaimModifyVolumeStatus)
}

#PersistentVolumeClaimCondition: {
	type: #PersistentVolumeClaimConditionType @go(Type) @protobuf(1,bytes,opt,casttype=PersistentVolumeClaimConditionType)

	status: #ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=ConditionStatus)

	lastProbeTime?: metav1.#Time @go(LastProbeTime) @protobuf(3,bytes,opt)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(4,bytes,opt)

	reason?: string @go(Reason) @protobuf(5,bytes,opt)

	message?: string @go(Message) @protobuf(6,bytes,opt)
}

#PersistentVolumeClaimStatus: {
	phase?: #PersistentVolumeClaimPhase @go(Phase) @protobuf(1,bytes,opt,casttype=PersistentVolumeClaimPhase)

	accessModes?: [...#PersistentVolumeAccessMode] @go(AccessModes,[]PersistentVolumeAccessMode) @protobuf(2,bytes,rep,casttype=PersistentVolumeAccessMode)

	capacity?: #ResourceList @go(Capacity) @protobuf(3,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	conditions?: [...#PersistentVolumeClaimCondition] @go(Conditions,[]PersistentVolumeClaimCondition) @protobuf(4,bytes,rep)

	allocatedResources?: #ResourceList @go(AllocatedResources) @protobuf(5,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	allocatedResourceStatuses?: {[string]: #ClaimResourceStatus} @go(AllocatedResourceStatuses,map[ResourceName]ClaimResourceStatus) @protobuf(7,bytes,rep)

	currentVolumeAttributesClassName?: string @go(CurrentVolumeAttributesClassName,*string) @protobuf(8,bytes,opt)

	modifyVolumeStatus?: #ModifyVolumeStatus @go(ModifyVolumeStatus,*ModifyVolumeStatus) @protobuf(9,bytes,opt)
}

#PersistentVolumeAccessMode: string // #enumPersistentVolumeAccessMode

#enumPersistentVolumeAccessMode:
	#ReadWriteOnce |
	#ReadOnlyMany |
	#ReadWriteMany |
	#ReadWriteOncePod

#ReadWriteOnce: #PersistentVolumeAccessMode & "ReadWriteOnce"

#ReadOnlyMany: #PersistentVolumeAccessMode & "ReadOnlyMany"

#ReadWriteMany: #PersistentVolumeAccessMode & "ReadWriteMany"

#ReadWriteOncePod: #PersistentVolumeAccessMode & "ReadWriteOncePod"

#PersistentVolumePhase: string // #enumPersistentVolumePhase

#enumPersistentVolumePhase:
	#VolumePending |
	#VolumeAvailable |
	#VolumeBound |
	#VolumeReleased |
	#VolumeFailed

#VolumePending: #PersistentVolumePhase & "Pending"

#VolumeAvailable: #PersistentVolumePhase & "Available"

#VolumeBound: #PersistentVolumePhase & "Bound"

#VolumeReleased: #PersistentVolumePhase & "Released"

#VolumeFailed: #PersistentVolumePhase & "Failed"

#PersistentVolumeClaimPhase: string // #enumPersistentVolumeClaimPhase

#enumPersistentVolumeClaimPhase:
	#ClaimPending |
	#ClaimBound |
	#ClaimLost

#ClaimPending: #PersistentVolumeClaimPhase & "Pending"

#ClaimBound: #PersistentVolumeClaimPhase & "Bound"

#ClaimLost: #PersistentVolumeClaimPhase & "Lost"

#HostPathType: string // #enumHostPathType

#enumHostPathType:
	#HostPathUnset |
	#HostPathDirectoryOrCreate |
	#HostPathDirectory |
	#HostPathFileOrCreate |
	#HostPathFile |
	#HostPathSocket |
	#HostPathCharDev |
	#HostPathBlockDev

#HostPathUnset: #HostPathType & ""

#HostPathDirectoryOrCreate: #HostPathType & "DirectoryOrCreate"

#HostPathDirectory: #HostPathType & "Directory"

#HostPathFileOrCreate: #HostPathType & "FileOrCreate"

#HostPathFile: #HostPathType & "File"

#HostPathSocket: #HostPathType & "Socket"

#HostPathCharDev: #HostPathType & "CharDevice"

#HostPathBlockDev: #HostPathType & "BlockDevice"

#HostPathVolumeSource: {
	path: string @go(Path) @protobuf(1,bytes,opt)

	type?: #HostPathType @go(Type,*HostPathType) @protobuf(2,bytes,opt)
}

#EmptyDirVolumeSource: {
	medium?: #StorageMedium @go(Medium) @protobuf(1,bytes,opt,casttype=StorageMedium)

	sizeLimit?: resource.#Quantity @go(SizeLimit,*resource.Quantity) @protobuf(2,bytes,opt)
}

#GlusterfsVolumeSource: {
	endpoints: string @go(EndpointsName) @protobuf(1,bytes,opt)

	path: string @go(Path) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)
}

#GlusterfsPersistentVolumeSource: {
	endpoints: string @go(EndpointsName) @protobuf(1,bytes,opt)

	path: string @go(Path) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)

	endpointsNamespace?: string @go(EndpointsNamespace,*string) @protobuf(4,bytes,opt)
}

#RBDVolumeSource: {
	monitors: [...string] @go(CephMonitors,[]string) @protobuf(1,bytes,rep)

	image: string @go(RBDImage) @protobuf(2,bytes,opt)

	fsType?: string @go(FSType) @protobuf(3,bytes,opt)

	pool?: string @go(RBDPool) @protobuf(4,bytes,opt)

	user?: string @go(RadosUser) @protobuf(5,bytes,opt)

	keyring?: string @go(Keyring) @protobuf(6,bytes,opt)

	secretRef?: #LocalObjectReference @go(SecretRef,*LocalObjectReference) @protobuf(7,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(8,varint,opt)
}

#RBDPersistentVolumeSource: {
	monitors: [...string] @go(CephMonitors,[]string) @protobuf(1,bytes,rep)

	image: string @go(RBDImage) @protobuf(2,bytes,opt)

	fsType?: string @go(FSType) @protobuf(3,bytes,opt)

	pool?: string @go(RBDPool) @protobuf(4,bytes,opt)

	user?: string @go(RadosUser) @protobuf(5,bytes,opt)

	keyring?: string @go(Keyring) @protobuf(6,bytes,opt)

	secretRef?: #SecretReference @go(SecretRef,*SecretReference) @protobuf(7,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(8,varint,opt)
}

#CinderVolumeSource: {
	volumeID: string @go(VolumeID) @protobuf(1,bytes,opt)

	fsType?: string @go(FSType) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)

	secretRef?: #LocalObjectReference @go(SecretRef,*LocalObjectReference) @protobuf(4,bytes,opt)
}

#CinderPersistentVolumeSource: {
	volumeID: string @go(VolumeID) @protobuf(1,bytes,opt)

	fsType?: string @go(FSType) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)

	secretRef?: #SecretReference @go(SecretRef,*SecretReference) @protobuf(4,bytes,opt)
}

#CephFSVolumeSource: {
	monitors: [...string] @go(Monitors,[]string) @protobuf(1,bytes,rep)

	path?: string @go(Path) @protobuf(2,bytes,opt)

	user?: string @go(User) @protobuf(3,bytes,opt)

	secretFile?: string @go(SecretFile) @protobuf(4,bytes,opt)

	secretRef?: #LocalObjectReference @go(SecretRef,*LocalObjectReference) @protobuf(5,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(6,varint,opt)
}

#SecretReference: {
	name?: string @go(Name) @protobuf(1,bytes,opt)

	namespace?: string @go(Namespace) @protobuf(2,bytes,opt)
}

#CephFSPersistentVolumeSource: {
	monitors: [...string] @go(Monitors,[]string) @protobuf(1,bytes,rep)

	path?: string @go(Path) @protobuf(2,bytes,opt)

	user?: string @go(User) @protobuf(3,bytes,opt)

	secretFile?: string @go(SecretFile) @protobuf(4,bytes,opt)

	secretRef?: #SecretReference @go(SecretRef,*SecretReference) @protobuf(5,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(6,varint,opt)
}

#FlockerVolumeSource: {
	datasetName?: string @go(DatasetName) @protobuf(1,bytes,opt)

	datasetUUID?: string @go(DatasetUUID) @protobuf(2,bytes,opt)
}

#StorageMedium: string // #enumStorageMedium

#enumStorageMedium:
	#StorageMediumDefault |
	#StorageMediumMemory |
	#StorageMediumHugePages |
	#StorageMediumHugePagesPrefix

#StorageMediumDefault:         #StorageMedium & ""
#StorageMediumMemory:          #StorageMedium & "Memory"
#StorageMediumHugePages:       #StorageMedium & "HugePages"
#StorageMediumHugePagesPrefix: #StorageMedium & "HugePages-"

#Protocol: string // #enumProtocol

#enumProtocol:
	#ProtocolTCP |
	#ProtocolUDP |
	#ProtocolSCTP

#ProtocolTCP: #Protocol & "TCP"

#ProtocolUDP: #Protocol & "UDP"

#ProtocolSCTP: #Protocol & "SCTP"

#GCEPersistentDiskVolumeSource: {
	pdName: string @go(PDName) @protobuf(1,bytes,opt)

	fsType?: string @go(FSType) @protobuf(2,bytes,opt)

	partition?: int32 @go(Partition) @protobuf(3,varint,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(4,varint,opt)
}

#QuobyteVolumeSource: {
	registry: string @go(Registry) @protobuf(1,bytes,opt)

	volume: string @go(Volume) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)

	user?: string @go(User) @protobuf(4,bytes,opt)

	group?: string @go(Group) @protobuf(5,bytes,opt)

	tenant?: string @go(Tenant) @protobuf(6,bytes,opt)
}

#FlexPersistentVolumeSource: {
	driver: string @go(Driver) @protobuf(1,bytes,opt)

	fsType?: string @go(FSType) @protobuf(2,bytes,opt)

	secretRef?: #SecretReference @go(SecretRef,*SecretReference) @protobuf(3,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(4,varint,opt)

	options?: {[string]: string} @go(Options,map[string]string) @protobuf(5,bytes,rep)
}

#FlexVolumeSource: {
	driver: string @go(Driver) @protobuf(1,bytes,opt)

	fsType?: string @go(FSType) @protobuf(2,bytes,opt)

	secretRef?: #LocalObjectReference @go(SecretRef,*LocalObjectReference) @protobuf(3,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(4,varint,opt)

	options?: {[string]: string} @go(Options,map[string]string) @protobuf(5,bytes,rep)
}

#AWSElasticBlockStoreVolumeSource: {
	volumeID: string @go(VolumeID) @protobuf(1,bytes,opt)

	fsType?: string @go(FSType) @protobuf(2,bytes,opt)

	partition?: int32 @go(Partition) @protobuf(3,varint,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(4,varint,opt)
}

#GitRepoVolumeSource: {
	repository: string @go(Repository) @protobuf(1,bytes,opt)

	revision?: string @go(Revision) @protobuf(2,bytes,opt)

	directory?: string @go(Directory) @protobuf(3,bytes,opt)
}

#SecretVolumeSource: {
	secretName?: string @go(SecretName) @protobuf(1,bytes,opt)

	items?: [...#KeyToPath] @go(Items,[]KeyToPath) @protobuf(2,bytes,rep)

	defaultMode?: int32 @go(DefaultMode,*int32) @protobuf(3,bytes,opt)

	optional?: bool @go(Optional,*bool) @protobuf(4,varint,opt)
}

#SecretVolumeSourceDefaultMode: int32 & 0o644

#SecretProjection: {
	#LocalObjectReference

	items?: [...#KeyToPath] @go(Items,[]KeyToPath) @protobuf(2,bytes,rep)

	optional?: bool @go(Optional,*bool) @protobuf(4,varint,opt)
}

#NFSVolumeSource: {
	server: string @go(Server) @protobuf(1,bytes,opt)

	path: string @go(Path) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)
}

#ISCSIVolumeSource: {
	targetPortal: string @go(TargetPortal) @protobuf(1,bytes,opt)

	iqn: string @go(IQN) @protobuf(2,bytes,opt)

	lun: int32 @go(Lun) @protobuf(3,varint,opt)

	iscsiInterface?: string @go(ISCSIInterface) @protobuf(4,bytes,opt)

	fsType?: string @go(FSType) @protobuf(5,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(6,varint,opt)

	portals?: [...string] @go(Portals,[]string) @protobuf(7,bytes,opt)

	chapAuthDiscovery?: bool @go(DiscoveryCHAPAuth) @protobuf(8,varint,opt)

	chapAuthSession?: bool @go(SessionCHAPAuth) @protobuf(11,varint,opt)

	secretRef?: #LocalObjectReference @go(SecretRef,*LocalObjectReference) @protobuf(10,bytes,opt)

	initiatorName?: string @go(InitiatorName,*string) @protobuf(12,bytes,opt)
}

#ISCSIPersistentVolumeSource: {
	targetPortal: string @go(TargetPortal) @protobuf(1,bytes,opt)

	iqn: string @go(IQN) @protobuf(2,bytes,opt)

	lun: int32 @go(Lun) @protobuf(3,varint,opt)

	iscsiInterface?: string @go(ISCSIInterface) @protobuf(4,bytes,opt)

	fsType?: string @go(FSType) @protobuf(5,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(6,varint,opt)

	portals?: [...string] @go(Portals,[]string) @protobuf(7,bytes,opt)

	chapAuthDiscovery?: bool @go(DiscoveryCHAPAuth) @protobuf(8,varint,opt)

	chapAuthSession?: bool @go(SessionCHAPAuth) @protobuf(11,varint,opt)

	secretRef?: #SecretReference @go(SecretRef,*SecretReference) @protobuf(10,bytes,opt)

	initiatorName?: string @go(InitiatorName,*string) @protobuf(12,bytes,opt)
}

#FCVolumeSource: {
	targetWWNs?: [...string] @go(TargetWWNs,[]string) @protobuf(1,bytes,rep)

	lun?: int32 @go(Lun,*int32) @protobuf(2,varint,opt)

	fsType?: string @go(FSType) @protobuf(3,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(4,varint,opt)

	wwids?: [...string] @go(WWIDs,[]string) @protobuf(5,bytes,rep)
}

#AzureFileVolumeSource: {
	secretName: string @go(SecretName) @protobuf(1,bytes,opt)

	shareName: string @go(ShareName) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)
}

#AzureFilePersistentVolumeSource: {
	secretName: string @go(SecretName) @protobuf(1,bytes,opt)

	shareName: string @go(ShareName) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)

	secretNamespace?: string @go(SecretNamespace,*string) @protobuf(4,bytes,opt)
}

#VsphereVirtualDiskVolumeSource: {
	volumePath: string @go(VolumePath) @protobuf(1,bytes,opt)

	fsType?: string @go(FSType) @protobuf(2,bytes,opt)

	storagePolicyName?: string @go(StoragePolicyName) @protobuf(3,bytes,opt)

	storagePolicyID?: string @go(StoragePolicyID) @protobuf(4,bytes,opt)
}

#PhotonPersistentDiskVolumeSource: {
	pdID: string @go(PdID) @protobuf(1,bytes,opt)

	fsType?: string @go(FSType) @protobuf(2,bytes,opt)
}

#AzureDataDiskCachingMode: string // #enumAzureDataDiskCachingMode

#enumAzureDataDiskCachingMode:
	#AzureDataDiskCachingNone |
	#AzureDataDiskCachingReadOnly |
	#AzureDataDiskCachingReadWrite

#AzureDataDiskKind: string // #enumAzureDataDiskKind

#enumAzureDataDiskKind:
	#AzureSharedBlobDisk |
	#AzureDedicatedBlobDisk |
	#AzureManagedDisk

#AzureDataDiskCachingNone:      #AzureDataDiskCachingMode & "None"
#AzureDataDiskCachingReadOnly:  #AzureDataDiskCachingMode & "ReadOnly"
#AzureDataDiskCachingReadWrite: #AzureDataDiskCachingMode & "ReadWrite"
#AzureSharedBlobDisk:           #AzureDataDiskKind & "Shared"
#AzureDedicatedBlobDisk:        #AzureDataDiskKind & "Dedicated"
#AzureManagedDisk:              #AzureDataDiskKind & "Managed"

#AzureDiskVolumeSource: {
	diskName: string @go(DiskName) @protobuf(1,bytes,opt)

	diskURI: string @go(DataDiskURI) @protobuf(2,bytes,opt)

	cachingMode?: #AzureDataDiskCachingMode @go(CachingMode,*AzureDataDiskCachingMode) @protobuf(3,bytes,opt,casttype=AzureDataDiskCachingMode)

	fsType?: string @go(FSType,*string) @protobuf(4,bytes,opt)

	readOnly?: bool @go(ReadOnly,*bool) @protobuf(5,varint,opt)

	kind?: #AzureDataDiskKind @go(Kind,*AzureDataDiskKind) @protobuf(6,bytes,opt,casttype=AzureDataDiskKind)
}

#PortworxVolumeSource: {
	volumeID: string @go(VolumeID) @protobuf(1,bytes,opt)

	fsType?: string @go(FSType) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)
}

#ScaleIOVolumeSource: {
	gateway: string @go(Gateway) @protobuf(1,bytes,opt)

	system: string @go(System) @protobuf(2,bytes,opt)

	secretRef?: #LocalObjectReference @go(SecretRef,*LocalObjectReference) @protobuf(3,bytes,opt)

	sslEnabled?: bool @go(SSLEnabled) @protobuf(4,varint,opt)

	protectionDomain?: string @go(ProtectionDomain) @protobuf(5,bytes,opt)

	storagePool?: string @go(StoragePool) @protobuf(6,bytes,opt)

	storageMode?: string @go(StorageMode) @protobuf(7,bytes,opt)

	volumeName?: string @go(VolumeName) @protobuf(8,bytes,opt)

	fsType?: string @go(FSType) @protobuf(9,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(10,varint,opt)
}

#ScaleIOPersistentVolumeSource: {
	gateway: string @go(Gateway) @protobuf(1,bytes,opt)

	system: string @go(System) @protobuf(2,bytes,opt)

	secretRef?: #SecretReference @go(SecretRef,*SecretReference) @protobuf(3,bytes,opt)

	sslEnabled?: bool @go(SSLEnabled) @protobuf(4,varint,opt)

	protectionDomain?: string @go(ProtectionDomain) @protobuf(5,bytes,opt)

	storagePool?: string @go(StoragePool) @protobuf(6,bytes,opt)

	storageMode?: string @go(StorageMode) @protobuf(7,bytes,opt)

	volumeName?: string @go(VolumeName) @protobuf(8,bytes,opt)

	fsType?: string @go(FSType) @protobuf(9,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(10,varint,opt)
}

#StorageOSVolumeSource: {
	volumeName?: string @go(VolumeName) @protobuf(1,bytes,opt)

	volumeNamespace?: string @go(VolumeNamespace) @protobuf(2,bytes,opt)

	fsType?: string @go(FSType) @protobuf(3,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(4,varint,opt)

	secretRef?: #LocalObjectReference @go(SecretRef,*LocalObjectReference) @protobuf(5,bytes,opt)
}

#StorageOSPersistentVolumeSource: {
	volumeName?: string @go(VolumeName) @protobuf(1,bytes,opt)

	volumeNamespace?: string @go(VolumeNamespace) @protobuf(2,bytes,opt)

	fsType?: string @go(FSType) @protobuf(3,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(4,varint,opt)

	secretRef?: #ObjectReference @go(SecretRef,*ObjectReference) @protobuf(5,bytes,opt)
}

#ConfigMapVolumeSource: {
	#LocalObjectReference

	items?: [...#KeyToPath] @go(Items,[]KeyToPath) @protobuf(2,bytes,rep)

	defaultMode?: int32 @go(DefaultMode,*int32) @protobuf(3,varint,opt)

	optional?: bool @go(Optional,*bool) @protobuf(4,varint,opt)
}

#ConfigMapVolumeSourceDefaultMode: int32 & 0o644

#ConfigMapProjection: {
	#LocalObjectReference

	items?: [...#KeyToPath] @go(Items,[]KeyToPath) @protobuf(2,bytes,rep)

	optional?: bool @go(Optional,*bool) @protobuf(4,varint,opt)
}

#ServiceAccountTokenProjection: {
	audience?: string @go(Audience) @protobuf(1,bytes,rep)

	expirationSeconds?: int64 @go(ExpirationSeconds,*int64) @protobuf(2,varint,opt)

	path: string @go(Path) @protobuf(3,bytes,opt)
}

#ClusterTrustBundleProjection: {
	name?: string @go(Name,*string) @protobuf(1,bytes,rep)

	signerName?: string @go(SignerName,*string) @protobuf(2,bytes,rep)

	labelSelector?: metav1.#LabelSelector @go(LabelSelector,*metav1.LabelSelector) @protobuf(3,bytes,rep)

	optional?: bool @go(Optional,*bool) @protobuf(5,varint,opt)

	path: string @go(Path) @protobuf(4,bytes,rep)
}

#PodCertificateProjection: {
	signerName: string @go(SignerName) @protobuf(1,bytes,rep)

	keyType: string @go(KeyType) @protobuf(2,bytes,rep)

	maxExpirationSeconds?: int32 @go(MaxExpirationSeconds,*int32) @protobuf(3,varint,opt)

	credentialBundlePath?: string @go(CredentialBundlePath) @protobuf(4,bytes,rep)

	keyPath?: string @go(KeyPath) @protobuf(5,bytes,rep)

	certificateChainPath?: string @go(CertificateChainPath) @protobuf(6,bytes,rep)

	userAnnotations?: {[string]: string} @go(UserAnnotations,map[string]string) @protobuf(7,bytes,rep)
}

#ProjectedVolumeSource: {
	sources?: [...#VolumeProjection] @go(Sources,[]VolumeProjection) @protobuf(1,bytes,rep)

	defaultMode?: int32 @go(DefaultMode,*int32) @protobuf(2,varint,opt)
}

#VolumeProjection: {
	secret?: #SecretProjection @go(Secret,*SecretProjection) @protobuf(1,bytes,opt)

	downwardAPI?: #DownwardAPIProjection @go(DownwardAPI,*DownwardAPIProjection) @protobuf(2,bytes,opt)

	configMap?: #ConfigMapProjection @go(ConfigMap,*ConfigMapProjection) @protobuf(3,bytes,opt)

	serviceAccountToken?: #ServiceAccountTokenProjection @go(ServiceAccountToken,*ServiceAccountTokenProjection) @protobuf(4,bytes,opt)

	clusterTrustBundle?: #ClusterTrustBundleProjection @go(ClusterTrustBundle,*ClusterTrustBundleProjection) @protobuf(5,bytes,opt)

	podCertificate?: #PodCertificateProjection @go(PodCertificate,*PodCertificateProjection) @protobuf(6,bytes,opt)
}

#ProjectedVolumeSourceDefaultMode: int32 & 0o644

#KeyToPath: {
	key: string @go(Key) @protobuf(1,bytes,opt)

	path: string @go(Path) @protobuf(2,bytes,opt)

	mode?: int32 @go(Mode,*int32) @protobuf(3,varint,opt)
}

#LocalVolumeSource: {
	path: string @go(Path) @protobuf(1,bytes,opt)

	fsType?: string @go(FSType,*string) @protobuf(2,bytes,opt)
}

#CSIPersistentVolumeSource: {
	driver: string @go(Driver) @protobuf(1,bytes,opt)

	volumeHandle: string @go(VolumeHandle) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)

	fsType?: string @go(FSType) @protobuf(4,bytes,opt)

	volumeAttributes?: {[string]: string} @go(VolumeAttributes,map[string]string) @protobuf(5,bytes,rep)

	controllerPublishSecretRef?: #SecretReference @go(ControllerPublishSecretRef,*SecretReference) @protobuf(6,bytes,opt)

	nodeStageSecretRef?: #SecretReference @go(NodeStageSecretRef,*SecretReference) @protobuf(7,bytes,opt)

	nodePublishSecretRef?: #SecretReference @go(NodePublishSecretRef,*SecretReference) @protobuf(8,bytes,opt)

	controllerExpandSecretRef?: #SecretReference @go(ControllerExpandSecretRef,*SecretReference) @protobuf(9,bytes,opt)

	nodeExpandSecretRef?: #SecretReference @go(NodeExpandSecretRef,*SecretReference) @protobuf(10,bytes,opt)
}

#CSIVolumeSource: {
	driver: string @go(Driver) @protobuf(1,bytes,opt)

	readOnly?: bool @go(ReadOnly,*bool) @protobuf(2,varint,opt)

	fsType?: string @go(FSType,*string) @protobuf(3,bytes,opt)

	volumeAttributes?: {[string]: string} @go(VolumeAttributes,map[string]string) @protobuf(4,bytes,rep)

	nodePublishSecretRef?: #LocalObjectReference @go(NodePublishSecretRef,*LocalObjectReference) @protobuf(5,bytes,opt)
}

#EphemeralVolumeSource: {
	volumeClaimTemplate?: #PersistentVolumeClaimTemplate @go(VolumeClaimTemplate,*PersistentVolumeClaimTemplate) @protobuf(1,bytes,opt)
}

#PersistentVolumeClaimTemplate: {
	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec: #PersistentVolumeClaimSpec @go(Spec) @protobuf(2,bytes)
}

#ContainerPort: {
	name?: string @go(Name) @protobuf(1,bytes,opt)

	hostPort?: int32 @go(HostPort) @protobuf(2,varint,opt)

	containerPort: int32 @go(ContainerPort) @protobuf(3,varint,opt)

	protocol?: #Protocol @go(Protocol) @protobuf(4,bytes,opt,casttype=Protocol)

	hostIP?: string @go(HostIP) @protobuf(5,bytes,opt)
}

#VolumeMount: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(2,varint,opt)

	recursiveReadOnly?: #RecursiveReadOnlyMode @go(RecursiveReadOnly,*RecursiveReadOnlyMode) @protobuf(7,bytes,opt,casttype=RecursiveReadOnlyMode)

	mountPath: string @go(MountPath) @protobuf(3,bytes,opt)

	subPath?: string @go(SubPath) @protobuf(4,bytes,opt)

	mountPropagation?: #MountPropagationMode @go(MountPropagation,*MountPropagationMode) @protobuf(5,bytes,opt,casttype=MountPropagationMode)

	subPathExpr?: string @go(SubPathExpr) @protobuf(6,bytes,opt)
}

#MountPropagationMode: string // #enumMountPropagationMode

#enumMountPropagationMode:
	#MountPropagationNone |
	#MountPropagationHostToContainer |
	#MountPropagationBidirectional

#MountPropagationNone: #MountPropagationMode & "None"

#MountPropagationHostToContainer: #MountPropagationMode & "HostToContainer"

#MountPropagationBidirectional: #MountPropagationMode & "Bidirectional"

#RecursiveReadOnlyMode: string // #enumRecursiveReadOnlyMode

#enumRecursiveReadOnlyMode:
	#RecursiveReadOnlyDisabled |
	#RecursiveReadOnlyIfPossible |
	#RecursiveReadOnlyEnabled

#RecursiveReadOnlyDisabled: #RecursiveReadOnlyMode & "Disabled"

#RecursiveReadOnlyIfPossible: #RecursiveReadOnlyMode & "IfPossible"

#RecursiveReadOnlyEnabled: #RecursiveReadOnlyMode & "Enabled"

#VolumeDevice: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	devicePath: string @go(DevicePath) @protobuf(2,bytes,opt)
}

#EnvVar: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	value?: string @go(Value) @protobuf(2,bytes,opt)

	valueFrom?: #EnvVarSource @go(ValueFrom,*EnvVarSource) @protobuf(3,bytes,opt)
}

#EnvVarSource: {
	fieldRef?: #ObjectFieldSelector @go(FieldRef,*ObjectFieldSelector) @protobuf(1,bytes,opt)

	resourceFieldRef?: #ResourceFieldSelector @go(ResourceFieldRef,*ResourceFieldSelector) @protobuf(2,bytes,opt)

	configMapKeyRef?: #ConfigMapKeySelector @go(ConfigMapKeyRef,*ConfigMapKeySelector) @protobuf(3,bytes,opt)

	secretKeyRef?: #SecretKeySelector @go(SecretKeyRef,*SecretKeySelector) @protobuf(4,bytes,opt)

	fileKeyRef?: #FileKeySelector @go(FileKeyRef,*FileKeySelector) @protobuf(5,bytes,opt)
}

#FileKeySelector: {
	volumeName: string @go(VolumeName) @protobuf(1,bytes,opt)

	path: string @go(Path) @protobuf(2,bytes,opt)

	key: string @go(Key) @protobuf(3,bytes,opt)

	optional?: bool @go(Optional,*bool) @protobuf(4,varint,opt)
}

#ObjectFieldSelector: {
	apiVersion?: string @go(APIVersion) @protobuf(1,bytes,opt)

	fieldPath: string @go(FieldPath) @protobuf(2,bytes,opt)
}

#ResourceFieldSelector: {
	containerName?: string @go(ContainerName) @protobuf(1,bytes,opt)

	resource: string @go(Resource) @protobuf(2,bytes,opt)

	divisor?: resource_9.#Quantity @go(Divisor) @protobuf(3,bytes,opt)
}

#ConfigMapKeySelector: {
	#LocalObjectReference

	key: string @go(Key) @protobuf(2,bytes,opt)

	optional?: bool @go(Optional,*bool) @protobuf(3,varint,opt)
}

#SecretKeySelector: {
	#LocalObjectReference

	key: string @go(Key) @protobuf(2,bytes,opt)

	optional?: bool @go(Optional,*bool) @protobuf(3,varint,opt)
}

#EnvFromSource: {
	prefix?: string @go(Prefix) @protobuf(1,bytes,opt)

	configMapRef?: #ConfigMapEnvSource @go(ConfigMapRef,*ConfigMapEnvSource) @protobuf(2,bytes,opt)

	secretRef?: #SecretEnvSource @go(SecretRef,*SecretEnvSource) @protobuf(3,bytes,opt)
}

#ConfigMapEnvSource: {
	#LocalObjectReference

	optional?: bool @go(Optional,*bool) @protobuf(2,varint,opt)
}

#SecretEnvSource: {
	#LocalObjectReference

	optional?: bool @go(Optional,*bool) @protobuf(2,varint,opt)
}

#HTTPHeader: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	value: string @go(Value) @protobuf(2,bytes,opt)
}

#HTTPGetAction: {
	path?: string @go(Path) @protobuf(1,bytes,opt)

	port: intstr.#IntOrString @go(Port) @protobuf(2,bytes,opt)

	host?: string @go(Host) @protobuf(3,bytes,opt)

	scheme?: #URIScheme @go(Scheme) @protobuf(4,bytes,opt,casttype=URIScheme)

	httpHeaders?: [...#HTTPHeader] @go(HTTPHeaders,[]HTTPHeader) @protobuf(5,bytes,rep)
}

#URIScheme: string // #enumURIScheme

#enumURIScheme:
	#URISchemeHTTP |
	#URISchemeHTTPS

#URISchemeHTTP: #URIScheme & "HTTP"

#URISchemeHTTPS: #URIScheme & "HTTPS"

#TCPSocketAction: {
	port: intstr.#IntOrString @go(Port) @protobuf(1,bytes,opt)

	host?: string @go(Host) @protobuf(2,bytes,opt)
}

#GRPCAction: {
	port: int32 @go(Port) @protobuf(1,bytes,opt)

	service?: string @go(Service,*string) @protobuf(2,bytes,opt)
}

#ExecAction: {
	command?: [...string] @go(Command,[]string) @protobuf(1,bytes,rep)
}

#SleepAction: {
	seconds: int64 @go(Seconds) @protobuf(1,bytes,opt)
}

#Probe: {
	#ProbeHandler

	initialDelaySeconds?: int32 @go(InitialDelaySeconds) @protobuf(2,varint,opt)

	timeoutSeconds?: int32 @go(TimeoutSeconds) @protobuf(3,varint,opt)

	periodSeconds?: int32 @go(PeriodSeconds) @protobuf(4,varint,opt)

	successThreshold?: int32 @go(SuccessThreshold) @protobuf(5,varint,opt)

	failureThreshold?: int32 @go(FailureThreshold) @protobuf(6,varint,opt)

	terminationGracePeriodSeconds?: int64 @go(TerminationGracePeriodSeconds,*int64) @protobuf(7,varint,opt)
}

#PullPolicy: string // #enumPullPolicy

#enumPullPolicy:
	#PullAlways |
	#PullNever |
	#PullIfNotPresent

#PullAlways: #PullPolicy & "Always"

#PullNever: #PullPolicy & "Never"

#PullIfNotPresent: #PullPolicy & "IfNotPresent"

#ResourceResizeRestartPolicy: string // #enumResourceResizeRestartPolicy

#enumResourceResizeRestartPolicy:
	#NotRequired |
	#RestartContainer

#NotRequired: #ResourceResizeRestartPolicy & "NotRequired"

#RestartContainer: #ResourceResizeRestartPolicy & "RestartContainer"

#ContainerResizePolicy: {
	resourceName: #ResourceName @go(ResourceName) @protobuf(1,bytes,opt,casttype=ResourceName)

	restartPolicy: #ResourceResizeRestartPolicy @go(RestartPolicy) @protobuf(2,bytes,opt,casttype=ResourceResizeRestartPolicy)
}

#PreemptionPolicy: string // #enumPreemptionPolicy

#enumPreemptionPolicy:
	#PreemptLowerPriority |
	#PreemptNever

#PreemptLowerPriority: #PreemptionPolicy & "PreemptLowerPriority"

#PreemptNever: #PreemptionPolicy & "Never"

#TerminationMessagePolicy: string // #enumTerminationMessagePolicy

#enumTerminationMessagePolicy:
	#TerminationMessageReadFile |
	#TerminationMessageFallbackToLogsOnError

#TerminationMessageReadFile: #TerminationMessagePolicy & "File"

#TerminationMessageFallbackToLogsOnError: #TerminationMessagePolicy & "FallbackToLogsOnError"

#Capability: string

#Capabilities: {
	add?: [...#Capability] @go(Add,[]Capability) @protobuf(1,bytes,rep,casttype=Capability)

	drop?: [...#Capability] @go(Drop,[]Capability) @protobuf(2,bytes,rep,casttype=Capability)
}

#ResourceRequirements: {
	limits?: #ResourceList @go(Limits) @protobuf(1,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	requests?: #ResourceList @go(Requests) @protobuf(2,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	claims?: [...#ResourceClaim] @go(Claims,[]ResourceClaim) @protobuf(3,bytes,opt)
}

#VolumeResourceRequirements: {
	limits?: #ResourceList @go(Limits) @protobuf(1,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	requests?: #ResourceList @go(Requests) @protobuf(2,bytes,rep,casttype=ResourceList,castkey=ResourceName)
}

#ResourceClaim: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	request?: string @go(Request) @protobuf(2,bytes,opt)
}

#TerminationMessagePathDefault: "/dev/termination-log"

#Container: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	image?: string @go(Image) @protobuf(2,bytes,opt)

	command?: [...string] @go(Command,[]string) @protobuf(3,bytes,rep)

	args?: [...string] @go(Args,[]string) @protobuf(4,bytes,rep)

	workingDir?: string @go(WorkingDir) @protobuf(5,bytes,opt)

	ports?: [...#ContainerPort] @go(Ports,[]ContainerPort) @protobuf(6,bytes,rep)

	envFrom?: [...#EnvFromSource] @go(EnvFrom,[]EnvFromSource) @protobuf(19,bytes,rep)

	env?: [...#EnvVar] @go(Env,[]EnvVar) @protobuf(7,bytes,rep)

	resources?: #ResourceRequirements @go(Resources) @protobuf(8,bytes,opt)

	resizePolicy?: [...#ContainerResizePolicy] @go(ResizePolicy,[]ContainerResizePolicy) @protobuf(23,bytes,rep)

	restartPolicy?: #ContainerRestartPolicy @go(RestartPolicy,*ContainerRestartPolicy) @protobuf(24,bytes,opt,casttype=ContainerRestartPolicy)

	restartPolicyRules?: [...#ContainerRestartRule] @go(RestartPolicyRules,[]ContainerRestartRule) @protobuf(25,bytes,rep)

	volumeMounts?: [...#VolumeMount] @go(VolumeMounts,[]VolumeMount) @protobuf(9,bytes,rep)

	volumeDevices?: [...#VolumeDevice] @go(VolumeDevices,[]VolumeDevice) @protobuf(21,bytes,rep)

	livenessProbe?: #Probe @go(LivenessProbe,*Probe) @protobuf(10,bytes,opt)

	readinessProbe?: #Probe @go(ReadinessProbe,*Probe) @protobuf(11,bytes,opt)

	startupProbe?: #Probe @go(StartupProbe,*Probe) @protobuf(22,bytes,opt)

	lifecycle?: #Lifecycle @go(Lifecycle,*Lifecycle) @protobuf(12,bytes,opt)

	terminationMessagePath?: string @go(TerminationMessagePath) @protobuf(13,bytes,opt)

	terminationMessagePolicy?: #TerminationMessagePolicy @go(TerminationMessagePolicy) @protobuf(20,bytes,opt,casttype=TerminationMessagePolicy)

	imagePullPolicy?: #PullPolicy @go(ImagePullPolicy) @protobuf(14,bytes,opt,casttype=PullPolicy)

	securityContext?: #SecurityContext @go(SecurityContext,*SecurityContext) @protobuf(15,bytes,opt)

	stdin?: bool @go(Stdin) @protobuf(16,varint,opt)

	stdinOnce?: bool @go(StdinOnce) @protobuf(17,varint,opt)

	tty?: bool @go(TTY) @protobuf(18,varint,opt)
}

#ProbeHandler: {
	exec?: #ExecAction @go(Exec,*ExecAction) @protobuf(1,bytes,opt)

	httpGet?: #HTTPGetAction @go(HTTPGet,*HTTPGetAction) @protobuf(2,bytes,opt)

	tcpSocket?: #TCPSocketAction @go(TCPSocket,*TCPSocketAction) @protobuf(3,bytes,opt)

	grpc?: #GRPCAction @go(GRPC,*GRPCAction) @protobuf(4,bytes,opt)
}

#LifecycleHandler: {
	exec?: #ExecAction @go(Exec,*ExecAction) @protobuf(1,bytes,opt)

	httpGet?: #HTTPGetAction @go(HTTPGet,*HTTPGetAction) @protobuf(2,bytes,opt)

	tcpSocket?: #TCPSocketAction @go(TCPSocket,*TCPSocketAction) @protobuf(3,bytes,opt)

	sleep?: #SleepAction @go(Sleep,*SleepAction) @protobuf(4,bytes,opt)
}

#Signal: string // #enumSignal

#enumSignal:
	#SIGABRT |
	#SIGALRM |
	#SIGBUS |
	#SIGCHLD |
	#SIGCLD |
	#SIGCONT |
	#SIGFPE |
	#SIGHUP |
	#SIGILL |
	#SIGINT |
	#SIGIO |
	#SIGIOT |
	#SIGKILL |
	#SIGPIPE |
	#SIGPOLL |
	#SIGPROF |
	#SIGPWR |
	#SIGQUIT |
	#SIGSEGV |
	#SIGSTKFLT |
	#SIGSTOP |
	#SIGSYS |
	#SIGTERM |
	#SIGTRAP |
	#SIGTSTP |
	#SIGTTIN |
	#SIGTTOU |
	#SIGURG |
	#SIGUSR1 |
	#SIGUSR2 |
	#SIGVTALRM |
	#SIGWINCH |
	#SIGXCPU |
	#SIGXFSZ |
	#SIGRTMIN |
	#SIGRTMINPLUS1 |
	#SIGRTMINPLUS2 |
	#SIGRTMINPLUS3 |
	#SIGRTMINPLUS4 |
	#SIGRTMINPLUS5 |
	#SIGRTMINPLUS6 |
	#SIGRTMINPLUS7 |
	#SIGRTMINPLUS8 |
	#SIGRTMINPLUS9 |
	#SIGRTMINPLUS10 |
	#SIGRTMINPLUS11 |
	#SIGRTMINPLUS12 |
	#SIGRTMINPLUS13 |
	#SIGRTMINPLUS14 |
	#SIGRTMINPLUS15 |
	#SIGRTMAXMINUS14 |
	#SIGRTMAXMINUS13 |
	#SIGRTMAXMINUS12 |
	#SIGRTMAXMINUS11 |
	#SIGRTMAXMINUS10 |
	#SIGRTMAXMINUS9 |
	#SIGRTMAXMINUS8 |
	#SIGRTMAXMINUS7 |
	#SIGRTMAXMINUS6 |
	#SIGRTMAXMINUS5 |
	#SIGRTMAXMINUS4 |
	#SIGRTMAXMINUS3 |
	#SIGRTMAXMINUS2 |
	#SIGRTMAXMINUS1 |
	#SIGRTMAX

#SIGABRT:         #Signal & "SIGABRT"
#SIGALRM:         #Signal & "SIGALRM"
#SIGBUS:          #Signal & "SIGBUS"
#SIGCHLD:         #Signal & "SIGCHLD"
#SIGCLD:          #Signal & "SIGCLD"
#SIGCONT:         #Signal & "SIGCONT"
#SIGFPE:          #Signal & "SIGFPE"
#SIGHUP:          #Signal & "SIGHUP"
#SIGILL:          #Signal & "SIGILL"
#SIGINT:          #Signal & "SIGINT"
#SIGIO:           #Signal & "SIGIO"
#SIGIOT:          #Signal & "SIGIOT"
#SIGKILL:         #Signal & "SIGKILL"
#SIGPIPE:         #Signal & "SIGPIPE"
#SIGPOLL:         #Signal & "SIGPOLL"
#SIGPROF:         #Signal & "SIGPROF"
#SIGPWR:          #Signal & "SIGPWR"
#SIGQUIT:         #Signal & "SIGQUIT"
#SIGSEGV:         #Signal & "SIGSEGV"
#SIGSTKFLT:       #Signal & "SIGSTKFLT"
#SIGSTOP:         #Signal & "SIGSTOP"
#SIGSYS:          #Signal & "SIGSYS"
#SIGTERM:         #Signal & "SIGTERM"
#SIGTRAP:         #Signal & "SIGTRAP"
#SIGTSTP:         #Signal & "SIGTSTP"
#SIGTTIN:         #Signal & "SIGTTIN"
#SIGTTOU:         #Signal & "SIGTTOU"
#SIGURG:          #Signal & "SIGURG"
#SIGUSR1:         #Signal & "SIGUSR1"
#SIGUSR2:         #Signal & "SIGUSR2"
#SIGVTALRM:       #Signal & "SIGVTALRM"
#SIGWINCH:        #Signal & "SIGWINCH"
#SIGXCPU:         #Signal & "SIGXCPU"
#SIGXFSZ:         #Signal & "SIGXFSZ"
#SIGRTMIN:        #Signal & "SIGRTMIN"
#SIGRTMINPLUS1:   #Signal & "SIGRTMIN+1"
#SIGRTMINPLUS2:   #Signal & "SIGRTMIN+2"
#SIGRTMINPLUS3:   #Signal & "SIGRTMIN+3"
#SIGRTMINPLUS4:   #Signal & "SIGRTMIN+4"
#SIGRTMINPLUS5:   #Signal & "SIGRTMIN+5"
#SIGRTMINPLUS6:   #Signal & "SIGRTMIN+6"
#SIGRTMINPLUS7:   #Signal & "SIGRTMIN+7"
#SIGRTMINPLUS8:   #Signal & "SIGRTMIN+8"
#SIGRTMINPLUS9:   #Signal & "SIGRTMIN+9"
#SIGRTMINPLUS10:  #Signal & "SIGRTMIN+10"
#SIGRTMINPLUS11:  #Signal & "SIGRTMIN+11"
#SIGRTMINPLUS12:  #Signal & "SIGRTMIN+12"
#SIGRTMINPLUS13:  #Signal & "SIGRTMIN+13"
#SIGRTMINPLUS14:  #Signal & "SIGRTMIN+14"
#SIGRTMINPLUS15:  #Signal & "SIGRTMIN+15"
#SIGRTMAXMINUS14: #Signal & "SIGRTMAX-14"
#SIGRTMAXMINUS13: #Signal & "SIGRTMAX-13"
#SIGRTMAXMINUS12: #Signal & "SIGRTMAX-12"
#SIGRTMAXMINUS11: #Signal & "SIGRTMAX-11"
#SIGRTMAXMINUS10: #Signal & "SIGRTMAX-10"
#SIGRTMAXMINUS9:  #Signal & "SIGRTMAX-9"
#SIGRTMAXMINUS8:  #Signal & "SIGRTMAX-8"
#SIGRTMAXMINUS7:  #Signal & "SIGRTMAX-7"
#SIGRTMAXMINUS6:  #Signal & "SIGRTMAX-6"
#SIGRTMAXMINUS5:  #Signal & "SIGRTMAX-5"
#SIGRTMAXMINUS4:  #Signal & "SIGRTMAX-4"
#SIGRTMAXMINUS3:  #Signal & "SIGRTMAX-3"
#SIGRTMAXMINUS2:  #Signal & "SIGRTMAX-2"
#SIGRTMAXMINUS1:  #Signal & "SIGRTMAX-1"
#SIGRTMAX:        #Signal & "SIGRTMAX"

#Lifecycle: {
	postStart?: #LifecycleHandler @go(PostStart,*LifecycleHandler) @protobuf(1,bytes,opt)

	preStop?: #LifecycleHandler @go(PreStop,*LifecycleHandler) @protobuf(2,bytes,opt)

	stopSignal?: #Signal @go(StopSignal,*Signal) @protobuf(3,bytes,opt)
}

#ConditionStatus: string // #enumConditionStatus

#enumConditionStatus:
	#ConditionTrue |
	#ConditionFalse |
	#ConditionUnknown

#ConditionTrue:    #ConditionStatus & "True"
#ConditionFalse:   #ConditionStatus & "False"
#ConditionUnknown: #ConditionStatus & "Unknown"

#ContainerStateWaiting: {
	reason?: string @go(Reason) @protobuf(1,bytes,opt)

	message?: string @go(Message) @protobuf(2,bytes,opt)
}

#ContainerStateRunning: {
	startedAt?: metav1.#Time @go(StartedAt) @protobuf(1,bytes,opt)
}

#ContainerStateTerminated: {
	exitCode: int32 @go(ExitCode) @protobuf(1,varint,opt)

	signal?: int32 @go(Signal) @protobuf(2,varint,opt)

	reason?: string @go(Reason) @protobuf(3,bytes,opt)

	message?: string @go(Message) @protobuf(4,bytes,opt)

	startedAt?: metav1.#Time @go(StartedAt) @protobuf(5,bytes,opt)

	finishedAt?: metav1.#Time @go(FinishedAt) @protobuf(6,bytes,opt)

	containerID?: string @go(ContainerID) @protobuf(7,bytes,opt)
}

#ContainerState: {
	waiting?: #ContainerStateWaiting @go(Waiting,*ContainerStateWaiting) @protobuf(1,bytes,opt)

	running?: #ContainerStateRunning @go(Running,*ContainerStateRunning) @protobuf(2,bytes,opt)

	terminated?: #ContainerStateTerminated @go(Terminated,*ContainerStateTerminated) @protobuf(3,bytes,opt)
}

#ContainerStatus: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	state?: #ContainerState @go(State) @protobuf(2,bytes,opt)

	lastState?: #ContainerState @go(LastTerminationState) @protobuf(3,bytes,opt)

	ready: bool @go(Ready) @protobuf(4,varint,opt)

	restartCount: int32 @go(RestartCount) @protobuf(5,varint,opt)

	image: string @go(Image) @protobuf(6,bytes,opt)

	imageID: string @go(ImageID) @protobuf(7,bytes,opt)

	containerID?: string @go(ContainerID) @protobuf(8,bytes,opt)

	started?: bool @go(Started,*bool) @protobuf(9,varint,opt)

	allocatedResources?: #ResourceList @go(AllocatedResources) @protobuf(10,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	resources?: #ResourceRequirements @go(Resources,*ResourceRequirements) @protobuf(11,bytes,opt)

	volumeMounts?: [...#VolumeMountStatus] @go(VolumeMounts,[]VolumeMountStatus) @protobuf(12,bytes,rep)

	user?: #ContainerUser @go(User,*ContainerUser) @protobuf(13,bytes,opt,casttype=ContainerUser)

	allocatedResourcesStatus?: [...#ResourceStatus] @go(AllocatedResourcesStatus,[]ResourceStatus) @protobuf(14,bytes,rep)

	stopSignal?: #Signal @go(StopSignal,*Signal) @protobuf(15,bytes,opt)
}

#ResourceStatus: {
	name: #ResourceName @go(Name) @protobuf(1,bytes,opt)

	resources?: [...#ResourceHealth] @go(Resources,[]ResourceHealth) @protobuf(2,bytes,rep)
}

#ResourceHealthStatus: string // #enumResourceHealthStatus

#enumResourceHealthStatus:
	#ResourceHealthStatusHealthy |
	#ResourceHealthStatusUnhealthy |
	#ResourceHealthStatusUnknown

#ResourceHealthStatusHealthy:   #ResourceHealthStatus & "Healthy"
#ResourceHealthStatusUnhealthy: #ResourceHealthStatus & "Unhealthy"
#ResourceHealthStatusUnknown:   #ResourceHealthStatus & "Unknown"

#ResourceHealthMessageMaxLength: 1024

#ResourceID: string

#ResourceHealth: {
	resourceID: #ResourceID @go(ResourceID) @protobuf(1,bytes,opt)

	health?: #ResourceHealthStatus @go(Health) @protobuf(2,bytes)

	message?: string @go(Message,*string) @protobuf(6,bytes,opt)
}

#ContainerUser: {
	linux?: #LinuxContainerUser @go(Linux,*LinuxContainerUser) @protobuf(1,bytes,opt,casttype=LinuxContainerUser)
}

#LinuxContainerUser: {
	uid: int64 @go(UID) @protobuf(1,varint)

	gid: int64 @go(GID) @protobuf(2,varint)

	supplementalGroups?: [...int64] @go(SupplementalGroups,[]int64) @protobuf(3,varint,rep)
}

#PodPhase: string // #enumPodPhase

#enumPodPhase:
	#PodPending |
	#PodRunning |
	#PodSucceeded |
	#PodFailed |
	#PodUnknown

#PodPending: #PodPhase & "Pending"

#PodRunning: #PodPhase & "Running"

#PodSucceeded: #PodPhase & "Succeeded"

#PodFailed: #PodPhase & "Failed"

#PodUnknown: #PodPhase & "Unknown"

#PodConditionType: string // #enumPodConditionType

#enumPodConditionType:
	#ContainersReady |
	#PodInitialized |
	#PodReady |
	#PodScheduled |
	#DisruptionTarget |
	#PodReadyToStartContainers |
	#PodResizePending |
	#PodResizeInProgress |
	#AllContainersRestarting

#ContainersReady: #PodConditionType & "ContainersReady"

#PodInitialized: #PodConditionType & "Initialized"

#PodReady: #PodConditionType & "Ready"

#PodScheduled: #PodConditionType & "PodScheduled"

#DisruptionTarget: #PodConditionType & "DisruptionTarget"

#PodReadyToStartContainers: #PodConditionType & "PodReadyToStartContainers"

#PodResizePending: #PodConditionType & "PodResizePending"

#PodResizeInProgress: #PodConditionType & "PodResizeInProgress"

#AllContainersRestarting: #PodConditionType & "AllContainersRestarting"

#PodReasonUnschedulable: "Unschedulable"

#PodReasonSchedulingGated: "SchedulingGated"

#PodReasonSchedulerError: "SchedulerError"

#PodReasonTerminationByKubelet: "TerminationByKubelet"

#PodReasonPreemptionByScheduler: "PreemptionByScheduler"

#PodReasonDeferred: "Deferred"

#PodReasonInfeasible: "Infeasible"

#PodReasonError: "Error"

#PodCondition: {
	type: #PodConditionType @go(Type) @protobuf(1,bytes,opt,casttype=PodConditionType)

	observedGeneration?: int64 @go(ObservedGeneration) @protobuf(7,varint,opt)

	status: #ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=ConditionStatus)

	lastProbeTime?: metav1.#Time @go(LastProbeTime) @protobuf(3,bytes,opt)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(4,bytes,opt)

	reason?: string @go(Reason) @protobuf(5,bytes,opt)

	message?: string @go(Message) @protobuf(6,bytes,opt)
}

#PodResizeStatus: string // #enumPodResizeStatus

#enumPodResizeStatus:
	#PodResizeStatusInProgress |
	#PodResizeStatusDeferred |
	#PodResizeStatusInfeasible

#PodResizeStatusInProgress: #PodResizeStatus & "InProgress"

#PodResizeStatusDeferred: #PodResizeStatus & "Deferred"

#PodResizeStatusInfeasible: #PodResizeStatus & "Infeasible"

#VolumeMountStatus: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	mountPath: string @go(MountPath) @protobuf(2,bytes,opt)

	readOnly?: bool @go(ReadOnly) @protobuf(3,varint,opt)

	recursiveReadOnly?: #RecursiveReadOnlyMode @go(RecursiveReadOnly,*RecursiveReadOnlyMode) @protobuf(4,bytes,opt,casttype=RecursiveReadOnlyMode)

	volumeStatus?: #VolumeStatus @go(VolumeStatus,*VolumeStatus) @protobuf(5,bytes,opt)
}

#VolumeStatus: {
	image?: #ImageVolumeStatus @go(Image,*ImageVolumeStatus) @protobuf(1,bytes,opt)
}

#ImageVolumeStatus: {
	imageRef: string @go(ImageRef) @protobuf(1,bytes,opt)
}

#RestartPolicy: string // #enumRestartPolicy

#enumRestartPolicy:
	#RestartPolicyAlways |
	#RestartPolicyOnFailure |
	#RestartPolicyNever

#RestartPolicyAlways:    #RestartPolicy & "Always"
#RestartPolicyOnFailure: #RestartPolicy & "OnFailure"
#RestartPolicyNever:     #RestartPolicy & "Never"

#ContainerRestartPolicy: string // #enumContainerRestartPolicy

#enumContainerRestartPolicy:
	#ContainerRestartPolicyAlways |
	#ContainerRestartPolicyNever |
	#ContainerRestartPolicyOnFailure

#ContainerRestartPolicyAlways:    #ContainerRestartPolicy & "Always"
#ContainerRestartPolicyNever:     #ContainerRestartPolicy & "Never"
#ContainerRestartPolicyOnFailure: #ContainerRestartPolicy & "OnFailure"

#ContainerRestartRule: {
	action: #ContainerRestartRuleAction @go(Action) @protobuf(1,bytes,opt,casttype=ContainerRestartRuleAction)

	exitCodes?: #ContainerRestartRuleOnExitCodes @go(ExitCodes,*ContainerRestartRuleOnExitCodes) @protobuf(2,bytes,opt)
}

#ContainerRestartRuleAction: string // #enumContainerRestartRuleAction

#enumContainerRestartRuleAction:
	#ContainerRestartRuleActionRestart |
	#ContainerRestartRuleActionRestartAllContainers

#ContainerRestartRuleActionRestart:              #ContainerRestartRuleAction & "Restart"
#ContainerRestartRuleActionRestartAllContainers: #ContainerRestartRuleAction & "RestartAllContainers"

#ContainerRestartRuleOnExitCodes: {
	operator: #ContainerRestartRuleOnExitCodesOperator @go(Operator) @protobuf(1,bytes,opt,casttype=ContainerRestartRuleOnExitCodesOperator)

	values?: [...int32] @go(Values,[]int32) @protobuf(2,varint,rep)
}

#ContainerRestartRuleOnExitCodesOperator: string // #enumContainerRestartRuleOnExitCodesOperator

#enumContainerRestartRuleOnExitCodesOperator:
	#ContainerRestartRuleOnExitCodesOpIn |
	#ContainerRestartRuleOnExitCodesOpNotIn

#ContainerRestartRuleOnExitCodesOpIn:    #ContainerRestartRuleOnExitCodesOperator & "In"
#ContainerRestartRuleOnExitCodesOpNotIn: #ContainerRestartRuleOnExitCodesOperator & "NotIn"

#DNSPolicy: string // #enumDNSPolicy

#enumDNSPolicy:
	#DNSClusterFirstWithHostNet |
	#DNSClusterFirst |
	#DNSDefault |
	#DNSNone

#DNSClusterFirstWithHostNet: #DNSPolicy & "ClusterFirstWithHostNet"

#DNSClusterFirst: #DNSPolicy & "ClusterFirst"

#DNSDefault: #DNSPolicy & "Default"

#DNSNone: #DNSPolicy & "None"

#DefaultTerminationGracePeriodSeconds: 30

#NodeSelector: {
	nodeSelectorTerms: [...#NodeSelectorTerm] @go(NodeSelectorTerms,[]NodeSelectorTerm) @protobuf(1,bytes,rep)
}

#NodeSelectorTerm: {
	matchExpressions?: [...#NodeSelectorRequirement] @go(MatchExpressions,[]NodeSelectorRequirement) @protobuf(1,bytes,rep)

	matchFields?: [...#NodeSelectorRequirement] @go(MatchFields,[]NodeSelectorRequirement) @protobuf(2,bytes,rep)
}

#NodeSelectorRequirement: {
	key: string @go(Key) @protobuf(1,bytes,opt)

	operator: #NodeSelectorOperator @go(Operator) @protobuf(2,bytes,opt,casttype=NodeSelectorOperator)

	values?: [...string] @go(Values,[]string) @protobuf(3,bytes,rep)
}

#NodeSelectorOperator: string // #enumNodeSelectorOperator

#enumNodeSelectorOperator:
	#NodeSelectorOpIn |
	#NodeSelectorOpNotIn |
	#NodeSelectorOpExists |
	#NodeSelectorOpDoesNotExist |
	#NodeSelectorOpGt |
	#NodeSelectorOpLt

#NodeSelectorOpIn:           #NodeSelectorOperator & "In"
#NodeSelectorOpNotIn:        #NodeSelectorOperator & "NotIn"
#NodeSelectorOpExists:       #NodeSelectorOperator & "Exists"
#NodeSelectorOpDoesNotExist: #NodeSelectorOperator & "DoesNotExist"
#NodeSelectorOpGt:           #NodeSelectorOperator & "Gt"
#NodeSelectorOpLt:           #NodeSelectorOperator & "Lt"

#TopologySelectorTerm: {
	matchLabelExpressions?: [...#TopologySelectorLabelRequirement] @go(MatchLabelExpressions,[]TopologySelectorLabelRequirement) @protobuf(1,bytes,rep)
}

#TopologySelectorLabelRequirement: {
	key: string @go(Key) @protobuf(1,bytes,opt)

	values: [...string] @go(Values,[]string) @protobuf(2,bytes,rep)
}

#Affinity: {
	nodeAffinity?: #NodeAffinity @go(NodeAffinity,*NodeAffinity) @protobuf(1,bytes,opt)

	podAffinity?: #PodAffinity @go(PodAffinity,*PodAffinity) @protobuf(2,bytes,opt)

	podAntiAffinity?: #PodAntiAffinity @go(PodAntiAffinity,*PodAntiAffinity) @protobuf(3,bytes,opt)
}

#PodAffinity: {
	requiredDuringSchedulingIgnoredDuringExecution?: [...#PodAffinityTerm] @go(RequiredDuringSchedulingIgnoredDuringExecution,[]PodAffinityTerm) @protobuf(1,bytes,rep)

	preferredDuringSchedulingIgnoredDuringExecution?: [...#WeightedPodAffinityTerm] @go(PreferredDuringSchedulingIgnoredDuringExecution,[]WeightedPodAffinityTerm) @protobuf(2,bytes,rep)
}

#PodAntiAffinity: {
	requiredDuringSchedulingIgnoredDuringExecution?: [...#PodAffinityTerm] @go(RequiredDuringSchedulingIgnoredDuringExecution,[]PodAffinityTerm) @protobuf(1,bytes,rep)

	preferredDuringSchedulingIgnoredDuringExecution?: [...#WeightedPodAffinityTerm] @go(PreferredDuringSchedulingIgnoredDuringExecution,[]WeightedPodAffinityTerm) @protobuf(2,bytes,rep)
}

#WeightedPodAffinityTerm: {
	weight: int32 @go(Weight) @protobuf(1,varint,opt)

	podAffinityTerm: #PodAffinityTerm @go(PodAffinityTerm) @protobuf(2,bytes,opt)
}

#PodAffinityTerm: {
	labelSelector?: metav1.#LabelSelector @go(LabelSelector,*metav1.LabelSelector) @protobuf(1,bytes,opt)

	namespaces?: [...string] @go(Namespaces,[]string) @protobuf(2,bytes,rep)

	topologyKey: string @go(TopologyKey) @protobuf(3,bytes,opt)

	namespaceSelector?: metav1.#LabelSelector @go(NamespaceSelector,*metav1.LabelSelector) @protobuf(4,bytes,opt)

	matchLabelKeys?: [...string] @go(MatchLabelKeys,[]string) @protobuf(5,bytes,opt)

	mismatchLabelKeys?: [...string] @go(MismatchLabelKeys,[]string) @protobuf(6,bytes,opt)
}

#NodeAffinity: {
	requiredDuringSchedulingIgnoredDuringExecution?: #NodeSelector @go(RequiredDuringSchedulingIgnoredDuringExecution,*NodeSelector) @protobuf(1,bytes,opt)

	preferredDuringSchedulingIgnoredDuringExecution?: [...#PreferredSchedulingTerm] @go(PreferredDuringSchedulingIgnoredDuringExecution,[]PreferredSchedulingTerm) @protobuf(2,bytes,rep)
}

#PreferredSchedulingTerm: {
	weight: int32 @go(Weight) @protobuf(1,varint,opt)

	preference: #NodeSelectorTerm @go(Preference) @protobuf(2,bytes,opt)
}

#Taint: {
	key: string @go(Key) @protobuf(1,bytes,opt)

	value?: string @go(Value) @protobuf(2,bytes,opt)

	effect: #TaintEffect @go(Effect) @protobuf(3,bytes,opt,casttype=TaintEffect)

	timeAdded?: metav1.#Time @go(TimeAdded,*metav1.Time) @protobuf(4,bytes,opt)
}

#TaintEffect: string // #enumTaintEffect

#enumTaintEffect:
	#TaintEffectNoSchedule |
	#TaintEffectPreferNoSchedule |
	#TaintEffectNoExecute

#TaintEffectNoSchedule: #TaintEffect & "NoSchedule"

#TaintEffectPreferNoSchedule: #TaintEffect & "PreferNoSchedule"

#TaintEffectNoExecute: #TaintEffect & "NoExecute"

#Toleration: {
	key?: string @go(Key) @protobuf(1,bytes,opt)

	operator?: #TolerationOperator @go(Operator) @protobuf(2,bytes,opt,casttype=TolerationOperator)

	value?: string @go(Value) @protobuf(3,bytes,opt)

	effect?: #TaintEffect @go(Effect) @protobuf(4,bytes,opt,casttype=TaintEffect)

	tolerationSeconds?: int64 @go(TolerationSeconds,*int64) @protobuf(5,varint,opt)
}

#TolerationOperator: string // #enumTolerationOperator

#enumTolerationOperator:
	#TolerationOpExists |
	#TolerationOpEqual |
	#TolerationOpLt |
	#TolerationOpGt

#TolerationOpExists: #TolerationOperator & "Exists"
#TolerationOpEqual:  #TolerationOperator & "Equal"
#TolerationOpLt:     #TolerationOperator & "Lt"
#TolerationOpGt:     #TolerationOperator & "Gt"

#PodReadinessGate: {
	conditionType: #PodConditionType @go(ConditionType) @protobuf(1,bytes,opt,casttype=PodConditionType)
}

#PodSpec: {
	volumes?: [...#Volume] @go(Volumes,[]Volume) @protobuf(1,bytes,rep)

	initContainers?: [...#Container] @go(InitContainers,[]Container) @protobuf(20,bytes,rep)

	containers: [...#Container] @go(Containers,[]Container) @protobuf(2,bytes,rep)

	ephemeralContainers?: [...#EphemeralContainer] @go(EphemeralContainers,[]EphemeralContainer) @protobuf(34,bytes,rep)

	restartPolicy?: #RestartPolicy @go(RestartPolicy) @protobuf(3,bytes,opt,casttype=RestartPolicy)

	terminationGracePeriodSeconds?: int64 @go(TerminationGracePeriodSeconds,*int64) @protobuf(4,varint,opt)

	activeDeadlineSeconds?: int64 @go(ActiveDeadlineSeconds,*int64) @protobuf(5,varint,opt)

	dnsPolicy?: #DNSPolicy @go(DNSPolicy) @protobuf(6,bytes,opt,casttype=DNSPolicy)

	nodeSelector?: {[string]: string} @go(NodeSelector,map[string]string) @protobuf(7,bytes,rep)

	serviceAccountName?: string @go(ServiceAccountName) @protobuf(8,bytes,opt)

	serviceAccount?: string @go(DeprecatedServiceAccount) @protobuf(9,bytes,opt)

	automountServiceAccountToken?: bool @go(AutomountServiceAccountToken,*bool) @protobuf(21,varint,opt)

	nodeName?: string @go(NodeName) @protobuf(10,bytes,opt)

	hostNetwork?: bool @go(HostNetwork) @protobuf(11,varint,opt)

	hostPID?: bool @go(HostPID) @protobuf(12,varint,opt)

	hostIPC?: bool @go(HostIPC) @protobuf(13,varint,opt)

	shareProcessNamespace?: bool @go(ShareProcessNamespace,*bool) @protobuf(27,varint,opt)

	securityContext?: #PodSecurityContext @go(SecurityContext,*PodSecurityContext) @protobuf(14,bytes,opt)

	imagePullSecrets?: [...#LocalObjectReference] @go(ImagePullSecrets,[]LocalObjectReference) @protobuf(15,bytes,rep)

	hostname?: string @go(Hostname) @protobuf(16,bytes,opt)

	subdomain?: string @go(Subdomain) @protobuf(17,bytes,opt)

	affinity?: #Affinity @go(Affinity,*Affinity) @protobuf(18,bytes,opt)

	schedulerName?: string @go(SchedulerName) @protobuf(19,bytes,opt)

	tolerations?: [...#Toleration] @go(Tolerations,[]Toleration) @protobuf(22,bytes,opt)

	hostAliases?: [...#HostAlias] @go(HostAliases,[]HostAlias) @protobuf(23,bytes,rep)

	priorityClassName?: string @go(PriorityClassName) @protobuf(24,bytes,opt)

	priority?: int32 @go(Priority,*int32) @protobuf(25,bytes,opt)

	dnsConfig?: #PodDNSConfig @go(DNSConfig,*PodDNSConfig) @protobuf(26,bytes,opt)

	readinessGates?: [...#PodReadinessGate] @go(ReadinessGates,[]PodReadinessGate) @protobuf(28,bytes,opt)

	runtimeClassName?: string @go(RuntimeClassName,*string) @protobuf(29,bytes,opt)

	enableServiceLinks?: bool @go(EnableServiceLinks,*bool) @protobuf(30,varint,opt)

	preemptionPolicy?: #PreemptionPolicy @go(PreemptionPolicy,*PreemptionPolicy) @protobuf(31,bytes,opt)

	overhead?: #ResourceList @go(Overhead) @protobuf(32,bytes,opt)

	topologySpreadConstraints?: [...#TopologySpreadConstraint] @go(TopologySpreadConstraints,[]TopologySpreadConstraint) @protobuf(33,bytes,opt)

	setHostnameAsFQDN?: bool @go(SetHostnameAsFQDN,*bool) @protobuf(35,varint,opt)

	os?: #PodOS @go(OS,*PodOS) @protobuf(36,bytes,opt)

	hostUsers?: bool @go(HostUsers,*bool) @protobuf(37,bytes,opt)

	schedulingGates?: [...#PodSchedulingGate] @go(SchedulingGates,[]PodSchedulingGate) @protobuf(38,bytes,opt)

	resourceClaims?: [...#PodResourceClaim] @go(ResourceClaims,[]PodResourceClaim) @protobuf(39,bytes,rep)

	resources?: #ResourceRequirements @go(Resources,*ResourceRequirements) @protobuf(40,bytes,opt)

	hostnameOverride?: string @go(HostnameOverride,*string) @protobuf(41,bytes,opt)

	schedulingGroup?: #PodSchedulingGroup @go(SchedulingGroup,*PodSchedulingGroup) @protobuf(43,bytes,opt)
}

#PodResourceClaim: {
	name: string @go(Name) @protobuf(1,bytes)

	resourceClaimName?: string @go(ResourceClaimName,*string) @protobuf(3,bytes,opt)

	resourceClaimTemplateName?: string @go(ResourceClaimTemplateName,*string) @protobuf(4,bytes,opt)
}

#PodResourceClaimStatus: {
	name: string @go(Name) @protobuf(1,bytes)

	resourceClaimName?: string @go(ResourceClaimName,*string) @protobuf(2,bytes,opt)
}

#PodExtendedResourceClaimStatus: {
	requestMappings: [...#ContainerExtendedResourceRequest] @go(RequestMappings,[]ContainerExtendedResourceRequest) @protobuf(1,bytes,rep)

	resourceClaimName: string @go(ResourceClaimName) @protobuf(2,bytes)
}

#ContainerExtendedResourceRequest: {
	containerName: string @go(ContainerName) @protobuf(1,bytes)

	resourceName: string @go(ResourceName) @protobuf(2,bytes)

	requestName: string @go(RequestName) @protobuf(3,bytes)
}

#OSName: string // #enumOSName

#enumOSName:
	#Linux |
	#Windows

#Linux:   #OSName & "linux"
#Windows: #OSName & "windows"

#PodOS: {
	name: #OSName @go(Name) @protobuf(1,bytes,opt)
}

#PodSchedulingGate: {
	name: string @go(Name) @protobuf(1,bytes,opt)
}

#PodSchedulingGroup: {
	podGroupName?: string @go(PodGroupName,*string) @protobuf(1,bytes,opt)
}

#UnsatisfiableConstraintAction: string // #enumUnsatisfiableConstraintAction

#enumUnsatisfiableConstraintAction:
	#DoNotSchedule |
	#ScheduleAnyway

#DoNotSchedule: #UnsatisfiableConstraintAction & "DoNotSchedule"

#ScheduleAnyway: #UnsatisfiableConstraintAction & "ScheduleAnyway"

#NodeInclusionPolicy: string // #enumNodeInclusionPolicy

#enumNodeInclusionPolicy:
	#NodeInclusionPolicyIgnore |
	#NodeInclusionPolicyHonor

#NodeInclusionPolicyIgnore: #NodeInclusionPolicy & "Ignore"

#NodeInclusionPolicyHonor: #NodeInclusionPolicy & "Honor"

#TopologySpreadConstraint: {
	maxSkew: int32 @go(MaxSkew) @protobuf(1,varint,opt)

	topologyKey: string @go(TopologyKey) @protobuf(2,bytes,opt)

	whenUnsatisfiable: #UnsatisfiableConstraintAction @go(WhenUnsatisfiable) @protobuf(3,bytes,opt,casttype=UnsatisfiableConstraintAction)

	labelSelector?: metav1.#LabelSelector @go(LabelSelector,*metav1.LabelSelector) @protobuf(4,bytes,opt)

	minDomains?: int32 @go(MinDomains,*int32) @protobuf(5,varint,opt)

	nodeAffinityPolicy?: #NodeInclusionPolicy @go(NodeAffinityPolicy,*NodeInclusionPolicy) @protobuf(6,bytes,opt)

	nodeTaintsPolicy?: #NodeInclusionPolicy @go(NodeTaintsPolicy,*NodeInclusionPolicy) @protobuf(7,bytes,opt)

	matchLabelKeys?: [...string] @go(MatchLabelKeys,[]string) @protobuf(8,bytes,opt)
}

#DefaultEnableServiceLinks: true

#HostAlias: {
	ip: string @go(IP) @protobuf(1,bytes,opt)

	hostnames?: [...string] @go(Hostnames,[]string) @protobuf(2,bytes,rep)
}

#PodFSGroupChangePolicy: string // #enumPodFSGroupChangePolicy

#enumPodFSGroupChangePolicy:
	#FSGroupChangeOnRootMismatch |
	#FSGroupChangeAlways

#FSGroupChangeOnRootMismatch: #PodFSGroupChangePolicy & "OnRootMismatch"

#FSGroupChangeAlways: #PodFSGroupChangePolicy & "Always"

#SupplementalGroupsPolicy: string // #enumSupplementalGroupsPolicy

#enumSupplementalGroupsPolicy:
	#SupplementalGroupsPolicyMerge |
	#SupplementalGroupsPolicyStrict

#SupplementalGroupsPolicyMerge: #SupplementalGroupsPolicy & "Merge"

#SupplementalGroupsPolicyStrict: #SupplementalGroupsPolicy & "Strict"

#PodSELinuxChangePolicy: string // #enumPodSELinuxChangePolicy

#enumPodSELinuxChangePolicy:
	#SELinuxChangePolicyRecursive |
	#SELinuxChangePolicyMountOption

#SELinuxChangePolicyRecursive: #PodSELinuxChangePolicy & "Recursive"

#SELinuxChangePolicyMountOption: #PodSELinuxChangePolicy & "MountOption"

#PodSecurityContext: {
	seLinuxOptions?: #SELinuxOptions @go(SELinuxOptions,*SELinuxOptions) @protobuf(1,bytes,opt)

	windowsOptions?: #WindowsSecurityContextOptions @go(WindowsOptions,*WindowsSecurityContextOptions) @protobuf(8,bytes,opt)

	runAsUser?: int64 @go(RunAsUser,*int64) @protobuf(2,varint,opt)

	runAsGroup?: int64 @go(RunAsGroup,*int64) @protobuf(6,varint,opt)

	runAsNonRoot?: bool @go(RunAsNonRoot,*bool) @protobuf(3,varint,opt)

	supplementalGroups?: [...int64] @go(SupplementalGroups,[]int64) @protobuf(4,varint,rep)

	supplementalGroupsPolicy?: #SupplementalGroupsPolicy @go(SupplementalGroupsPolicy,*SupplementalGroupsPolicy) @protobuf(12,bytes,opt)

	fsGroup?: int64 @go(FSGroup,*int64) @protobuf(5,varint,opt)

	sysctls?: [...#Sysctl] @go(Sysctls,[]Sysctl) @protobuf(7,bytes,rep)

	fsGroupChangePolicy?: #PodFSGroupChangePolicy @go(FSGroupChangePolicy,*PodFSGroupChangePolicy) @protobuf(9,bytes,opt)

	seccompProfile?: #SeccompProfile @go(SeccompProfile,*SeccompProfile) @protobuf(10,bytes,opt)

	appArmorProfile?: #AppArmorProfile @go(AppArmorProfile,*AppArmorProfile) @protobuf(11,bytes,opt)

	seLinuxChangePolicy?: #PodSELinuxChangePolicy @go(SELinuxChangePolicy,*PodSELinuxChangePolicy) @protobuf(13,bytes,opt)
}

#SeccompProfile: {
	type: #SeccompProfileType @go(Type) @protobuf(1,bytes,opt,casttype=SeccompProfileType)

	localhostProfile?: string @go(LocalhostProfile,*string) @protobuf(2,bytes,opt)
}

#SeccompProfileType: string // #enumSeccompProfileType

#enumSeccompProfileType:
	#SeccompProfileTypeUnconfined |
	#SeccompProfileTypeRuntimeDefault |
	#SeccompProfileTypeLocalhost

#SeccompProfileTypeUnconfined: #SeccompProfileType & "Unconfined"

#SeccompProfileTypeRuntimeDefault: #SeccompProfileType & "RuntimeDefault"

#SeccompProfileTypeLocalhost: #SeccompProfileType & "Localhost"

#AppArmorProfile: {
	type: #AppArmorProfileType @go(Type) @protobuf(1,bytes,opt,casttype=AppArmorProfileType)

	localhostProfile?: string @go(LocalhostProfile,*string) @protobuf(2,bytes,opt)
}

#AppArmorProfileType: string // #enumAppArmorProfileType

#enumAppArmorProfileType:
	#AppArmorProfileTypeUnconfined |
	#AppArmorProfileTypeRuntimeDefault |
	#AppArmorProfileTypeLocalhost

#AppArmorProfileTypeUnconfined: #AppArmorProfileType & "Unconfined"

#AppArmorProfileTypeRuntimeDefault: #AppArmorProfileType & "RuntimeDefault"

#AppArmorProfileTypeLocalhost: #AppArmorProfileType & "Localhost"

#PodQOSClass: string // #enumPodQOSClass

#enumPodQOSClass:
	#PodQOSGuaranteed |
	#PodQOSBurstable |
	#PodQOSBestEffort

#PodQOSGuaranteed: #PodQOSClass & "Guaranteed"

#PodQOSBurstable: #PodQOSClass & "Burstable"

#PodQOSBestEffort: #PodQOSClass & "BestEffort"

#PodDNSConfig: {
	nameservers?: [...string] @go(Nameservers,[]string) @protobuf(1,bytes,rep)

	searches?: [...string] @go(Searches,[]string) @protobuf(2,bytes,rep)

	options?: [...#PodDNSConfigOption] @go(Options,[]PodDNSConfigOption) @protobuf(3,bytes,rep)
}

#PodDNSConfigOption: {
	name?: string @go(Name) @protobuf(1,bytes,opt)

	value?: string @go(Value,*string) @protobuf(2,bytes,opt)
}

#PodIP: {
	ip: string @go(IP) @protobuf(1,bytes,opt)
}

#HostIP: {
	ip: string @go(IP) @protobuf(1,bytes,opt)
}

#EphemeralContainerCommon: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	image?: string @go(Image) @protobuf(2,bytes,opt)

	command?: [...string] @go(Command,[]string) @protobuf(3,bytes,rep)

	args?: [...string] @go(Args,[]string) @protobuf(4,bytes,rep)

	workingDir?: string @go(WorkingDir) @protobuf(5,bytes,opt)

	ports?: [...#ContainerPort] @go(Ports,[]ContainerPort) @protobuf(6,bytes,rep)

	envFrom?: [...#EnvFromSource] @go(EnvFrom,[]EnvFromSource) @protobuf(19,bytes,rep)

	env?: [...#EnvVar] @go(Env,[]EnvVar) @protobuf(7,bytes,rep)

	resources?: #ResourceRequirements @go(Resources) @protobuf(8,bytes,opt)

	resizePolicy?: [...#ContainerResizePolicy] @go(ResizePolicy,[]ContainerResizePolicy) @protobuf(23,bytes,rep)

	restartPolicy?: #ContainerRestartPolicy @go(RestartPolicy,*ContainerRestartPolicy) @protobuf(24,bytes,opt,casttype=ContainerRestartPolicy)

	restartPolicyRules?: [...#ContainerRestartRule] @go(RestartPolicyRules,[]ContainerRestartRule) @protobuf(25,bytes,rep)

	volumeMounts?: [...#VolumeMount] @go(VolumeMounts,[]VolumeMount) @protobuf(9,bytes,rep)

	volumeDevices?: [...#VolumeDevice] @go(VolumeDevices,[]VolumeDevice) @protobuf(21,bytes,rep)

	livenessProbe?: #Probe @go(LivenessProbe,*Probe) @protobuf(10,bytes,opt)

	readinessProbe?: #Probe @go(ReadinessProbe,*Probe) @protobuf(11,bytes,opt)

	startupProbe?: #Probe @go(StartupProbe,*Probe) @protobuf(22,bytes,opt)

	lifecycle?: #Lifecycle @go(Lifecycle,*Lifecycle) @protobuf(12,bytes,opt)

	terminationMessagePath?: string @go(TerminationMessagePath) @protobuf(13,bytes,opt)

	terminationMessagePolicy?: #TerminationMessagePolicy @go(TerminationMessagePolicy) @protobuf(20,bytes,opt,casttype=TerminationMessagePolicy)

	imagePullPolicy?: #PullPolicy @go(ImagePullPolicy) @protobuf(14,bytes,opt,casttype=PullPolicy)

	securityContext?: #SecurityContext @go(SecurityContext,*SecurityContext) @protobuf(15,bytes,opt)

	stdin?: bool @go(Stdin) @protobuf(16,varint,opt)

	stdinOnce?: bool @go(StdinOnce) @protobuf(17,varint,opt)

	tty?: bool @go(TTY) @protobuf(18,varint,opt)
}

#EphemeralContainer: {
	#EphemeralContainerCommon

	targetContainerName?: string @go(TargetContainerName) @protobuf(2,bytes,opt)
}

#PodStatus: {
	observedGeneration?: int64 @go(ObservedGeneration) @protobuf(17,varint,opt)

	phase?: #PodPhase @go(Phase) @protobuf(1,bytes,opt,casttype=PodPhase)

	conditions?: [...#PodCondition] @go(Conditions,[]PodCondition) @protobuf(2,bytes,rep)

	message?: string @go(Message) @protobuf(3,bytes,opt)

	reason?: string @go(Reason) @protobuf(4,bytes,opt)

	nominatedNodeName?: string @go(NominatedNodeName) @protobuf(11,bytes,opt)

	hostIP?: string @go(HostIP) @protobuf(5,bytes,opt)

	hostIPs?: [...#HostIP] @go(HostIPs,[]HostIP) @protobuf(16,bytes,rep)

	podIP?: string @go(PodIP) @protobuf(6,bytes,opt)

	podIPs?: [...#PodIP] @go(PodIPs,[]PodIP) @protobuf(12,bytes,rep)

	startTime?: metav1.#Time @go(StartTime,*metav1.Time) @protobuf(7,bytes,opt)

	initContainerStatuses?: [...#ContainerStatus] @go(InitContainerStatuses,[]ContainerStatus) @protobuf(10,bytes,rep)

	containerStatuses?: [...#ContainerStatus] @go(ContainerStatuses,[]ContainerStatus) @protobuf(8,bytes,rep)

	qosClass?: #PodQOSClass @go(QOSClass) @protobuf(9,bytes,rep)

	ephemeralContainerStatuses?: [...#ContainerStatus] @go(EphemeralContainerStatuses,[]ContainerStatus) @protobuf(13,bytes,rep)

	resize?: #PodResizeStatus @go(Resize) @protobuf(14,bytes,opt,casttype=PodResizeStatus)

	resourceClaimStatuses?: [...#PodResourceClaimStatus] @go(ResourceClaimStatuses,[]PodResourceClaimStatus) @protobuf(15,bytes,rep)

	extendedResourceClaimStatus?: #PodExtendedResourceClaimStatus @go(ExtendedResourceClaimStatus,*PodExtendedResourceClaimStatus) @protobuf(18,bytes,opt)

	allocatedResources?: #ResourceList @go(AllocatedResources) @protobuf(19,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	resources?: #ResourceRequirements @go(Resources,*ResourceRequirements) @protobuf(20,bytes,opt)

	nodeAllocatableResourceClaimStatuses?: [...#NodeAllocatableResourceClaimStatus] @go(NodeAllocatableResourceClaimStatuses,[]NodeAllocatableResourceClaimStatus) @protobuf(21,bytes,rep)
}

#PodStatusResult: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	status?: #PodStatus @go(Status) @protobuf(2,bytes,opt)
}

#Pod: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #PodSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #PodStatus @go(Status) @protobuf(3,bytes,opt)
}

#PodList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Pod] @go(Items,[]Pod) @protobuf(2,bytes,rep)
}

#PodTemplateSpec: {
	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #PodSpec @go(Spec) @protobuf(2,bytes,opt)
}

#PodTemplate: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	template?: #PodTemplateSpec @go(Template) @protobuf(2,bytes,opt)
}

#PodTemplateList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#PodTemplate] @go(Items,[]PodTemplate) @protobuf(2,bytes,rep)
}

#ReplicationControllerSpec: {
	replicas?: int32 @go(Replicas,*int32) @protobuf(1,varint,opt)

	minReadySeconds?: int32 @go(MinReadySeconds) @protobuf(4,varint,opt)

	selector?: {[string]: string} @go(Selector,map[string]string) @protobuf(2,bytes,rep)

	template?: #PodTemplateSpec @go(Template,*PodTemplateSpec) @protobuf(3,bytes,opt)
}

#ReplicationControllerStatus: {
	replicas: int32 @go(Replicas) @protobuf(1,varint,opt)

	fullyLabeledReplicas?: int32 @go(FullyLabeledReplicas) @protobuf(2,varint,opt)

	readyReplicas?: int32 @go(ReadyReplicas) @protobuf(4,varint,opt)

	availableReplicas?: int32 @go(AvailableReplicas) @protobuf(5,varint,opt)

	observedGeneration?: int64 @go(ObservedGeneration) @protobuf(3,varint,opt)

	conditions?: [...#ReplicationControllerCondition] @go(Conditions,[]ReplicationControllerCondition) @protobuf(6,bytes,rep)
}

#ReplicationControllerConditionType: string // #enumReplicationControllerConditionType

#enumReplicationControllerConditionType:
	#ReplicationControllerReplicaFailure

#ReplicationControllerReplicaFailure: #ReplicationControllerConditionType & "ReplicaFailure"

#ReplicationControllerCondition: {
	type: #ReplicationControllerConditionType @go(Type) @protobuf(1,bytes,opt,casttype=ReplicationControllerConditionType)

	status: #ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=ConditionStatus)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(3,bytes,opt)

	reason?: string @go(Reason) @protobuf(4,bytes,opt)

	message?: string @go(Message) @protobuf(5,bytes,opt)
}

#ReplicationController: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #ReplicationControllerSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #ReplicationControllerStatus @go(Status) @protobuf(3,bytes,opt)
}

#ReplicationControllerList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ReplicationController] @go(Items,[]ReplicationController) @protobuf(2,bytes,rep)
}

#ServiceAffinity: string // #enumServiceAffinity

#enumServiceAffinity:
	#ServiceAffinityClientIP |
	#ServiceAffinityNone

#ServiceAffinityClientIP: #ServiceAffinity & "ClientIP"

#ServiceAffinityNone: #ServiceAffinity & "None"

#DefaultClientIPServiceAffinitySeconds: int32 & 10800

#SessionAffinityConfig: {
	clientIP?: #ClientIPConfig @go(ClientIP,*ClientIPConfig) @protobuf(1,bytes,opt)
}

#ClientIPConfig: {
	timeoutSeconds?: int32 @go(TimeoutSeconds,*int32) @protobuf(1,varint,opt)
}

#ServiceType: string // #enumServiceType

#enumServiceType:
	#ServiceTypeClusterIP |
	#ServiceTypeNodePort |
	#ServiceTypeLoadBalancer |
	#ServiceTypeExternalName

#ServiceTypeClusterIP: #ServiceType & "ClusterIP"

#ServiceTypeNodePort: #ServiceType & "NodePort"

#ServiceTypeLoadBalancer: #ServiceType & "LoadBalancer"

#ServiceTypeExternalName: #ServiceType & "ExternalName"

#ServiceInternalTrafficPolicy: string // #enumServiceInternalTrafficPolicy

#enumServiceInternalTrafficPolicy:
	#ServiceInternalTrafficPolicyCluster |
	#ServiceInternalTrafficPolicyLocal

#ServiceInternalTrafficPolicyCluster: #ServiceInternalTrafficPolicy & "Cluster"

#ServiceInternalTrafficPolicyLocal: #ServiceInternalTrafficPolicy & "Local"

#ServiceInternalTrafficPolicyType: #ServiceInternalTrafficPolicy

#ServiceExternalTrafficPolicy: string // #enumServiceExternalTrafficPolicy

#enumServiceExternalTrafficPolicy:
	#ServiceExternalTrafficPolicyCluster |
	#ServiceExternalTrafficPolicyLocal |
	#ServiceExternalTrafficPolicyTypeLocal |
	#ServiceExternalTrafficPolicyTypeCluster

#ServiceExternalTrafficPolicyCluster: #ServiceExternalTrafficPolicy & "Cluster"

#ServiceExternalTrafficPolicyLocal: #ServiceExternalTrafficPolicy & "Local"

#ServiceExternalTrafficPolicyType: #ServiceExternalTrafficPolicy

#ServiceExternalTrafficPolicyTypeLocal:   #ServiceExternalTrafficPolicy & "Local"
#ServiceExternalTrafficPolicyTypeCluster: #ServiceExternalTrafficPolicy & "Cluster"

#ServiceTrafficDistributionPreferSameZone: "PreferSameZone"

#ServiceTrafficDistributionPreferSameNode: "PreferSameNode"

#ServiceTrafficDistributionPreferClose: "PreferClose"

#LoadBalancerPortsError: "LoadBalancerPortsError"

#LoadBalancerPortsErrorReason: "LoadBalancerMixedProtocolNotSupported"

#ServiceStatus: {
	loadBalancer?: #LoadBalancerStatus @go(LoadBalancer) @protobuf(1,bytes,opt)

	conditions?: [...metav1.#Condition] @go(Conditions,[]metav1.Condition) @protobuf(2,bytes,rep)
}

#LoadBalancerStatus: {
	ingress?: [...#LoadBalancerIngress] @go(Ingress,[]LoadBalancerIngress) @protobuf(1,bytes,rep)
}

#LoadBalancerIngress: {
	ip?: string @go(IP) @protobuf(1,bytes,opt)

	hostname?: string @go(Hostname) @protobuf(2,bytes,opt)

	ipMode?: #LoadBalancerIPMode @go(IPMode,*LoadBalancerIPMode) @protobuf(3,bytes,opt)

	ports?: [...#PortStatus] @go(Ports,[]PortStatus) @protobuf(4,bytes,rep)
}

#IPFamily: string // #enumIPFamily

#enumIPFamily:
	#IPv4Protocol |
	#IPv6Protocol |
	#IPFamilyUnknown

#IPv4Protocol: #IPFamily & "IPv4"

#IPv6Protocol: #IPFamily & "IPv6"

#IPFamilyUnknown: #IPFamily & ""

#IPFamilyPolicy: string // #enumIPFamilyPolicy

#enumIPFamilyPolicy:
	#IPFamilyPolicySingleStack |
	#IPFamilyPolicyPreferDualStack |
	#IPFamilyPolicyRequireDualStack

#IPFamilyPolicySingleStack: #IPFamilyPolicy & "SingleStack"

#IPFamilyPolicyPreferDualStack: #IPFamilyPolicy & "PreferDualStack"

#IPFamilyPolicyRequireDualStack: #IPFamilyPolicy & "RequireDualStack"

#IPFamilyPolicyType: #IPFamilyPolicy

#ServiceSpec: {
	ports?: [...#ServicePort] @go(Ports,[]ServicePort) @protobuf(1,bytes,rep)

	selector?: {[string]: string} @go(Selector,map[string]string) @protobuf(2,bytes,rep)

	clusterIP?: string @go(ClusterIP) @protobuf(3,bytes,opt)

	clusterIPs?: [...string] @go(ClusterIPs,[]string) @protobuf(18,bytes,opt)

	type?: #ServiceType @go(Type) @protobuf(4,bytes,opt,casttype=ServiceType)

	externalIPs?: [...string] @go(ExternalIPs,[]string) @protobuf(5,bytes,rep)

	sessionAffinity?: #ServiceAffinity @go(SessionAffinity) @protobuf(7,bytes,opt,casttype=ServiceAffinity)

	loadBalancerIP?: string @go(LoadBalancerIP) @protobuf(8,bytes,opt)

	loadBalancerSourceRanges?: [...string] @go(LoadBalancerSourceRanges,[]string) @protobuf(9,bytes,opt)

	externalName?: string @go(ExternalName) @protobuf(10,bytes,opt)

	externalTrafficPolicy?: #ServiceExternalTrafficPolicy @go(ExternalTrafficPolicy) @protobuf(11,bytes,opt)

	healthCheckNodePort?: int32 @go(HealthCheckNodePort) @protobuf(12,bytes,opt)

	publishNotReadyAddresses?: bool @go(PublishNotReadyAddresses) @protobuf(13,varint,opt)

	sessionAffinityConfig?: #SessionAffinityConfig @go(SessionAffinityConfig,*SessionAffinityConfig) @protobuf(14,bytes,opt)

	ipFamilies?: [...#IPFamily] @go(IPFamilies,[]IPFamily) @protobuf(19,bytes,opt,casttype=IPFamily)

	ipFamilyPolicy?: #IPFamilyPolicy @go(IPFamilyPolicy,*IPFamilyPolicy) @protobuf(17,bytes,opt,casttype=IPFamilyPolicy)

	allocateLoadBalancerNodePorts?: bool @go(AllocateLoadBalancerNodePorts,*bool) @protobuf(20,bytes,opt)

	loadBalancerClass?: string @go(LoadBalancerClass,*string) @protobuf(21,bytes,opt)

	internalTrafficPolicy?: #ServiceInternalTrafficPolicy @go(InternalTrafficPolicy,*ServiceInternalTrafficPolicy) @protobuf(22,bytes,opt)

	trafficDistribution?: string @go(TrafficDistribution,*string) @protobuf(23,bytes,opt)
}

#ServicePort: {
	name?: string @go(Name) @protobuf(1,bytes,opt)

	protocol?: #Protocol @go(Protocol) @protobuf(2,bytes,opt,casttype=Protocol)

	appProtocol?: string @go(AppProtocol,*string) @protobuf(6,bytes,opt)

	port: int32 @go(Port) @protobuf(3,varint,opt)

	targetPort?: intstr.#IntOrString @go(TargetPort) @protobuf(4,bytes,opt)

	nodePort?: int32 @go(NodePort) @protobuf(5,varint,opt)
}

#Service: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #ServiceSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #ServiceStatus @go(Status) @protobuf(3,bytes,opt)
}

#ClusterIPNone: "None"

#ServiceList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Service] @go(Items,[]Service) @protobuf(2,bytes,rep)
}

#ServiceAccount: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	secrets?: [...#ObjectReference] @go(Secrets,[]ObjectReference) @protobuf(2,bytes,rep)

	imagePullSecrets?: [...#LocalObjectReference] @go(ImagePullSecrets,[]LocalObjectReference) @protobuf(3,bytes,rep)

	automountServiceAccountToken?: bool @go(AutomountServiceAccountToken,*bool) @protobuf(4,varint,opt)
}

#ServiceAccountList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ServiceAccount] @go(Items,[]ServiceAccount) @protobuf(2,bytes,rep)
}

#Endpoints: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	subsets?: [...#EndpointSubset] @go(Subsets,[]EndpointSubset) @protobuf(2,bytes,rep)
}

#EndpointSubset: {
	addresses?: [...#EndpointAddress] @go(Addresses,[]EndpointAddress) @protobuf(1,bytes,rep)

	notReadyAddresses?: [...#EndpointAddress] @go(NotReadyAddresses,[]EndpointAddress) @protobuf(2,bytes,rep)

	ports?: [...#EndpointPort] @go(Ports,[]EndpointPort) @protobuf(3,bytes,rep)
}

#EndpointAddress: {
	ip: string @go(IP) @protobuf(1,bytes,opt)

	hostname?: string @go(Hostname) @protobuf(3,bytes,opt)

	nodeName?: string @go(NodeName,*string) @protobuf(4,bytes,opt)

	targetRef?: #ObjectReference @go(TargetRef,*ObjectReference) @protobuf(2,bytes,opt)
}

#EndpointPort: {
	name?: string @go(Name) @protobuf(1,bytes,opt)

	port: int32 @go(Port) @protobuf(2,varint,opt)

	protocol?: #Protocol @go(Protocol) @protobuf(3,bytes,opt,casttype=Protocol)

	appProtocol?: string @go(AppProtocol,*string) @protobuf(4,bytes,opt)
}

#EndpointsList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Endpoints] @go(Items,[]Endpoints) @protobuf(2,bytes,rep)
}

#NodeSpec: {
	podCIDR?: string @go(PodCIDR) @protobuf(1,bytes,opt)

	podCIDRs?: [...string] @go(PodCIDRs,[]string) @protobuf(7,bytes,opt)

	providerID?: string @go(ProviderID) @protobuf(3,bytes,opt)

	unschedulable?: bool @go(Unschedulable) @protobuf(4,varint,opt)

	taints?: [...#Taint] @go(Taints,[]Taint) @protobuf(5,bytes,opt)

	configSource?: #NodeConfigSource @go(ConfigSource,*NodeConfigSource) @protobuf(6,bytes,opt)

	externalID?: string @go(DoNotUseExternalID) @protobuf(2,bytes,opt)
}

#NodeConfigSource: {
	configMap?: #ConfigMapNodeConfigSource @go(ConfigMap,*ConfigMapNodeConfigSource) @protobuf(2,bytes,opt)
}

#ConfigMapNodeConfigSource: {
	namespace: string @go(Namespace) @protobuf(1,bytes,opt)

	name: string @go(Name) @protobuf(2,bytes,opt)

	uid?: types.#UID @go(UID) @protobuf(3,bytes,opt)

	resourceVersion?: string @go(ResourceVersion) @protobuf(4,bytes,opt)

	kubeletConfigKey: string @go(KubeletConfigKey) @protobuf(5,bytes,opt)
}

#DaemonEndpoint: {
	Port: int32 @protobuf(1,varint,opt)
}

#NodeDaemonEndpoints: {
	kubeletEndpoint?: #DaemonEndpoint @go(KubeletEndpoint) @protobuf(1,bytes,opt)
}

#NodeRuntimeHandlerFeatures: {
	recursiveReadOnlyMounts?: bool @go(RecursiveReadOnlyMounts,*bool) @protobuf(1,varint,opt)

	userNamespaces?: bool @go(UserNamespaces,*bool) @protobuf(2,varint,opt)
}

#NodeRuntimeHandler: {
	name?: string @go(Name) @protobuf(1,bytes,opt)

	features?: #NodeRuntimeHandlerFeatures @go(Features,*NodeRuntimeHandlerFeatures) @protobuf(2,bytes,opt)
}

#NodeFeatures: {
	supplementalGroupsPolicy?: bool @go(SupplementalGroupsPolicy,*bool) @protobuf(1,varint,opt)
}

#NodeSystemInfo: {
	machineID: string @go(MachineID) @protobuf(1,bytes,opt)

	systemUUID: string @go(SystemUUID) @protobuf(2,bytes,opt)

	bootID: string @go(BootID) @protobuf(3,bytes,opt)

	kernelVersion: string @go(KernelVersion) @protobuf(4,bytes,opt)

	osImage: string @go(OSImage) @protobuf(5,bytes,opt)

	containerRuntimeVersion: string @go(ContainerRuntimeVersion) @protobuf(6,bytes,opt)

	kubeletVersion: string @go(KubeletVersion) @protobuf(7,bytes,opt)

	kubeProxyVersion: string @go(KubeProxyVersion) @protobuf(8,bytes,opt)

	operatingSystem: string @go(OperatingSystem) @protobuf(9,bytes,opt)

	architecture: string @go(Architecture) @protobuf(10,bytes,opt)

	swap?: #NodeSwapStatus @go(Swap,*NodeSwapStatus) @protobuf(11,bytes,opt)
}

#NodeSwapStatus: {
	capacity?: int64 @go(Capacity,*int64) @protobuf(1,varint,opt)
}

#NodeConfigStatus: {
	assigned?: #NodeConfigSource @go(Assigned,*NodeConfigSource) @protobuf(1,bytes,opt)

	active?: #NodeConfigSource @go(Active,*NodeConfigSource) @protobuf(2,bytes,opt)

	lastKnownGood?: #NodeConfigSource @go(LastKnownGood,*NodeConfigSource) @protobuf(3,bytes,opt)

	error?: string @go(Error) @protobuf(4,bytes,opt)
}

#NodeStatus: {
	capacity?: #ResourceList @go(Capacity) @protobuf(1,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	allocatable?: #ResourceList @go(Allocatable) @protobuf(2,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	phase?: #NodePhase @go(Phase) @protobuf(3,bytes,opt,casttype=NodePhase)

	conditions?: [...#NodeCondition] @go(Conditions,[]NodeCondition) @protobuf(4,bytes,rep)

	addresses?: [...#NodeAddress] @go(Addresses,[]NodeAddress) @protobuf(5,bytes,rep)

	daemonEndpoints?: #NodeDaemonEndpoints @go(DaemonEndpoints) @protobuf(6,bytes,opt)

	nodeInfo?: #NodeSystemInfo @go(NodeInfo) @protobuf(7,bytes,opt)

	images?: [...#ContainerImage] @go(Images,[]ContainerImage) @protobuf(8,bytes,rep)

	volumesInUse?: [...#UniqueVolumeName] @go(VolumesInUse,[]UniqueVolumeName) @protobuf(9,bytes,rep)

	volumesAttached?: [...#AttachedVolume] @go(VolumesAttached,[]AttachedVolume) @protobuf(10,bytes,rep)

	config?: #NodeConfigStatus @go(Config,*NodeConfigStatus) @protobuf(11,bytes,opt)

	runtimeHandlers?: [...#NodeRuntimeHandler] @go(RuntimeHandlers,[]NodeRuntimeHandler) @protobuf(12,bytes,rep)

	features?: #NodeFeatures @go(Features,*NodeFeatures) @protobuf(13,bytes,rep)

	declaredFeatures?: [...string] @go(DeclaredFeatures,[]string) @protobuf(14,bytes,rep)
}

#UniqueVolumeName: string

#AttachedVolume: {
	name: #UniqueVolumeName @go(Name) @protobuf(1,bytes,rep)

	devicePath: string @go(DevicePath) @protobuf(2,bytes,rep)
}

#AvoidPods: {
	preferAvoidPods?: [...#PreferAvoidPodsEntry] @go(PreferAvoidPods,[]PreferAvoidPodsEntry) @protobuf(1,bytes,rep)
}

#PreferAvoidPodsEntry: {
	podSignature: #PodSignature @go(PodSignature) @protobuf(1,bytes,opt)

	evictionTime?: metav1.#Time @go(EvictionTime) @protobuf(2,bytes,opt)

	reason?: string @go(Reason) @protobuf(3,bytes,opt)

	message?: string @go(Message) @protobuf(4,bytes,opt)
}

#PodSignature: {
	podController?: metav1.#OwnerReference @go(PodController,*metav1.OwnerReference) @protobuf(1,bytes,opt)
}

#ContainerImage: {
	names?: [...string] @go(Names,[]string) @protobuf(1,bytes,rep)

	sizeBytes?: int64 @go(SizeBytes) @protobuf(2,varint,opt)
}

#NodePhase: string // #enumNodePhase

#enumNodePhase:
	#NodePending |
	#NodeRunning |
	#NodeTerminated

#NodePending: #NodePhase & "Pending"

#NodeRunning: #NodePhase & "Running"

#NodeTerminated: #NodePhase & "Terminated"

#NodeConditionType: string // #enumNodeConditionType

#enumNodeConditionType:
	#NodeReady |
	#NodeMemoryPressure |
	#NodeDiskPressure |
	#NodePIDPressure |
	#NodeNetworkUnavailable

#NodeReady: #NodeConditionType & "Ready"

#NodeMemoryPressure: #NodeConditionType & "MemoryPressure"

#NodeDiskPressure: #NodeConditionType & "DiskPressure"

#NodePIDPressure: #NodeConditionType & "PIDPressure"

#NodeNetworkUnavailable: #NodeConditionType & "NetworkUnavailable"

#NodeCondition: {
	type: #NodeConditionType @go(Type) @protobuf(1,bytes,opt,casttype=NodeConditionType)

	status: #ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=ConditionStatus)

	lastHeartbeatTime?: metav1.#Time @go(LastHeartbeatTime) @protobuf(3,bytes,opt)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(4,bytes,opt)

	reason?: string @go(Reason) @protobuf(5,bytes,opt)

	message?: string @go(Message) @protobuf(6,bytes,opt)
}

#NodeAddressType: string // #enumNodeAddressType

#enumNodeAddressType:
	#NodeHostName |
	#NodeInternalIP |
	#NodeExternalIP |
	#NodeInternalDNS |
	#NodeExternalDNS

#NodeHostName: #NodeAddressType & "Hostname"

#NodeInternalIP: #NodeAddressType & "InternalIP"

#NodeExternalIP: #NodeAddressType & "ExternalIP"

#NodeInternalDNS: #NodeAddressType & "InternalDNS"

#NodeExternalDNS: #NodeAddressType & "ExternalDNS"

#NodeAddress: {
	type: #NodeAddressType @go(Type) @protobuf(1,bytes,opt,casttype=NodeAddressType)

	address: string @go(Address) @protobuf(2,bytes,opt)
}

#ResourceName: string // #enumResourceName

#enumResourceName:
	#ResourceCPU |
	#ResourceMemory |
	#ResourceStorage |
	#ResourceEphemeralStorage |
	#ResourcePods |
	#ResourceServices |
	#ResourceReplicationControllers |
	#ResourceQuotas |
	#ResourceSecrets |
	#ResourceConfigMaps |
	#ResourcePersistentVolumeClaims |
	#ResourceServicesNodePorts |
	#ResourceServicesLoadBalancers |
	#ResourceRequestsCPU |
	#ResourceRequestsMemory |
	#ResourceRequestsStorage |
	#ResourceRequestsEphemeralStorage |
	#ResourceLimitsCPU |
	#ResourceLimitsMemory |
	#ResourceLimitsEphemeralStorage

#ResourceCPU: #ResourceName & "cpu"

#ResourceMemory: #ResourceName & "memory"

#ResourceStorage: #ResourceName & "storage"

#ResourceEphemeralStorage: #ResourceName & "ephemeral-storage"

#ResourceDefaultNamespacePrefix: "kubernetes.io/"

#ResourceHugePagesPrefix: "hugepages-"

#ResourceAttachableVolumesPrefix: "attachable-volumes-"

#ResourceList: {[string]: resource.#Quantity}

#Node: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #NodeSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #NodeStatus @go(Status) @protobuf(3,bytes,opt)
}

#NodeList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Node] @go(Items,[]Node) @protobuf(2,bytes,rep)
}

#FinalizerName: string // #enumFinalizerName

#enumFinalizerName:
	#FinalizerKubernetes

#FinalizerKubernetes: #FinalizerName & "kubernetes"

#NamespaceSpec: {
	finalizers?: [...#FinalizerName] @go(Finalizers,[]FinalizerName) @protobuf(1,bytes,rep,casttype=FinalizerName)
}

#NamespaceStatus: {
	phase?: #NamespacePhase @go(Phase) @protobuf(1,bytes,opt,casttype=NamespacePhase)

	conditions?: [...#NamespaceCondition] @go(Conditions,[]NamespaceCondition) @protobuf(2,bytes,rep)
}

#NamespacePhase: string // #enumNamespacePhase

#enumNamespacePhase:
	#NamespaceActive |
	#NamespaceTerminating

#NamespaceActive: #NamespacePhase & "Active"

#NamespaceTerminating: #NamespacePhase & "Terminating"

#NamespaceTerminatingCause: metav1.#CauseType & "NamespaceTerminating"

#NamespaceConditionType: string // #enumNamespaceConditionType

#enumNamespaceConditionType:
	#NamespaceDeletionDiscoveryFailure |
	#NamespaceDeletionContentFailure |
	#NamespaceDeletionGVParsingFailure |
	#NamespaceContentRemaining |
	#NamespaceFinalizersRemaining

#NamespaceDeletionDiscoveryFailure: #NamespaceConditionType & "NamespaceDeletionDiscoveryFailure"

#NamespaceDeletionContentFailure: #NamespaceConditionType & "NamespaceDeletionContentFailure"

#NamespaceDeletionGVParsingFailure: #NamespaceConditionType & "NamespaceDeletionGroupVersionParsingFailure"

#NamespaceContentRemaining: #NamespaceConditionType & "NamespaceContentRemaining"

#NamespaceFinalizersRemaining: #NamespaceConditionType & "NamespaceFinalizersRemaining"

#NamespaceCondition: {
	type: #NamespaceConditionType @go(Type) @protobuf(1,bytes,opt,casttype=NamespaceConditionType)

	status: #ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=ConditionStatus)

	lastTransitionTime?: metav1.#Time @go(LastTransitionTime) @protobuf(4,bytes,opt)

	reason?: string @go(Reason) @protobuf(5,bytes,opt)

	message?: string @go(Message) @protobuf(6,bytes,opt)
}

#Namespace: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #NamespaceSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #NamespaceStatus @go(Status) @protobuf(3,bytes,opt)
}

#NamespaceList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Namespace] @go(Items,[]Namespace) @protobuf(2,bytes,rep)
}

#Binding: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	target: #ObjectReference @go(Target) @protobuf(2,bytes,opt)
}

#Preconditions: {
	uid?: types.#UID @go(UID,*types.UID) @protobuf(1,bytes,opt,casttype=k8s.io/apimachinery/pkg/types.UID)
}

#LogStreamStdout: "Stdout"

#LogStreamStderr: "Stderr"

#LogStreamAll: "All"

#PodLogOptions: {
	metav1.#TypeMeta

	container?: string @go(Container) @protobuf(1,bytes,opt)

	follow?: bool @go(Follow) @protobuf(2,varint,opt)

	previous?: bool @go(Previous) @protobuf(3,varint,opt)

	sinceSeconds?: int64 @go(SinceSeconds,*int64) @protobuf(4,varint,opt)

	sinceTime?: metav1.#Time @go(SinceTime,*metav1.Time) @protobuf(5,bytes,opt)

	timestamps?: bool @go(Timestamps) @protobuf(6,varint,opt)

	tailLines?: int64 @go(TailLines,*int64) @protobuf(7,varint,opt)

	limitBytes?: int64 @go(LimitBytes,*int64) @protobuf(8,varint,opt)

	insecureSkipTLSVerifyBackend?: bool @go(InsecureSkipTLSVerifyBackend) @protobuf(9,varint,opt)

	stream?: string @go(Stream,*string) @protobuf(10,varint,opt)
}

#PodAttachOptions: {
	metav1.#TypeMeta

	stdin?: bool @go(Stdin) @protobuf(1,varint,opt)

	stdout?: bool @go(Stdout) @protobuf(2,varint,opt)

	stderr?: bool @go(Stderr) @protobuf(3,varint,opt)

	tty?: bool @go(TTY) @protobuf(4,varint,opt)

	container?: string @go(Container) @protobuf(5,bytes,opt)
}

#PodExecOptions: {
	metav1.#TypeMeta

	stdin?: bool @go(Stdin) @protobuf(1,varint,opt)

	stdout?: bool @go(Stdout) @protobuf(2,varint,opt)

	stderr?: bool @go(Stderr) @protobuf(3,varint,opt)

	tty?: bool @go(TTY) @protobuf(4,varint,opt)

	container?: string @go(Container) @protobuf(5,bytes,opt)

	command: [...string] @go(Command,[]string) @protobuf(6,bytes,rep)
}

#PodPortForwardOptions: {
	metav1.#TypeMeta

	ports?: [...int32] @go(Ports,[]int32) @protobuf(1,varint,rep)
}

#PodProxyOptions: {
	metav1.#TypeMeta

	path?: string @go(Path) @protobuf(1,bytes,opt)
}

#NodeProxyOptions: {
	metav1.#TypeMeta

	path?: string @go(Path) @protobuf(1,bytes,opt)
}

#ServiceProxyOptions: {
	metav1.#TypeMeta

	path?: string @go(Path) @protobuf(1,bytes,opt)
}

#ObjectReference: {
	kind?: string @go(Kind) @protobuf(1,bytes,opt)

	namespace?: string @go(Namespace) @protobuf(2,bytes,opt)

	name?: string @go(Name) @protobuf(3,bytes,opt)

	uid?: types.#UID @go(UID) @protobuf(4,bytes,opt,casttype=k8s.io/apimachinery/pkg/types.UID)

	apiVersion?: string @go(APIVersion) @protobuf(5,bytes,opt)

	resourceVersion?: string @go(ResourceVersion) @protobuf(6,bytes,opt)

	fieldPath?: string @go(FieldPath) @protobuf(7,bytes,opt)
}

#LocalObjectReference: {
	name?: string @go(Name) @protobuf(1,bytes,opt)
}

#TypedLocalObjectReference: {
	apiGroup?: string @go(APIGroup,*string) @protobuf(1,bytes,opt)

	kind: string @go(Kind) @protobuf(2,bytes,opt)

	name: string @go(Name) @protobuf(3,bytes,opt)
}

#SerializedReference: {
	metav1.#TypeMeta

	reference?: #ObjectReference @go(Reference) @protobuf(1,bytes,opt)
}

#EventSource: {
	component?: string @go(Component) @protobuf(1,bytes,opt)

	host?: string @go(Host) @protobuf(2,bytes,opt)
}

#EventTypeNormal: "Normal"

#EventTypeWarning: "Warning"

#Event: {
	metav1.#TypeMeta

	metadata: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	involvedObject: #ObjectReference @go(InvolvedObject) @protobuf(2,bytes,opt)

	reason?: string @go(Reason) @protobuf(3,bytes,opt)

	message?: string @go(Message) @protobuf(4,bytes,opt)

	source?: #EventSource @go(Source) @protobuf(5,bytes,opt)

	firstTimestamp?: metav1.#Time @go(FirstTimestamp) @protobuf(6,bytes,opt)

	lastTimestamp?: metav1.#Time @go(LastTimestamp) @protobuf(7,bytes,opt)

	count?: int32 @go(Count) @protobuf(8,varint,opt)

	type?: string @go(Type) @protobuf(9,bytes,opt)

	eventTime?: metav1.#MicroTime @go(EventTime) @protobuf(10,bytes,opt)

	series?: #EventSeries @go(Series,*EventSeries) @protobuf(11,bytes,opt)

	action?: string @go(Action) @protobuf(12,bytes,opt)

	related?: #ObjectReference @go(Related,*ObjectReference) @protobuf(13,bytes,opt)

	reportingComponent?: string @go(ReportingController) @protobuf(14,bytes,opt)

	reportingInstance?: string @go(ReportingInstance) @protobuf(15,bytes,opt)
}

#EventSeries: {
	count?: int32 @go(Count) @protobuf(1,varint)

	lastObservedTime?: metav1.#MicroTime @go(LastObservedTime) @protobuf(2,bytes)
}

#EventList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Event] @go(Items,[]Event) @protobuf(2,bytes,rep)
}

#List: metav1.#List

#LimitType: string // #enumLimitType

#enumLimitType:
	#LimitTypePod |
	#LimitTypeContainer |
	#LimitTypePersistentVolumeClaim

#LimitTypePod: #LimitType & "Pod"

#LimitTypeContainer: #LimitType & "Container"

#LimitTypePersistentVolumeClaim: #LimitType & "PersistentVolumeClaim"

#LimitRangeItem: {
	type: #LimitType @go(Type) @protobuf(1,bytes,opt,casttype=LimitType)

	max?: #ResourceList @go(Max) @protobuf(2,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	min?: #ResourceList @go(Min) @protobuf(3,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	default?: #ResourceList @go(Default) @protobuf(4,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	defaultRequest?: #ResourceList @go(DefaultRequest) @protobuf(5,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	maxLimitRequestRatio?: #ResourceList @go(MaxLimitRequestRatio) @protobuf(6,bytes,rep,casttype=ResourceList,castkey=ResourceName)
}

#LimitRangeSpec: {
	limits: [...#LimitRangeItem] @go(Limits,[]LimitRangeItem) @protobuf(1,bytes,rep)
}

#LimitRange: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #LimitRangeSpec @go(Spec) @protobuf(2,bytes,opt)
}

#LimitRangeList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#LimitRange] @go(Items,[]LimitRange) @protobuf(2,bytes,rep)
}

#ResourcePods: #ResourceName & "pods"

#ResourceServices: #ResourceName & "services"

#ResourceReplicationControllers: #ResourceName & "replicationcontrollers"

#ResourceQuotas: #ResourceName & "resourcequotas"

#ResourceSecrets: #ResourceName & "secrets"

#ResourceConfigMaps: #ResourceName & "configmaps"

#ResourcePersistentVolumeClaims: #ResourceName & "persistentvolumeclaims"

#ResourceServicesNodePorts: #ResourceName & "services.nodeports"

#ResourceServicesLoadBalancers: #ResourceName & "services.loadbalancers"

#ResourceRequestsCPU: #ResourceName & "requests.cpu"

#ResourceRequestsMemory: #ResourceName & "requests.memory"

#ResourceRequestsStorage: #ResourceName & "requests.storage"

#ResourceRequestsEphemeralStorage: #ResourceName & "requests.ephemeral-storage"

#ResourceLimitsCPU: #ResourceName & "limits.cpu"

#ResourceLimitsMemory: #ResourceName & "limits.memory"

#ResourceLimitsEphemeralStorage: #ResourceName & "limits.ephemeral-storage"

#ResourceClaimsPerClass: ".deviceclass.resource.k8s.io/devices"

#ResourceImplicitExtendedClaimsPerClass: "requests.deviceclass.resource.kubernetes.io/"

#ResourceRequestsHugePagesPrefix: "requests.hugepages-"

#DefaultResourceRequestsPrefix: "requests."

#ResourceQuotaScope: string // #enumResourceQuotaScope

#enumResourceQuotaScope:
	#ResourceQuotaScopeTerminating |
	#ResourceQuotaScopeNotTerminating |
	#ResourceQuotaScopeBestEffort |
	#ResourceQuotaScopeNotBestEffort |
	#ResourceQuotaScopePriorityClass |
	#ResourceQuotaScopeCrossNamespacePodAffinity |
	#ResourceQuotaScopeVolumeAttributesClass

#ResourceQuotaScopeTerminating: #ResourceQuotaScope & "Terminating"

#ResourceQuotaScopeNotTerminating: #ResourceQuotaScope & "NotTerminating"

#ResourceQuotaScopeBestEffort: #ResourceQuotaScope & "BestEffort"

#ResourceQuotaScopeNotBestEffort: #ResourceQuotaScope & "NotBestEffort"

#ResourceQuotaScopePriorityClass: #ResourceQuotaScope & "PriorityClass"

#ResourceQuotaScopeCrossNamespacePodAffinity: #ResourceQuotaScope & "CrossNamespacePodAffinity"

#ResourceQuotaScopeVolumeAttributesClass: #ResourceQuotaScope & "VolumeAttributesClass"

#ResourceQuotaSpec: {
	hard?: #ResourceList @go(Hard) @protobuf(1,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	scopes?: [...#ResourceQuotaScope] @go(Scopes,[]ResourceQuotaScope) @protobuf(2,bytes,rep,casttype=ResourceQuotaScope)

	scopeSelector?: #ScopeSelector @go(ScopeSelector,*ScopeSelector) @protobuf(3,bytes,opt)
}

#ScopeSelector: {
	matchExpressions?: [...#ScopedResourceSelectorRequirement] @go(MatchExpressions,[]ScopedResourceSelectorRequirement) @protobuf(1,bytes,rep)
}

#ScopedResourceSelectorRequirement: {
	scopeName: #ResourceQuotaScope @go(ScopeName) @protobuf(1,bytes,opt)

	operator: #ScopeSelectorOperator @go(Operator) @protobuf(2,bytes,opt,casttype=ScopedResourceSelectorOperator)

	values?: [...string] @go(Values,[]string) @protobuf(3,bytes,rep)
}

#ScopeSelectorOperator: string // #enumScopeSelectorOperator

#enumScopeSelectorOperator:
	#ScopeSelectorOpIn |
	#ScopeSelectorOpNotIn |
	#ScopeSelectorOpExists |
	#ScopeSelectorOpDoesNotExist

#ScopeSelectorOpIn:           #ScopeSelectorOperator & "In"
#ScopeSelectorOpNotIn:        #ScopeSelectorOperator & "NotIn"
#ScopeSelectorOpExists:       #ScopeSelectorOperator & "Exists"
#ScopeSelectorOpDoesNotExist: #ScopeSelectorOperator & "DoesNotExist"

#ResourceQuotaStatus: {
	hard?: #ResourceList @go(Hard) @protobuf(1,bytes,rep,casttype=ResourceList,castkey=ResourceName)

	used?: #ResourceList @go(Used) @protobuf(2,bytes,rep,casttype=ResourceList,castkey=ResourceName)
}

#ResourceQuota: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	spec?: #ResourceQuotaSpec @go(Spec) @protobuf(2,bytes,opt)

	status?: #ResourceQuotaStatus @go(Status) @protobuf(3,bytes,opt)
}

#ResourceQuotaList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ResourceQuota] @go(Items,[]ResourceQuota) @protobuf(2,bytes,rep)
}

#Secret: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	immutable?: bool @go(Immutable,*bool) @protobuf(5,varint,opt)

	data?: {[string]: bytes} @go(Data,map[string][]byte) @protobuf(2,bytes,rep)

	stringData?: {[string]: string} @go(StringData,map[string]string) @protobuf(4,bytes,rep)

	type?: #SecretType @go(Type) @protobuf(3,bytes,opt,casttype=SecretType)
}

#MaxSecretSize: 1048576

#SecretType: string // #enumSecretType

#enumSecretType:
	#SecretTypeOpaque |
	#SecretTypeServiceAccountToken |
	#SecretTypeDockercfg |
	#SecretTypeDockerConfigJson |
	#SecretTypeBasicAuth |
	#SecretTypeSSHAuth |
	#SecretTypeTLS |
	#SecretTypeBootstrapToken

#SecretTypeOpaque: #SecretType & "Opaque"

#SecretTypeServiceAccountToken: #SecretType & "kubernetes.io/service-account-token"

#ServiceAccountNameKey: "kubernetes.io/service-account.name"

#ServiceAccountUIDKey: "kubernetes.io/service-account.uid"

#ServiceAccountTokenKey: "token"

#ServiceAccountKubeconfigKey: "kubernetes.kubeconfig"

#ServiceAccountRootCAKey: "ca.crt"

#ServiceAccountNamespaceKey: "namespace"

#SecretTypeDockercfg: #SecretType & "kubernetes.io/dockercfg"

#DockerConfigKey: ".dockercfg"

#SecretTypeDockerConfigJson: #SecretType & "kubernetes.io/dockerconfigjson"

#DockerConfigJsonKey: ".dockerconfigjson"

#SecretTypeBasicAuth: #SecretType & "kubernetes.io/basic-auth"

#BasicAuthUsernameKey: "username"

#BasicAuthPasswordKey: "password"

#SecretTypeSSHAuth: #SecretType & "kubernetes.io/ssh-auth"

#SSHAuthPrivateKey: "ssh-privatekey"

#SecretTypeTLS: #SecretType & "kubernetes.io/tls"

#TLSCertKey: "tls.crt"

#TLSPrivateKeyKey: "tls.key"

#SecretTypeBootstrapToken: #SecretType & "bootstrap.kubernetes.io/token"

#SecretList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#Secret] @go(Items,[]Secret) @protobuf(2,bytes,rep)
}

#ConfigMap: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	immutable?: bool @go(Immutable,*bool) @protobuf(4,varint,opt)

	data?: {[string]: string} @go(Data,map[string]string) @protobuf(2,bytes,rep)

	binaryData?: {[string]: bytes} @go(BinaryData,map[string][]byte) @protobuf(3,bytes,rep)
}

#ConfigMapList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ConfigMap] @go(Items,[]ConfigMap) @protobuf(2,bytes,rep)
}

#ComponentConditionType: string // #enumComponentConditionType

#enumComponentConditionType:
	#ComponentHealthy

#ComponentHealthy: #ComponentConditionType & "Healthy"

#ComponentCondition: {
	type: #ComponentConditionType @go(Type) @protobuf(1,bytes,opt,casttype=ComponentConditionType)

	status: #ConditionStatus @go(Status) @protobuf(2,bytes,opt,casttype=ConditionStatus)

	message?: string @go(Message) @protobuf(3,bytes,opt)

	error?: string @go(Error) @protobuf(4,bytes,opt)
}

#ComponentStatus: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	conditions?: [...#ComponentCondition] @go(Conditions,[]ComponentCondition) @protobuf(2,bytes,rep)
}

#ComponentStatusList: {
	metav1.#TypeMeta

	metadata?: metav1.#ListMeta @go(ListMeta) @protobuf(1,bytes,opt)

	items: [...#ComponentStatus] @go(Items,[]ComponentStatus) @protobuf(2,bytes,rep)
}

#DownwardAPIVolumeSource: {
	items?: [...#DownwardAPIVolumeFile] @go(Items,[]DownwardAPIVolumeFile) @protobuf(1,bytes,rep)

	defaultMode?: int32 @go(DefaultMode,*int32) @protobuf(2,varint,opt)
}

#DownwardAPIVolumeSourceDefaultMode: int32 & 0o644

#DownwardAPIVolumeFile: {
	path: string @go(Path) @protobuf(1,bytes,opt)

	fieldRef?: #ObjectFieldSelector @go(FieldRef,*ObjectFieldSelector) @protobuf(2,bytes,opt)

	resourceFieldRef?: #ResourceFieldSelector @go(ResourceFieldRef,*ResourceFieldSelector) @protobuf(3,bytes,opt)

	mode?: int32 @go(Mode,*int32) @protobuf(4,varint,opt)
}

#DownwardAPIProjection: {
	items?: [...#DownwardAPIVolumeFile] @go(Items,[]DownwardAPIVolumeFile) @protobuf(1,bytes,rep)
}

#SecurityContext: {
	capabilities?: #Capabilities @go(Capabilities,*Capabilities) @protobuf(1,bytes,opt)

	privileged?: bool @go(Privileged,*bool) @protobuf(2,varint,opt)

	seLinuxOptions?: #SELinuxOptions @go(SELinuxOptions,*SELinuxOptions) @protobuf(3,bytes,opt)

	windowsOptions?: #WindowsSecurityContextOptions @go(WindowsOptions,*WindowsSecurityContextOptions) @protobuf(10,bytes,opt)

	runAsUser?: int64 @go(RunAsUser,*int64) @protobuf(4,varint,opt)

	runAsGroup?: int64 @go(RunAsGroup,*int64) @protobuf(8,varint,opt)

	runAsNonRoot?: bool @go(RunAsNonRoot,*bool) @protobuf(5,varint,opt)

	readOnlyRootFilesystem?: bool @go(ReadOnlyRootFilesystem,*bool) @protobuf(6,varint,opt)

	allowPrivilegeEscalation?: bool @go(AllowPrivilegeEscalation,*bool) @protobuf(7,varint,opt)

	procMount?: #ProcMountType @go(ProcMount,*ProcMountType) @protobuf(9,bytes,opt)

	seccompProfile?: #SeccompProfile @go(SeccompProfile,*SeccompProfile) @protobuf(11,bytes,opt)

	appArmorProfile?: #AppArmorProfile @go(AppArmorProfile,*AppArmorProfile) @protobuf(12,bytes,opt)
}

#ProcMountType: string // #enumProcMountType

#enumProcMountType:
	#DefaultProcMount |
	#UnmaskedProcMount

#DefaultProcMount: #ProcMountType & "Default"

#UnmaskedProcMount: #ProcMountType & "Unmasked"

#SELinuxOptions: {
	user?: string @go(User) @protobuf(1,bytes,opt)

	role?: string @go(Role) @protobuf(2,bytes,opt)

	type?: string @go(Type) @protobuf(3,bytes,opt)

	level?: string @go(Level) @protobuf(4,bytes,opt)
}

#WindowsSecurityContextOptions: {
	gmsaCredentialSpecName?: string @go(GMSACredentialSpecName,*string) @protobuf(1,bytes,opt)

	gmsaCredentialSpec?: string @go(GMSACredentialSpec,*string) @protobuf(2,bytes,opt)

	runAsUserName?: string @go(RunAsUserName,*string) @protobuf(3,bytes,opt)

	hostProcess?: bool @go(HostProcess,*bool) @protobuf(4,bytes,opt)
}

#RangeAllocation: {
	metav1.#TypeMeta

	metadata?: metav1.#ObjectMeta @go(ObjectMeta) @protobuf(1,bytes,opt)

	range: string @go(Range) @protobuf(2,bytes,opt)

	data: bytes @go(Data,[]byte) @protobuf(3,bytes,opt)
}

#DefaultSchedulerName: "default-scheduler"

#DefaultHardPodAffinitySymmetricWeight: int32 & 1

#Sysctl: {
	name: string @go(Name) @protobuf(1,bytes,opt)

	value: string @go(Value) @protobuf(2,bytes,opt)
}

#ExecStdinParam: "input"

#ExecStdoutParam: "output"

#ExecStderrParam: "error"

#ExecTTYParam: "tty"

#ExecCommandParam: "command"

#StreamType: "streamType"

#StreamTypeStdin: "stdin"

#StreamTypeStdout: "stdout"

#StreamTypeStderr: "stderr"

#StreamTypeData: "data"

#StreamTypeError: "error"

#StreamTypeResize: "resize"

#PortHeader: "port"

#PortForwardRequestIDHeader: "requestID"

#MixedProtocolNotSupported: "MixedProtocolNotSupported"

#PortStatus: {
	port: int32 @go(Port) @protobuf(1,varint,opt)

	protocol: #Protocol @go(Protocol) @protobuf(2,bytes,opt,casttype=Protocol)

	error?: string @go(Error,*string) @protobuf(3,bytes,opt)
}

#LoadBalancerIPMode: string // #enumLoadBalancerIPMode

#enumLoadBalancerIPMode:
	#LoadBalancerIPModeVIP |
	#LoadBalancerIPModeProxy

#LoadBalancerIPModeVIP: #LoadBalancerIPMode & "VIP"

#LoadBalancerIPModeProxy: #LoadBalancerIPMode & "Proxy"

#ImageVolumeSource: {
	reference?: string @go(Reference) @protobuf(1,bytes,opt)

	pullPolicy?: #PullPolicy @go(PullPolicy) @protobuf(2,bytes,opt,casttype=PullPolicy)
}

#NodeAllocatableResourceClaimStatus: {
	resourceClaimName: string @go(ResourceClaimName) @protobuf(1,bytes,opt)

	containers?: [...string] @go(Containers,[]string) @protobuf(2,bytes,rep)

	resources: {[string]: resource.#Quantity} @go(Resources,map[ResourceName]resource.Quantity) @protobuf(3,bytes,rep)
}
