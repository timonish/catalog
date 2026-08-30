

package v1

import "strings"

#Certificate: {
	apiVersion: "cert-manager.io/v1"

	kind: "Certificate"
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

	spec!: #CertificateSpec
}

#CertificateSpec: {
	additionalOutputFormats?: [...{
		type!: "DER" | "CombinedPEM"
	}]

	commonName?: string

	dnsNames?: [...string]

	duration?: string

	emailAddresses?: [...string]

	encodeUsagesInRequest?: bool

	ipAddresses?: [...string]

	isCA?: bool

	issuerRef!: {
		group?: string

		kind?: string

		name!: string
	}

	keystores?: {
		jks?: {
			alias?: string

			create!: bool

			password?: string

			passwordSecretRef?: {
				key?: string

				name!: string
			}
		}

		pkcs12?: {
			create!: bool

			password?: string

			passwordSecretRef?: {
				key?: string

				name!: string
			}

			profile?: "LegacyRC2" | "LegacyDES" | "Modern2023" | "Modern2026"
		}
	}

	literalSubject?: string

	nameConstraints?: {
		critical?: bool

		excluded?: {
			dnsDomains?: [...string]

			emailAddresses?: [...string]

			ipRanges?: [...string]

			uriDomains?: [...string]
		}

		permitted?: {
			dnsDomains?: [...string]

			emailAddresses?: [...string]

			ipRanges?: [...string]

			uriDomains?: [...string]
		}
	}

	otherNames?: [...{
		oid?: string

		utf8Value?: string
	}]

	privateKey?: {
		algorithm?: "RSA" | "ECDSA" | "Ed25519"

		encoding?: "PKCS1" | "PKCS8"

		rotationPolicy?: "Never" | "Always"

		size?: int
	}

	renewBefore?: string

	renewBeforePercentage?: int32

	renewal?: {
		policy?: "RenewBefore" | "Disabled"

		windows?: [...{
			cron!: strings.MinRunes(1)

			timezone?: strings.MinRunes(1)

			windowDuration!: =~"^([0-9]+(\\.[0-9]+)?(s|m|h))+$"
		}]
	}

	revisionHistoryLimit?: int32

	secretName!: string

	secretTemplate?: {
		annotations?: {
			[string]: string
		}

		labels?: {
			[string]: string
		}
	}

	signatureAlgorithm?: "SHA256WithRSA" | "SHA384WithRSA" | "SHA512WithRSA" | "ECDSAWithSHA256" | "ECDSAWithSHA384" | "ECDSAWithSHA512" | "PureEd25519"

	subject?: {
		countries?: [...string]

		localities?: [...string]

		organizationalUnits?: [...string]

		organizations?: [...string]

		postalCodes?: [...string]

		provinces?: [...string]

		serialNumber?: string

		streetAddresses?: [...string]
	}

	uris?: [...string]

	usages?: [..."signing" | "digital signature" | "content commitment" | "key encipherment" | "key agreement" | "data encipherment" | "cert sign" | "crl sign" | "encipher only" | "decipher only" | "any" | "server auth" | "client auth" | "code signing" | "email protection" | "s/mime" | "ipsec end system" | "ipsec tunnel" | "ipsec user" | "timestamping" | "ocsp signing" | "microsoft sgc" | "netscape sgc"]
}

