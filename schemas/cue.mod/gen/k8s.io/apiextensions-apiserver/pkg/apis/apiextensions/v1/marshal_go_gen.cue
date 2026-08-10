

package v1

_#cborMajorType: int

_#cborUnsignedInteger: _#cborMajorType & 0
_#cborNegativeInteger: _#cborMajorType & 1
_#cborByteString:      _#cborMajorType & 2
_#cborTextString:      _#cborMajorType & 3
_#cborArray:           _#cborMajorType & 4
_#cborMap:             _#cborMajorType & 5
_#cborTag:             _#cborMajorType & 6
_#cborOther:           _#cborMajorType & 7

_#cborFalseValue: 0xf4
_#cborTrueValue:  0xf5
_#cborNullValue:  0xf6
