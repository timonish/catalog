

package resource

#Scale: int32 // #enumScale

#enumScale:
	#Nano |
	#Micro |
	#Milli |
	#Kilo |
	#Mega |
	#Giga |
	#Tera |
	#Peta |
	#Exa

#values_Scale: {
	Nano:  #Nano
	Micro: #Micro
	Milli: #Milli
	Kilo:  #Kilo
	Mega:  #Mega
	Giga:  #Giga
	Tera:  #Tera
	Peta:  #Peta
	Exa:   #Exa
}

#Nano:  #Scale & -9
#Micro: #Scale & -6
#Milli: #Scale & -3
#Kilo:  #Scale & 3
#Mega:  #Scale & 6
#Giga:  #Scale & 9
#Tera:  #Scale & 12
#Peta:  #Scale & 15
#Exa:   #Scale & 18

_#infDecAmount: string
