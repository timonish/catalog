package config

import (
	"strconv"
	"strings"
)

// ListenPort extracts the port number of a `host:port` listen address;
// the `0` address disables the listener and yields port 0. Random-port
// addresses like `:0` are rejected — the container ports and Services
// need a deterministic port.
#ListenPort: {
	#Address: string
	_parts:   strings.Split(#Address, ":")
	port: [
		if #Address == "0" {0},
		strconv.Atoi(_parts[len(_parts)-1]) & >0 & <=65535,
	][0]
}