_crd: {
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		name: "certificates.cert-manager.io"
	}
	spec: {
		group: "cert-manager.io"
		names: {
			categories: ["cert-manager"]
			kind:     "Certificate"
			listKind: "CertificateList"
			plural:   "certificates"
			shortNames: ["cert", "certs"]
			singular: "certificate"
		}
		scope: "Namespaced"
		versions: [{
			name:    "v1"
			served:  true
			storage: true
			schema: {
				openAPIV3Schema: {
					properties: {
						apiVersion: {
							type: "string"
						}
						kind: {
							type: "string"
						}
						metadata: {
							type: "object"
						}
						spec: {
							properties: {
								additionalOutputFormats: {
									items: {
										properties: {
											type: {
												enum: ["DER", "CombinedPEM"]
												type: "string"
											}
										}
										required: ["type"]
										type: "object"
									}
									type:                     "array"
									"x-kubernetes-list-type": "atomic"
								}
								commonName: {
									type: "string"
								}
								dnsNames: {
									items: {
										type: "string"
									}
									type:                     "array"
									"x-kubernetes-list-type": "atomic"
								}
								duration: {
									type: "string"
								}
								emailAddresses: {
									items: {
										type: "string"
									}
									type:                     "array"
									"x-kubernetes-list-type": "atomic"
								}
								encodeUsagesInRequest: {
									type: "boolean"
								}
								ipAddresses: {
									items: {
										type: "string"
									}
									type:                     "array"
									"x-kubernetes-list-type": "atomic"
								}
								isCA: {
									type: "boolean"
								}
								issuerRef: {
									properties: {
										group: {
											type: "string"
										}
										kind: {
											type: "string"
										}
										name: {
											type: "string"
										}
									}
									required: ["name"]
									type: "object"
								}
								keystores: {
									properties: {
										jks: {
											properties: {
												alias: {
													type: "string"
												}
												create: {
													type: "boolean"
												}
												password: {
													type: "string"
												}
												passwordSecretRef: {
													properties: {
														key: {
															type: "string"
														}
														name: {
															type: "string"
														}
													}
													required: ["name"]
													type: "object"
												}
											}
											required: ["create"]
											type: "object"
										}
										pkcs12: {
											properties: {
												create: {
													type: "boolean"
												}
												password: {
													type: "string"
												}
												passwordSecretRef: {
													properties: {
														key: {
															type: "string"
														}
														name: {
															type: "string"
														}
													}
													required: ["name"]
													type: "object"
												}
												profile: {
													enum: ["LegacyRC2", "LegacyDES", "Modern2023", "Modern2026"]
													type: "string"
												}
											}
											required: ["create"]
											type: "object"
										}
									}
									type: "object"
								}
								literalSubject: {
									type: "string"
								}
								nameConstraints: {
									properties: {
										critical: {
											type: "boolean"
										}
										excluded: {
											properties: {
												dnsDomains: {
													items: {
														type: "string"
													}
													type:                     "array"
													"x-kubernetes-list-type": "atomic"
												}
												emailAddresses: {
													items: {
														type: "string"
													}
													type:                     "array"
													"x-kubernetes-list-type": "atomic"
												}
												ipRanges: {
													items: {
														type: "string"
													}
													type:                     "array"
													"x-kubernetes-list-type": "atomic"
												}
												uriDomains: {
													items: {
														type: "string"
													}
													type:                     "array"
													"x-kubernetes-list-type": "atomic"
												}
											}
											type: "object"
										}
										permitted: {
											properties: {
												dnsDomains: {
													items: {
														type: "string"
													}
													type:                     "array"
													"x-kubernetes-list-type": "atomic"
												}
												emailAddresses: {
													items: {
														type: "string"
													}
													type:                     "array"
													"x-kubernetes-list-type": "atomic"
												}
												ipRanges: {
													items: {
														type: "string"
													}
													type:                     "array"
													"x-kubernetes-list-type": "atomic"
												}
												uriDomains: {
													items: {
														type: "string"
													}
													type:                     "array"
													"x-kubernetes-list-type": "atomic"
												}
											}
											type: "object"
										}
									}
									type: "object"
								}
								otherNames: {
									items: {
										properties: {
											oid: {
												type: "string"
											}
											utf8Value: {
												type: "string"
											}
										}
										type: "object"
									}
									type:                     "array"
									"x-kubernetes-list-type": "atomic"
								}
								privateKey: {
									properties: {
										algorithm: {
											enum: ["RSA", "ECDSA", "Ed25519"]
											type: "string"
										}
										encoding: {
											enum: ["PKCS1", "PKCS8"]
											type: "string"
										}
										rotationPolicy: {
											enum: ["Never", "Always"]
											type: "string"
										}
										size: {
											type: "integer"
										}
									}
									type: "object"
								}
								renewBefore: {
									type: "string"
								}
								renewBeforePercentage: {
									format: "int32"
									type:   "integer"
								}
								renewal: {
									properties: {
										policy: {
											enum: ["RenewBefore", "Disabled"]
											type: "string"
										}
										windows: {
											items: {
												properties: {
													cron: {
														minLength: 1
														type:      "string"
													}
													timezone: {
														minLength: 1
														type:      "string"
													}
													windowDuration: {
														pattern: "^([0-9]+(\\.[0-9]+)?(s|m|h))+$"
														type:    "string"
													}
												}
												required: ["cron", "windowDuration"]
												type: "object"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
									}
									type: "object"
								}
								revisionHistoryLimit: {
									format: "int32"
									type:   "integer"
								}
								secretName: {
									type: "string"
								}
								secretTemplate: {
									properties: {
										annotations: {
											additionalProperties: {
												type: "string"
											}
											type: "object"
										}
										labels: {
											additionalProperties: {
												type: "string"
											}
											type: "object"
										}
									}
									type: "object"
								}
								signatureAlgorithm: {
									enum: ["SHA256WithRSA", "SHA384WithRSA", "SHA512WithRSA", "ECDSAWithSHA256", "ECDSAWithSHA384", "ECDSAWithSHA512", "PureEd25519"]
									type: "string"
								}
								subject: {
									properties: {
										countries: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
										localities: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
										organizationalUnits: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
										organizations: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
										postalCodes: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
										provinces: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
										serialNumber: {
											type: "string"
										}
										streetAddresses: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
									}
									type: "object"
								}
								uris: {
									items: {
										type: "string"
									}
									type:                     "array"
									"x-kubernetes-list-type": "atomic"
								}
								usages: {
									items: {
										enum: ["signing", "digital signature", "content commitment", "key encipherment", "key agreement", "data encipherment", "cert sign", "crl sign", "encipher only", "decipher only", "any", "server auth", "client auth", "code signing", "email protection", "s/mime", "ipsec end system", "ipsec tunnel", "ipsec user", "timestamping", "ocsp signing", "microsoft sgc", "netscape sgc"]
										type: "string"
									}
									type:                     "array"
									"x-kubernetes-list-type": "atomic"
								}
							}
							required: ["issuerRef", "secretName"]
							type: "object"
						}
						status: {
							properties: {
								acme: {
									properties: {
										ari: {
											properties: {
												explanationURL: {
													type: "string"
												}
												lastChecked: {
													format: "date-time"
													type:   "string"
												}
												lastError: {
													type: "string"
												}
												nextCheck: {
													format: "date-time"
													type:   "string"
												}
												suggestedWindow: {
													properties: {
														end: {
															format: "date-time"
															type:   "string"
														}
														start: {
															format: "date-time"
															type:   "string"
														}
													}
													required: ["end", "start"]
													type: "object"
												}
											}
											type: "object"
										}
									}
									type: "object"
								}
								conditions: {
									items: {
										properties: {
											lastTransitionTime: {
												format: "date-time"
												type:   "string"
											}
											message: {
												type: "string"
											}
											observedGeneration: {
												format: "int64"
												type:   "integer"
											}
											reason: {
												type: "string"
											}
											status: {
												enum: ["True", "False", "Unknown"]
												type: "string"
											}
											type: {
												type: "string"
											}
										}
										required: ["status", "type"]
										type: "object"
									}
									type: "array"
									"x-kubernetes-list-map-keys": ["type"]
									"x-kubernetes-list-type": "map"
								}
								failedIssuanceAttempts: {
									type: "integer"
								}
								lastFailureTime: {
									format: "date-time"
									type:   "string"
								}
								nextPrivateKeySecretName: {
									type: "string"
								}
								notAfter: {
									format: "date-time"
									type:   "string"
								}
								notBefore: {
									format: "date-time"
									type:   "string"
								}
								renewalTime: {
									format: "date-time"
									type:   "string"
								}
								revision: {
									type: "integer"
								}
							}
							type: "object"
						}
					}
					type: "object"
				}
			}
			subresources: {
				status: {}
			}
		}]
	}
}
