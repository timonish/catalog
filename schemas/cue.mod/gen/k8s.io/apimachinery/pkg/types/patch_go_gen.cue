

package types

#PatchType: string // #enumPatchType

#enumPatchType:
	#JSONPatchType |
	#MergePatchType |
	#StrategicMergePatchType |
	#ApplyPatchType |
	#ApplyYAMLPatchType |
	#ApplyCBORPatchType

#JSONPatchType:           #PatchType & "application/json-patch+json"
#MergePatchType:          #PatchType & "application/merge-patch+json"
#StrategicMergePatchType: #PatchType & "application/strategic-merge-patch+json"
#ApplyPatchType:          #PatchType & "application/apply-patch+yaml"
#ApplyYAMLPatchType:      #PatchType & "application/apply-patch+yaml"
#ApplyCBORPatchType:      #PatchType & "application/apply-patch+cbor"
