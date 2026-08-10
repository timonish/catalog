

package watch

#FullChannelBehavior: int // #enumFullChannelBehavior

#enumFullChannelBehavior:
	#WaitIfChannelFull |
	#DropIfChannelFull

#values_FullChannelBehavior: {
	WaitIfChannelFull: #WaitIfChannelFull
	DropIfChannelFull: #DropIfChannelFull
}

#WaitIfChannelFull: #FullChannelBehavior & 0
#DropIfChannelFull: #FullChannelBehavior & 1

_#incomingQueueLength: 25

_#internalRunFunctionMarker: "internal-do-function"
