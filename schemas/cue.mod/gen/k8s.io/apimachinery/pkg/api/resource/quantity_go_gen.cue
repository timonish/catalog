

package resource

#Quantity: _

#CanonicalValue: _

#Format: string // #enumFormat

#enumFormat:
	#DecimalExponent |
	#BinarySI |
	#DecimalSI

#DecimalExponent: #Format & "DecimalExponent"
#BinarySI:        #Format & "BinarySI"
#DecimalSI:       #Format & "DecimalSI"

_#splitREString: "^([+-]?[0-9.]+)([eEinumkKMGTP]*[-+]?[0-9]*)$"

_#int64QuantityExpectedBytes: 18

#QuantityValue: _
