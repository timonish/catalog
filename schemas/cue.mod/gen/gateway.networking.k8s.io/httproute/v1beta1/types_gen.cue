

package v1beta1

import (
	"strings"
	"list"
)

#HTTPRoute: {
	apiVersion: "gateway.networking.k8s.io/v1beta1"

	kind: "HTTPRoute"
	metadata!: {
		name!: strings.MaxRunes(253) & strings.MinRunes(1) & {
			string
		}
		namespace!: strings.MaxRunes(63) & strings.MinRunes(1) & {
			string
		}
		labels?: {
			[string]: string
		}
		annotations?: {
			[string]: string
		}
	}

	spec!: #HTTPRouteSpec
}

#HTTPRouteSpec: {
	hostnames?: list.MaxItems(16) & [...strings.MaxRunes(253) & strings.MinRunes(1) & =~"^(\\*\\.)?[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"]

	parentRefs?: list.MaxItems(32) & [...{
		group?: strings.MaxRunes(253) & {
			=~"^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
		}

		kind?: strings.MaxRunes(63) & strings.MinRunes(1) & {
			=~"^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
		}

		name!: strings.MaxRunes(253) & strings.MinRunes(1)

		namespace?: strings.MaxRunes(63) & strings.MinRunes(1) & {
			=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
		}

		port?: uint & >=1 & <=65535

		sectionName?: strings.MaxRunes(253) & strings.MinRunes(1) & {
			=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
		}
	}]

	rules?: list.MaxItems(16) & [...{
		backendRefs?: list.MaxItems(16) & [...{
			filters?: list.MaxItems(16) & [...{
				cors?: {
					allowCredentials?: bool

					allowHeaders?: list.MaxItems(64) & [...strings.MaxRunes(256) & strings.MinRunes(1) & =~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"]

					allowMethods?: list.MaxItems(9) & [..."GET" | "HEAD" | "POST" | "PUT" | "DELETE" | "CONNECT" | "OPTIONS" | "TRACE" | "PATCH" | "*"]

					allowOrigins?: list.MaxItems(64) & [...strings.MaxRunes(253) & strings.MinRunes(1) & =~"(^\\*$)|(^(http(s)?):\\/\\/(((\\*\\.)?([a-zA-Z0-9\\-]+\\.)*[a-zA-Z0-9-]+|\\*)(:([0-9]{1,5}))?)$)"]

					exposeHeaders?: list.MaxItems(64) & [...strings.MaxRunes(256) & strings.MinRunes(1) & =~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"]

					maxAge?: uint & >=1 & <=2147483647
				}

				extensionRef?: {
					group!: strings.MaxRunes(253) & {
						=~"^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
					}

					kind!: strings.MaxRunes(63) & strings.MinRunes(1) & {
						=~"^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
					}

					name!: strings.MaxRunes(253) & strings.MinRunes(1)
				}

				requestHeaderModifier?: {
					add?: list.MaxItems(16) & [...{
						name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
							=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
						}

						value!: strings.MaxRunes(4096) & strings.MinRunes(1)
					}]

					remove?: list.MaxItems(16) & [...string]

					set?: list.MaxItems(16) & [...{
						name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
							=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
						}

						value!: strings.MaxRunes(4096) & strings.MinRunes(1)
					}]
				}

				requestMirror?: {
					backendRef!: {
						group?: strings.MaxRunes(253) & {
							=~"^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
						}

						kind?: strings.MaxRunes(63) & strings.MinRunes(1) & {
							=~"^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
						}

						name!: strings.MaxRunes(253) & strings.MinRunes(1)

						namespace?: strings.MaxRunes(63) & strings.MinRunes(1) & {
							=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
						}

						port?: uint & >=1 & <=65535
					}

					fraction?: {
						denominator?: uint & >=1 & <=2147483647
						numerator!:   uint & <=2147483647
					}

					percent?: uint & <=100
				}

				requestRedirect?: {
					hostname?: strings.MaxRunes(253) & strings.MinRunes(1) & {
						=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
					}

					path?: {
						replaceFullPath?: strings.MaxRunes(1024)

						replacePrefixMatch?: strings.MaxRunes(1024)

						type!: "ReplaceFullPath" | "ReplacePrefixMatch"
					}

					port?: uint & >=1 & <=65535

					scheme?: "http" | "https"

					statusCode?: (301 | 302 | 303 | 307 | 308) & {
						int
					}
				}

				responseHeaderModifier?: {
					add?: list.MaxItems(16) & [...{
						name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
							=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
						}

						value!: strings.MaxRunes(4096) & strings.MinRunes(1)
					}]

					remove?: list.MaxItems(16) & [...string]

					set?: list.MaxItems(16) & [...{
						name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
							=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
						}

						value!: strings.MaxRunes(4096) & strings.MinRunes(1)
					}]
				}

				type!: "RequestHeaderModifier" | "ResponseHeaderModifier" | "RequestMirror" | "RequestRedirect" | "URLRewrite" | "ExtensionRef" | "CORS"

				urlRewrite?: {
					hostname?: strings.MaxRunes(253) & strings.MinRunes(1) & {
						=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
					}

					path?: {
						replaceFullPath?: strings.MaxRunes(1024)

						replacePrefixMatch?: strings.MaxRunes(1024)

						type!: "ReplaceFullPath" | "ReplacePrefixMatch"
					}
				}
			}]

			group?: strings.MaxRunes(253) & {
				=~"^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
			}

			kind?: strings.MaxRunes(63) & strings.MinRunes(1) & {
				=~"^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
			}

			name!: strings.MaxRunes(253) & strings.MinRunes(1)

			namespace?: strings.MaxRunes(63) & strings.MinRunes(1) & {
				=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
			}

			port?: uint & >=1 & <=65535

			weight?: uint & <=1000000
		}]

		filters?: list.MaxItems(16) & [...{
			cors?: {
				allowCredentials?: bool

				allowHeaders?: list.MaxItems(64) & [...strings.MaxRunes(256) & strings.MinRunes(1) & =~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"]

				allowMethods?: list.MaxItems(9) & [..."GET" | "HEAD" | "POST" | "PUT" | "DELETE" | "CONNECT" | "OPTIONS" | "TRACE" | "PATCH" | "*"]

				allowOrigins?: list.MaxItems(64) & [...strings.MaxRunes(253) & strings.MinRunes(1) & =~"(^\\*$)|(^(http(s)?):\\/\\/(((\\*\\.)?([a-zA-Z0-9\\-]+\\.)*[a-zA-Z0-9-]+|\\*)(:([0-9]{1,5}))?)$)"]

				exposeHeaders?: list.MaxItems(64) & [...strings.MaxRunes(256) & strings.MinRunes(1) & =~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"]

				maxAge?: uint & >=1 & <=2147483647
			}

			extensionRef?: {
				group!: strings.MaxRunes(253) & {
					=~"^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
				}

				kind!: strings.MaxRunes(63) & strings.MinRunes(1) & {
					=~"^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
				}

				name!: strings.MaxRunes(253) & strings.MinRunes(1)
			}

			requestHeaderModifier?: {
				add?: list.MaxItems(16) & [...{
					name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
						=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
					}

					value!: strings.MaxRunes(4096) & strings.MinRunes(1)
				}]

				remove?: list.MaxItems(16) & [...string]

				set?: list.MaxItems(16) & [...{
					name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
						=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
					}

					value!: strings.MaxRunes(4096) & strings.MinRunes(1)
				}]
			}

			requestMirror?: {
				backendRef!: {
					group?: strings.MaxRunes(253) & {
						=~"^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
					}

					kind?: strings.MaxRunes(63) & strings.MinRunes(1) & {
						=~"^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
					}

					name!: strings.MaxRunes(253) & strings.MinRunes(1)

					namespace?: strings.MaxRunes(63) & strings.MinRunes(1) & {
						=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
					}

					port?: uint & >=1 & <=65535
				}

				fraction?: {
					denominator?: uint & >=1 & <=2147483647
					numerator!:   uint & <=2147483647
				}

				percent?: uint & <=100
			}

			requestRedirect?: {
				hostname?: strings.MaxRunes(253) & strings.MinRunes(1) & {
					=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
				}

				path?: {
					replaceFullPath?: strings.MaxRunes(1024)

					replacePrefixMatch?: strings.MaxRunes(1024)

					type!: "ReplaceFullPath" | "ReplacePrefixMatch"
				}

				port?: uint & >=1 & <=65535

				scheme?: "http" | "https"

				statusCode?: (301 | 302 | 303 | 307 | 308) & {
					int
				}
			}

			responseHeaderModifier?: {
				add?: list.MaxItems(16) & [...{
					name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
						=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
					}

					value!: strings.MaxRunes(4096) & strings.MinRunes(1)
				}]

				remove?: list.MaxItems(16) & [...string]

				set?: list.MaxItems(16) & [...{
					name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
						=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
					}

					value!: strings.MaxRunes(4096) & strings.MinRunes(1)
				}]
			}

			type!: "RequestHeaderModifier" | "ResponseHeaderModifier" | "RequestMirror" | "RequestRedirect" | "URLRewrite" | "ExtensionRef" | "CORS"

			urlRewrite?: {
				hostname?: strings.MaxRunes(253) & strings.MinRunes(1) & {
					=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
				}

				path?: {
					replaceFullPath?: strings.MaxRunes(1024)

					replacePrefixMatch?: strings.MaxRunes(1024)

					type!: "ReplaceFullPath" | "ReplacePrefixMatch"
				}
			}
		}]

		matches?: list.MaxItems(64) & [...{
			headers?: list.MaxItems(16) & [...{
				name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
					=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
				}

				type?: "Exact" | "RegularExpression"

				value!: strings.MaxRunes(4096) & strings.MinRunes(1)
			}]

			method?: "GET" | "HEAD" | "POST" | "PUT" | "DELETE" | "CONNECT" | "OPTIONS" | "TRACE" | "PATCH"

			path?: {
				type?: "Exact" | "PathPrefix" | "RegularExpression"

				value?: strings.MaxRunes(1024)
			}

			queryParams?: list.MaxItems(16) & [...{
				name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
					=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
				}

				type?: "Exact" | "RegularExpression"

				value!: strings.MaxRunes(1024) & strings.MinRunes(1)
			}]
		}]

		name?: strings.MaxRunes(253) & strings.MinRunes(1) & {
			=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
		}

		timeouts?: {
			backendRequest?: =~"^([0-9]{1,5}(h|m|s|ms)){1,4}$"

			request?: =~"^([0-9]{1,5}(h|m|s|ms)){1,4}$"
		}
	}] & [_, ...]
}
