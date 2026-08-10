

package intstr

#IntOrString: _

#Type: int64 // #enumType

#enumType:
	#Int |
	#String

#values_Type: {
	Int:    #Int
	String: #String
}

#Int:    #Type & 0
#String: #Type & 1
