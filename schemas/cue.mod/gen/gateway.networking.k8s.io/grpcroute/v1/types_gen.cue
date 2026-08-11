

package v1

import (
	"strings"
	"list"
)

#GRPCRoute: {
	apiVersion: "gateway.networking.k8s.io/v1"

	kind: "GRPCRoute"
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

	spec!: #GRPCRouteSpec
}

#GRPCRouteSpec: {
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

				type!: "ResponseHeaderModifier" | "RequestHeaderModifier" | "RequestMirror" | "ExtensionRef"
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

			type!: "ResponseHeaderModifier" | "RequestHeaderModifier" | "RequestMirror" | "ExtensionRef"
		}]

		matches?: list.MaxItems(64) & [...{
			headers?: list.MaxItems(16) & [...{
				name!: strings.MaxRunes(256) & strings.MinRunes(1) & {
					=~"^[A-Za-z0-9!#$%&'*+\\-.^_\\x60|~]+$"
				}

				type?: "Exact" | "RegularExpression"

				value!: strings.MaxRunes(4096) & strings.MinRunes(1)
			}]

			method?: {
				method?: strings.MaxRunes(1024)

				service?: strings.MaxRunes(1024)

				type?: "Exact" | "RegularExpression"
			}
		}]

		name?: strings.MaxRunes(253) & strings.MinRunes(1) & {
			=~"^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
		}
	}]
}
