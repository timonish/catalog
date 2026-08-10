

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
