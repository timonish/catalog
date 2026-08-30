

package v1

import "strings"

#Issuer: {
	apiVersion: "cert-manager.io/v1"

	kind: "Issuer"
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

	spec!: #IssuerSpec
}

#IssuerSpec: {
	acme?: {
		caBundle?: string

		disableAccountKeyGeneration?: bool

		email?: string

		enableDurationFeature?: bool

		externalAccountBinding?: {
			keyAlgorithm?: "HS256" | "HS384" | "HS512"

			keyID!: string

			keySecretRef!: {
				key?: string

				name!: string
			}
		}

		preferredChain?: strings.MaxRunes(64)

		privateKeySecretRef!: {
			key?: string

			name!: string
		}

		profile?: string

		server!: string

		skipTLSVerify?: bool

		solvers?: [...{
			dns01?: {
				acmeDNS?: {
					accountSecretRef!: {
						key?: string

						name!: string
					}
					host!: string
				}

				akamai?: {
					accessTokenSecretRef!: {
						key?: string

						name!: string
					}

					clientSecretSecretRef!: {
						key?: string

						name!: string
					}

					clientTokenSecretRef!: {
						key?: string

						name!: string
					}
					serviceConsumerDomain!: string
				}

				azureDNS?: {
					clientID?: string

					clientSecretSecretRef?: {
						key?: string

						name!: string
					}

					environment?: "AzurePublicCloud" | "AzureChinaCloud" | "AzureGermanCloud" | "AzureUSGovernmentCloud"

					hostedZoneName?: string

					managedIdentity?: {
						clientID?: string

						resourceID?: string

						tenantID?: string
					}

					resourceGroupName!: string

					subscriptionID!: string

					tenantID?: string

					zoneType?: "AzurePublicZone" | "AzurePrivateZone"
				}

				cloudDNS?: {
					hostedZoneName?: string
					project!:        string

					serviceAccountSecretRef?: {
						key?: string

						name!: string
					}
				}

				cloudflare?: {
					apiKeySecretRef?: {
						key?: string

						name!: string
					}

					apiTokenSecretRef?: {
						key?: string

						name!: string
					}

					email?: string
				}

				cnameStrategy?: "None" | "Follow"
				digitalocean?: {
					tokenSecretRef!: {
						key?: string

						name!: string
					}
				}

				rfc2136?: {
					nameserver!: string

					protocol?: "TCP" | "UDP"

					tsigAlgorithm?: string

					tsigKeyName?: string

					tsigSecretSecretRef?: {
						key?: string

						name!: string
					}
				}

				route53?: {
					accessKeyID?: string

					accessKeyIDSecretRef?: {
						key?: string

						name!: string
					}
					auth?: {
						kubernetes!: {
							serviceAccountRef!: {
								audiences?: [...string]

								name!: string
							}
						}
					}

					hostedZoneID?: string

					region?: string

					role?: string

					secretAccessKeySecretRef?: {
						key?: string

						name!: string
					}
				}

				webhook?: {
					config?: _

					groupName!: string

					solverName!: string
				}
			}

			http01?: {
				gatewayHTTPRoute?: {
					labels?: {
						[string]: string
					}

					parentRefs?: [...{
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

					podTemplate?: {
						metadata?: {
							annotations?: {
								[string]: string
							}

							labels?: {
								[string]: string
							}
						}

						spec?: {
							affinity?: {
								nodeAffinity?: {
									preferredDuringSchedulingIgnoredDuringExecution?: [...{
										preference!: {
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchFields?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]
										}

										weight!: int32
									}]
									requiredDuringSchedulingIgnoredDuringExecution?: {
										nodeSelectorTerms!: [...{
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchFields?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]
										}]
									}
								}

								podAffinity?: {
									preferredDuringSchedulingIgnoredDuringExecution?: [...{
										podAffinityTerm!: {
											labelSelector?: {
												matchExpressions?: [...{
													key!: string

													operator!: string

													values?: [...string]
												}]

												matchLabels?: {
													[string]: string
												}
											}

											matchLabelKeys?: [...string]

											mismatchLabelKeys?: [...string]

											namespaceSelector?: {
												matchExpressions?: [...{
													key!: string

													operator!: string

													values?: [...string]
												}]

												matchLabels?: {
													[string]: string
												}
											}

											namespaces?: [...string]

											topologyKey!: string
										}

										weight!: int32
									}]

									requiredDuringSchedulingIgnoredDuringExecution?: [...{
										labelSelector?: {
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchLabels?: {
												[string]: string
											}
										}

										matchLabelKeys?: [...string]

										mismatchLabelKeys?: [...string]

										namespaceSelector?: {
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchLabels?: {
												[string]: string
											}
										}

										namespaces?: [...string]

										topologyKey!: string
									}]
								}

								podAntiAffinity?: {
									preferredDuringSchedulingIgnoredDuringExecution?: [...{
										podAffinityTerm!: {
											labelSelector?: {
												matchExpressions?: [...{
													key!: string

													operator!: string

													values?: [...string]
												}]

												matchLabels?: {
													[string]: string
												}
											}

											matchLabelKeys?: [...string]

											mismatchLabelKeys?: [...string]

											namespaceSelector?: {
												matchExpressions?: [...{
													key!: string

													operator!: string

													values?: [...string]
												}]

												matchLabels?: {
													[string]: string
												}
											}

											namespaces?: [...string]

											topologyKey!: string
										}

										weight!: int32
									}]

									requiredDuringSchedulingIgnoredDuringExecution?: [...{
										labelSelector?: {
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchLabels?: {
												[string]: string
											}
										}

										matchLabelKeys?: [...string]

										mismatchLabelKeys?: [...string]

										namespaceSelector?: {
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchLabels?: {
												[string]: string
											}
										}

										namespaces?: [...string]

										topologyKey!: string
									}]
								}
							}

							imagePullSecrets?: [...{
								name?: string
							}]

							nodeSelector?: {
								[string]: string
							}

							priorityClassName?: string

							resources?: {
								limits?: {
									[string]: matchN(>=1, [int, string]) & (number | =~"^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$")
								}

								requests?: {
									[string]: matchN(>=1, [int, string]) & (number | =~"^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$")
								}
							}

							securityContext?: {
								fsGroup?: int64

								fsGroupChangePolicy?: string

								runAsGroup?: int64

								runAsNonRoot?: bool

								runAsUser?: int64

								seLinuxOptions?: {
									level?: string

									role?: string

									type?: string

									user?: string
								}

								seccompProfile?: {
									localhostProfile?: string

									type!: string
								}

								supplementalGroups?: [...int & int64]

								sysctls?: [...{
									name!: string

									value!: string
								}]
							}

							serviceAccountName?: string

							tolerations?: [...{
								effect?: string

								key?: string

								operator?: string

								tolerationSeconds?: int64

								value?: string
							}]
						}
					}

					serviceType?: string
				}

				ingress?: {
					class?: string

					ingressClassName?: string
					ingressTemplate?: {
						metadata?: {
							annotations?: {
								[string]: string
							}

							labels?: {
								[string]: string
							}
						}
					}

					name?: string

					podTemplate?: {
						metadata?: {
							annotations?: {
								[string]: string
							}

							labels?: {
								[string]: string
							}
						}

						spec?: {
							affinity?: {
								nodeAffinity?: {
									preferredDuringSchedulingIgnoredDuringExecution?: [...{
										preference!: {
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchFields?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]
										}

										weight!: int32
									}]
									requiredDuringSchedulingIgnoredDuringExecution?: {
										nodeSelectorTerms!: [...{
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchFields?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]
										}]
									}
								}

								podAffinity?: {
									preferredDuringSchedulingIgnoredDuringExecution?: [...{
										podAffinityTerm!: {
											labelSelector?: {
												matchExpressions?: [...{
													key!: string

													operator!: string

													values?: [...string]
												}]

												matchLabels?: {
													[string]: string
												}
											}

											matchLabelKeys?: [...string]

											mismatchLabelKeys?: [...string]

											namespaceSelector?: {
												matchExpressions?: [...{
													key!: string

													operator!: string

													values?: [...string]
												}]

												matchLabels?: {
													[string]: string
												}
											}

											namespaces?: [...string]

											topologyKey!: string
										}

										weight!: int32
									}]

									requiredDuringSchedulingIgnoredDuringExecution?: [...{
										labelSelector?: {
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchLabels?: {
												[string]: string
											}
										}

										matchLabelKeys?: [...string]

										mismatchLabelKeys?: [...string]

										namespaceSelector?: {
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchLabels?: {
												[string]: string
											}
										}

										namespaces?: [...string]

										topologyKey!: string
									}]
								}

								podAntiAffinity?: {
									preferredDuringSchedulingIgnoredDuringExecution?: [...{
										podAffinityTerm!: {
											labelSelector?: {
												matchExpressions?: [...{
													key!: string

													operator!: string

													values?: [...string]
												}]

												matchLabels?: {
													[string]: string
												}
											}

											matchLabelKeys?: [...string]

											mismatchLabelKeys?: [...string]

											namespaceSelector?: {
												matchExpressions?: [...{
													key!: string

													operator!: string

													values?: [...string]
												}]

												matchLabels?: {
													[string]: string
												}
											}

											namespaces?: [...string]

											topologyKey!: string
										}

										weight!: int32
									}]

									requiredDuringSchedulingIgnoredDuringExecution?: [...{
										labelSelector?: {
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchLabels?: {
												[string]: string
											}
										}

										matchLabelKeys?: [...string]

										mismatchLabelKeys?: [...string]

										namespaceSelector?: {
											matchExpressions?: [...{
												key!: string

												operator!: string

												values?: [...string]
											}]

											matchLabels?: {
												[string]: string
											}
										}

										namespaces?: [...string]

										topologyKey!: string
									}]
								}
							}

							imagePullSecrets?: [...{
								name?: string
							}]

							nodeSelector?: {
								[string]: string
							}

							priorityClassName?: string

							resources?: {
								limits?: {
									[string]: matchN(>=1, [int, string]) & (number | =~"^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$")
								}

								requests?: {
									[string]: matchN(>=1, [int, string]) & (number | =~"^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$")
								}
							}

							securityContext?: {
								fsGroup?: int64

								fsGroupChangePolicy?: string

								runAsGroup?: int64

								runAsNonRoot?: bool

								runAsUser?: int64

								seLinuxOptions?: {
									level?: string

									role?: string

									type?: string

									user?: string
								}

								seccompProfile?: {
									localhostProfile?: string

									type!: string
								}

								supplementalGroups?: [...int & int64]

								sysctls?: [...{
									name!: string

									value!: string
								}]
							}

							serviceAccountName?: string

							tolerations?: [...{
								effect?: string

								key?: string

								operator?: string

								tolerationSeconds?: int64

								value?: string
							}]
						}
					}

					serviceType?: string
				}
			}

			selector?: {
				dnsNames?: [...string]

				dnsZones?: [...string]

				matchLabels?: {
					[string]: string
				}
			}

			waitInsteadOfSelfCheck?: string
		}]
	}

	ca?: {
		crlDistributionPoints?: [...string]

		issuingCertificateURLs?: [...string]

		ocspServers?: [...string]

		secretName!: string
	}
	selfSigned?: {
		crlDistributionPoints?: [...string]
	}

	vault?: {
		auth!: {
			appRole?: {
				path!: string

				roleId!: string

				secretRef!: {
					key?: string

					name!: string
				}
			}

			aws?: {
				iamRoleArn?: string

				mountPath?: string

				region?: string

				role!: strings.MinRunes(1)

				serviceAccountRef?: {
					audiences?: [...string]

					name!: string
				}

				vaultHeaderValue?: string
			}

			clientCertificate?: {
				mountPath?: string

				name?: string

				secretName?: string
			}

			kubernetes?: {
				mountPath?: string

				role!: string

				secretRef?: {
					key?: string

					name!: string
				}

				serviceAccountRef?: {
					audiences?: [...string]

					name!: string
				}
			}

			tokenSecretRef?: {
				key?: string

				name!: string
			}
		}

		caBundle?: string

		caBundleSecretRef?: {
			key?: string

			name!: string
		}

		clientCertSecretRef?: {
			key?: string

			name!: string
		}

		clientKeySecretRef?: {
			key?: string

			name!: string
		}

		namespace?: string

		path!: string

		server!: string

		serverName?: string
	}

	venafi?: {
		cloud?: {
			apiTokenSecretRef!: {
				key?: string

				name!: string
			}

			url?: string
		}

		ngts?: {
			credentialsRef!: {
				name!: string
			}

			tokenEndpoint?: string

			tsgID!: string

			url?: string
		}

		tpp?: {
			caBundle?: string

			caBundleSecretRef?: {
				key?: string

				name!: string
			}
			credentialsRef!: {
				name!: string
			}

			url!: string
		}

		zone!: string
	}
}

_crd: {
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: {
		name: "issuers.cert-manager.io"
	}
	spec: {
		group: "cert-manager.io"
		names: {
			categories: ["cert-manager"]
			kind:     "Issuer"
			listKind: "IssuerList"
			plural:   "issuers"
			shortNames: ["iss"]
			singular: "issuer"
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
								acme: {
									properties: {
										caBundle: {
											format: "byte"
											type:   "string"
										}
										disableAccountKeyGeneration: {
											type: "boolean"
										}
										email: {
											type: "string"
										}
										enableDurationFeature: {
											type: "boolean"
										}
										externalAccountBinding: {
											properties: {
												keyAlgorithm: {
													enum: ["HS256", "HS384", "HS512"]
													type: "string"
												}
												keyID: {
													type: "string"
												}
												keySecretRef: {
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
											required: ["keyID", "keySecretRef"]
											type: "object"
										}
										preferredChain: {
											maxLength: 64
											type:      "string"
										}
										privateKeySecretRef: {
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
											type: "string"
										}
										server: {
											type: "string"
										}
										skipTLSVerify: {
											type: "boolean"
										}
										solvers: {
											items: {
												properties: {
													dns01: {
														properties: {
															acmeDNS: {
																properties: {
																	accountSecretRef: {
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
																	host: {
																		type: "string"
																	}
																}
																required: ["accountSecretRef", "host"]
																type: "object"
															}
															akamai: {
																properties: {
																	accessTokenSecretRef: {
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
																	clientSecretSecretRef: {
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
																	clientTokenSecretRef: {
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
																	serviceConsumerDomain: {
																		type: "string"
																	}
																}
																required: ["accessTokenSecretRef", "clientSecretSecretRef", "clientTokenSecretRef", "serviceConsumerDomain"]
																type: "object"
															}
															azureDNS: {
																properties: {
																	clientID: {
																		type: "string"
																	}
																	clientSecretSecretRef: {
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
																	environment: {
																		enum: ["AzurePublicCloud", "AzureChinaCloud", "AzureGermanCloud", "AzureUSGovernmentCloud"]
																		type: "string"
																	}
																	hostedZoneName: {
																		type: "string"
																	}
																	managedIdentity: {
																		properties: {
																			clientID: {
																				type: "string"
																			}
																			resourceID: {
																				type: "string"
																			}
																			tenantID: {
																				type: "string"
																			}
																		}
																		type: "object"
																	}
																	resourceGroupName: {
																		type: "string"
																	}
																	subscriptionID: {
																		type: "string"
																	}
																	tenantID: {
																		type: "string"
																	}
																	zoneType: {
																		enum: ["AzurePublicZone", "AzurePrivateZone"]
																		type: "string"
																	}
																}
																required: ["resourceGroupName", "subscriptionID"]
																type: "object"
															}
															cloudDNS: {
																properties: {
																	hostedZoneName: {
																		type: "string"
																	}
																	project: {
																		type: "string"
																	}
																	serviceAccountSecretRef: {
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
																required: ["project"]
																type: "object"
															}
															cloudflare: {
																properties: {
																	apiKeySecretRef: {
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
																	apiTokenSecretRef: {
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
																	email: {
																		type: "string"
																	}
																}
																type: "object"
															}
															cnameStrategy: {
																enum: ["None", "Follow"]
																type: "string"
															}
															digitalocean: {
																properties: {
																	tokenSecretRef: {
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
																required: ["tokenSecretRef"]
																type: "object"
															}
															rfc2136: {
																properties: {
																	nameserver: {
																		type: "string"
																	}
																	protocol: {
																		enum: ["TCP", "UDP"]
																		type: "string"
																	}
																	tsigAlgorithm: {
																		type: "string"
																	}
																	tsigKeyName: {
																		type: "string"
																	}
																	tsigSecretSecretRef: {
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
																required: ["nameserver"]
																type: "object"
															}
															route53: {
																properties: {
																	accessKeyID: {
																		type: "string"
																	}
																	accessKeyIDSecretRef: {
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
																	auth: {
																		properties: {
																			kubernetes: {
																				properties: {
																					serviceAccountRef: {
																						properties: {
																							audiences: {
																								items: {
																									type: "string"
																								}
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																							name: {
																								type: "string"
																							}
																						}
																						required: ["name"]
																						type: "object"
																					}
																				}
																				required: ["serviceAccountRef"]
																				type: "object"
																			}
																		}
																		required: ["kubernetes"]
																		type: "object"
																	}
																	hostedZoneID: {
																		type: "string"
																	}
																	region: {
																		type: "string"
																	}
																	role: {
																		type: "string"
																	}
																	secretAccessKeySecretRef: {
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
																type: "object"
															}
															webhook: {
																properties: {
																	config: {
																		"x-kubernetes-preserve-unknown-fields": true
																	}
																	groupName: {
																		type: "string"
																	}
																	solverName: {
																		type: "string"
																	}
																}
																required: ["groupName", "solverName"]
																type: "object"
															}
														}
														type: "object"
													}
													http01: {
														properties: {
															gatewayHTTPRoute: {
																properties: {
																	labels: {
																		additionalProperties: {
																			type: "string"
																		}
																		type: "object"
																	}
																	parentRefs: {
																		items: {
																			properties: {
																				group: {
																					default:   "gateway.networking.k8s.io"
																					maxLength: 253
																					pattern:   "^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																					type:      "string"
																				}
																				kind: {
																					default:   "Gateway"
																					maxLength: 63
																					minLength: 1
																					pattern:   "^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$"
																					type:      "string"
																				}
																				name: {
																					maxLength: 253
																					minLength: 1
																					type:      "string"
																				}
																				namespace: {
																					maxLength: 63
																					minLength: 1
																					pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$"
																					type:      "string"
																				}
																				port: {
																					format:  "int32"
																					maximum: 65535
																					minimum: 1
																					type:    "integer"
																				}
																				sectionName: {
																					maxLength: 253
																					minLength: 1
																					pattern:   "^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$"
																					type:      "string"
																				}
																			}
																			required: ["name"]
																			type: "object"
																		}
																		type:                     "array"
																		"x-kubernetes-list-type": "atomic"
																	}
																	podTemplate: {
																		properties: {
																			metadata: {
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
																			spec: {
																				properties: {
																					affinity: {
																						properties: {
																							nodeAffinity: {
																								properties: {
																									preferredDuringSchedulingIgnoredDuringExecution: {
																										items: {
																											properties: {
																												preference: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchFields: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												weight: {
																													format: "int32"
																													type:   "integer"
																												}
																											}
																											required: ["preference", "weight"]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									requiredDuringSchedulingIgnoredDuringExecution: {
																										properties: {
																											nodeSelectorTerms: {
																												items: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchFields: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: ["nodeSelectorTerms"]
																										type:                    "object"
																										"x-kubernetes-map-type": "atomic"
																									}
																								}
																								type: "object"
																							}
																							podAffinity: {
																								properties: {
																									preferredDuringSchedulingIgnoredDuringExecution: {
																										items: {
																											properties: {
																												podAffinityTerm: {
																													properties: {
																														labelSelector: {
																															properties: {
																																matchExpressions: {
																																	items: {
																																		properties: {
																																			key: {
																																				type: "string"
																																			}
																																			operator: {
																																				type: "string"
																																			}
																																			values: {
																																				items: {
																																					type: "string"
																																				}
																																				type:                     "array"
																																				"x-kubernetes-list-type": "atomic"
																																			}
																																		}
																																		required: ["key", "operator"]
																																		type: "object"
																																	}
																																	type:                     "array"
																																	"x-kubernetes-list-type": "atomic"
																																}
																																matchLabels: {
																																	additionalProperties: {
																																		type: "string"
																																	}
																																	type: "object"
																																}
																															}
																															type:                    "object"
																															"x-kubernetes-map-type": "atomic"
																														}
																														matchLabelKeys: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														mismatchLabelKeys: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														namespaceSelector: {
																															properties: {
																																matchExpressions: {
																																	items: {
																																		properties: {
																																			key: {
																																				type: "string"
																																			}
																																			operator: {
																																				type: "string"
																																			}
																																			values: {
																																				items: {
																																					type: "string"
																																				}
																																				type:                     "array"
																																				"x-kubernetes-list-type": "atomic"
																																			}
																																		}
																																		required: ["key", "operator"]
																																		type: "object"
																																	}
																																	type:                     "array"
																																	"x-kubernetes-list-type": "atomic"
																																}
																																matchLabels: {
																																	additionalProperties: {
																																		type: "string"
																																	}
																																	type: "object"
																																}
																															}
																															type:                    "object"
																															"x-kubernetes-map-type": "atomic"
																														}
																														namespaces: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														topologyKey: {
																															type: "string"
																														}
																													}
																													required: ["topologyKey"]
																													type: "object"
																												}
																												weight: {
																													format: "int32"
																													type:   "integer"
																												}
																											}
																											required: ["podAffinityTerm", "weight"]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									requiredDuringSchedulingIgnoredDuringExecution: {
																										items: {
																											properties: {
																												labelSelector: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchLabels: {
																															additionalProperties: {
																																type: "string"
																															}
																															type: "object"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												matchLabelKeys: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												mismatchLabelKeys: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												namespaceSelector: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchLabels: {
																															additionalProperties: {
																																type: "string"
																															}
																															type: "object"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												namespaces: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												topologyKey: {
																													type: "string"
																												}
																											}
																											required: ["topologyKey"]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																								}
																								type: "object"
																							}
																							podAntiAffinity: {
																								properties: {
																									preferredDuringSchedulingIgnoredDuringExecution: {
																										items: {
																											properties: {
																												podAffinityTerm: {
																													properties: {
																														labelSelector: {
																															properties: {
																																matchExpressions: {
																																	items: {
																																		properties: {
																																			key: {
																																				type: "string"
																																			}
																																			operator: {
																																				type: "string"
																																			}
																																			values: {
																																				items: {
																																					type: "string"
																																				}
																																				type:                     "array"
																																				"x-kubernetes-list-type": "atomic"
																																			}
																																		}
																																		required: ["key", "operator"]
																																		type: "object"
																																	}
																																	type:                     "array"
																																	"x-kubernetes-list-type": "atomic"
																																}
																																matchLabels: {
																																	additionalProperties: {
																																		type: "string"
																																	}
																																	type: "object"
																																}
																															}
																															type:                    "object"
																															"x-kubernetes-map-type": "atomic"
																														}
																														matchLabelKeys: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														mismatchLabelKeys: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														namespaceSelector: {
																															properties: {
																																matchExpressions: {
																																	items: {
																																		properties: {
																																			key: {
																																				type: "string"
																																			}
																																			operator: {
																																				type: "string"
																																			}
																																			values: {
																																				items: {
																																					type: "string"
																																				}
																																				type:                     "array"
																																				"x-kubernetes-list-type": "atomic"
																																			}
																																		}
																																		required: ["key", "operator"]
																																		type: "object"
																																	}
																																	type:                     "array"
																																	"x-kubernetes-list-type": "atomic"
																																}
																																matchLabels: {
																																	additionalProperties: {
																																		type: "string"
																																	}
																																	type: "object"
																																}
																															}
																															type:                    "object"
																															"x-kubernetes-map-type": "atomic"
																														}
																														namespaces: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														topologyKey: {
																															type: "string"
																														}
																													}
																													required: ["topologyKey"]
																													type: "object"
																												}
																												weight: {
																													format: "int32"
																													type:   "integer"
																												}
																											}
																											required: ["podAffinityTerm", "weight"]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									requiredDuringSchedulingIgnoredDuringExecution: {
																										items: {
																											properties: {
																												labelSelector: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchLabels: {
																															additionalProperties: {
																																type: "string"
																															}
																															type: "object"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												matchLabelKeys: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												mismatchLabelKeys: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												namespaceSelector: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchLabels: {
																															additionalProperties: {
																																type: "string"
																															}
																															type: "object"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												namespaces: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												topologyKey: {
																													type: "string"
																												}
																											}
																											required: ["topologyKey"]
																											type: "object"
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
																					imagePullSecrets: {
																						items: {
																							properties: {
																								name: {
																									default: ""
																									type:    "string"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						type: "array"
																						"x-kubernetes-list-map-keys": ["name"]
																						"x-kubernetes-list-type": "map"
																					}
																					nodeSelector: {
																						additionalProperties: {
																							type: "string"
																						}
																						type: "object"
																					}
																					priorityClassName: {
																						type: "string"
																					}
																					resources: {
																						properties: {
																							limits: {
																								additionalProperties: {
																									anyOf: [{
																										type: "integer"
																									}, {
																										type: "string"
																									}]
																									pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																									"x-kubernetes-int-or-string": true
																								}
																								type: "object"
																							}
																							requests: {
																								additionalProperties: {
																									anyOf: [{
																										type: "integer"
																									}, {
																										type: "string"
																									}]
																									pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																									"x-kubernetes-int-or-string": true
																								}
																								type: "object"
																							}
																						}
																						type: "object"
																					}
																					securityContext: {
																						properties: {
																							fsGroup: {
																								format: "int64"
																								type:   "integer"
																							}
																							fsGroupChangePolicy: {
																								type: "string"
																							}
																							runAsGroup: {
																								format: "int64"
																								type:   "integer"
																							}
																							runAsNonRoot: {
																								type: "boolean"
																							}
																							runAsUser: {
																								format: "int64"
																								type:   "integer"
																							}
																							seLinuxOptions: {
																								properties: {
																									level: {
																										type: "string"
																									}
																									role: {
																										type: "string"
																									}
																									type: {
																										type: "string"
																									}
																									user: {
																										type: "string"
																									}
																								}
																								type: "object"
																							}
																							seccompProfile: {
																								properties: {
																									localhostProfile: {
																										type: "string"
																									}
																									type: {
																										type: "string"
																									}
																								}
																								required: ["type"]
																								type: "object"
																							}
																							supplementalGroups: {
																								items: {
																									format: "int64"
																									type:   "integer"
																								}
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																							sysctls: {
																								items: {
																									properties: {
																										name: {
																											type: "string"
																										}
																										value: {
																											type: "string"
																										}
																									}
																									required: ["name", "value"]
																									type: "object"
																								}
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																						}
																						type: "object"
																					}
																					serviceAccountName: {
																						type: "string"
																					}
																					tolerations: {
																						items: {
																							properties: {
																								effect: {
																									type: "string"
																								}
																								key: {
																									type: "string"
																								}
																								operator: {
																									type: "string"
																								}
																								tolerationSeconds: {
																									format: "int64"
																									type:   "integer"
																								}
																								value: {
																									type: "string"
																								}
																							}
																							type: "object"
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
																	serviceType: {
																		type: "string"
																	}
																}
																type: "object"
															}
															ingress: {
																properties: {
																	class: {
																		type: "string"
																	}
																	ingressClassName: {
																		type: "string"
																	}
																	ingressTemplate: {
																		properties: {
																			metadata: {
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
																		}
																		type: "object"
																	}
																	name: {
																		type: "string"
																	}
																	podTemplate: {
																		properties: {
																			metadata: {
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
																			spec: {
																				properties: {
																					affinity: {
																						properties: {
																							nodeAffinity: {
																								properties: {
																									preferredDuringSchedulingIgnoredDuringExecution: {
																										items: {
																											properties: {
																												preference: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchFields: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												weight: {
																													format: "int32"
																													type:   "integer"
																												}
																											}
																											required: ["preference", "weight"]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									requiredDuringSchedulingIgnoredDuringExecution: {
																										properties: {
																											nodeSelectorTerms: {
																												items: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchFields: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												type:                     "array"
																												"x-kubernetes-list-type": "atomic"
																											}
																										}
																										required: ["nodeSelectorTerms"]
																										type:                    "object"
																										"x-kubernetes-map-type": "atomic"
																									}
																								}
																								type: "object"
																							}
																							podAffinity: {
																								properties: {
																									preferredDuringSchedulingIgnoredDuringExecution: {
																										items: {
																											properties: {
																												podAffinityTerm: {
																													properties: {
																														labelSelector: {
																															properties: {
																																matchExpressions: {
																																	items: {
																																		properties: {
																																			key: {
																																				type: "string"
																																			}
																																			operator: {
																																				type: "string"
																																			}
																																			values: {
																																				items: {
																																					type: "string"
																																				}
																																				type:                     "array"
																																				"x-kubernetes-list-type": "atomic"
																																			}
																																		}
																																		required: ["key", "operator"]
																																		type: "object"
																																	}
																																	type:                     "array"
																																	"x-kubernetes-list-type": "atomic"
																																}
																																matchLabels: {
																																	additionalProperties: {
																																		type: "string"
																																	}
																																	type: "object"
																																}
																															}
																															type:                    "object"
																															"x-kubernetes-map-type": "atomic"
																														}
																														matchLabelKeys: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														mismatchLabelKeys: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														namespaceSelector: {
																															properties: {
																																matchExpressions: {
																																	items: {
																																		properties: {
																																			key: {
																																				type: "string"
																																			}
																																			operator: {
																																				type: "string"
																																			}
																																			values: {
																																				items: {
																																					type: "string"
																																				}
																																				type:                     "array"
																																				"x-kubernetes-list-type": "atomic"
																																			}
																																		}
																																		required: ["key", "operator"]
																																		type: "object"
																																	}
																																	type:                     "array"
																																	"x-kubernetes-list-type": "atomic"
																																}
																																matchLabels: {
																																	additionalProperties: {
																																		type: "string"
																																	}
																																	type: "object"
																																}
																															}
																															type:                    "object"
																															"x-kubernetes-map-type": "atomic"
																														}
																														namespaces: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														topologyKey: {
																															type: "string"
																														}
																													}
																													required: ["topologyKey"]
																													type: "object"
																												}
																												weight: {
																													format: "int32"
																													type:   "integer"
																												}
																											}
																											required: ["podAffinityTerm", "weight"]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									requiredDuringSchedulingIgnoredDuringExecution: {
																										items: {
																											properties: {
																												labelSelector: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchLabels: {
																															additionalProperties: {
																																type: "string"
																															}
																															type: "object"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												matchLabelKeys: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												mismatchLabelKeys: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												namespaceSelector: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchLabels: {
																															additionalProperties: {
																																type: "string"
																															}
																															type: "object"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												namespaces: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												topologyKey: {
																													type: "string"
																												}
																											}
																											required: ["topologyKey"]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																								}
																								type: "object"
																							}
																							podAntiAffinity: {
																								properties: {
																									preferredDuringSchedulingIgnoredDuringExecution: {
																										items: {
																											properties: {
																												podAffinityTerm: {
																													properties: {
																														labelSelector: {
																															properties: {
																																matchExpressions: {
																																	items: {
																																		properties: {
																																			key: {
																																				type: "string"
																																			}
																																			operator: {
																																				type: "string"
																																			}
																																			values: {
																																				items: {
																																					type: "string"
																																				}
																																				type:                     "array"
																																				"x-kubernetes-list-type": "atomic"
																																			}
																																		}
																																		required: ["key", "operator"]
																																		type: "object"
																																	}
																																	type:                     "array"
																																	"x-kubernetes-list-type": "atomic"
																																}
																																matchLabels: {
																																	additionalProperties: {
																																		type: "string"
																																	}
																																	type: "object"
																																}
																															}
																															type:                    "object"
																															"x-kubernetes-map-type": "atomic"
																														}
																														matchLabelKeys: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														mismatchLabelKeys: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														namespaceSelector: {
																															properties: {
																																matchExpressions: {
																																	items: {
																																		properties: {
																																			key: {
																																				type: "string"
																																			}
																																			operator: {
																																				type: "string"
																																			}
																																			values: {
																																				items: {
																																					type: "string"
																																				}
																																				type:                     "array"
																																				"x-kubernetes-list-type": "atomic"
																																			}
																																		}
																																		required: ["key", "operator"]
																																		type: "object"
																																	}
																																	type:                     "array"
																																	"x-kubernetes-list-type": "atomic"
																																}
																																matchLabels: {
																																	additionalProperties: {
																																		type: "string"
																																	}
																																	type: "object"
																																}
																															}
																															type:                    "object"
																															"x-kubernetes-map-type": "atomic"
																														}
																														namespaces: {
																															items: {
																																type: "string"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														topologyKey: {
																															type: "string"
																														}
																													}
																													required: ["topologyKey"]
																													type: "object"
																												}
																												weight: {
																													format: "int32"
																													type:   "integer"
																												}
																											}
																											required: ["podAffinityTerm", "weight"]
																											type: "object"
																										}
																										type:                     "array"
																										"x-kubernetes-list-type": "atomic"
																									}
																									requiredDuringSchedulingIgnoredDuringExecution: {
																										items: {
																											properties: {
																												labelSelector: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchLabels: {
																															additionalProperties: {
																																type: "string"
																															}
																															type: "object"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												matchLabelKeys: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												mismatchLabelKeys: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												namespaceSelector: {
																													properties: {
																														matchExpressions: {
																															items: {
																																properties: {
																																	key: {
																																		type: "string"
																																	}
																																	operator: {
																																		type: "string"
																																	}
																																	values: {
																																		items: {
																																			type: "string"
																																		}
																																		type:                     "array"
																																		"x-kubernetes-list-type": "atomic"
																																	}
																																}
																																required: ["key", "operator"]
																																type: "object"
																															}
																															type:                     "array"
																															"x-kubernetes-list-type": "atomic"
																														}
																														matchLabels: {
																															additionalProperties: {
																																type: "string"
																															}
																															type: "object"
																														}
																													}
																													type:                    "object"
																													"x-kubernetes-map-type": "atomic"
																												}
																												namespaces: {
																													items: {
																														type: "string"
																													}
																													type:                     "array"
																													"x-kubernetes-list-type": "atomic"
																												}
																												topologyKey: {
																													type: "string"
																												}
																											}
																											required: ["topologyKey"]
																											type: "object"
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
																					imagePullSecrets: {
																						items: {
																							properties: {
																								name: {
																									default: ""
																									type:    "string"
																								}
																							}
																							type:                    "object"
																							"x-kubernetes-map-type": "atomic"
																						}
																						type: "array"
																						"x-kubernetes-list-map-keys": ["name"]
																						"x-kubernetes-list-type": "map"
																					}
																					nodeSelector: {
																						additionalProperties: {
																							type: "string"
																						}
																						type: "object"
																					}
																					priorityClassName: {
																						type: "string"
																					}
																					resources: {
																						properties: {
																							limits: {
																								additionalProperties: {
																									anyOf: [{
																										type: "integer"
																									}, {
																										type: "string"
																									}]
																									pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																									"x-kubernetes-int-or-string": true
																								}
																								type: "object"
																							}
																							requests: {
																								additionalProperties: {
																									anyOf: [{
																										type: "integer"
																									}, {
																										type: "string"
																									}]
																									pattern:                      "^(\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\\+|-)?(([0-9]+(\\.[0-9]*)?)|(\\.[0-9]+))))?$"
																									"x-kubernetes-int-or-string": true
																								}
																								type: "object"
																							}
																						}
																						type: "object"
																					}
																					securityContext: {
																						properties: {
																							fsGroup: {
																								format: "int64"
																								type:   "integer"
																							}
																							fsGroupChangePolicy: {
																								type: "string"
																							}
																							runAsGroup: {
																								format: "int64"
																								type:   "integer"
																							}
																							runAsNonRoot: {
																								type: "boolean"
																							}
																							runAsUser: {
																								format: "int64"
																								type:   "integer"
																							}
																							seLinuxOptions: {
																								properties: {
																									level: {
																										type: "string"
																									}
																									role: {
																										type: "string"
																									}
																									type: {
																										type: "string"
																									}
																									user: {
																										type: "string"
																									}
																								}
																								type: "object"
																							}
																							seccompProfile: {
																								properties: {
																									localhostProfile: {
																										type: "string"
																									}
																									type: {
																										type: "string"
																									}
																								}
																								required: ["type"]
																								type: "object"
																							}
																							supplementalGroups: {
																								items: {
																									format: "int64"
																									type:   "integer"
																								}
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																							sysctls: {
																								items: {
																									properties: {
																										name: {
																											type: "string"
																										}
																										value: {
																											type: "string"
																										}
																									}
																									required: ["name", "value"]
																									type: "object"
																								}
																								type:                     "array"
																								"x-kubernetes-list-type": "atomic"
																							}
																						}
																						type: "object"
																					}
																					serviceAccountName: {
																						type: "string"
																					}
																					tolerations: {
																						items: {
																							properties: {
																								effect: {
																									type: "string"
																								}
																								key: {
																									type: "string"
																								}
																								operator: {
																									type: "string"
																								}
																								tolerationSeconds: {
																									format: "int64"
																									type:   "integer"
																								}
																								value: {
																									type: "string"
																								}
																							}
																							type: "object"
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
																	serviceType: {
																		type: "string"
																	}
																}
																type: "object"
															}
														}
														type: "object"
													}
													selector: {
														properties: {
															dnsNames: {
																items: {
																	type: "string"
																}
																type:                     "array"
																"x-kubernetes-list-type": "atomic"
															}
															dnsZones: {
																items: {
																	type: "string"
																}
																type:                     "array"
																"x-kubernetes-list-type": "atomic"
															}
															matchLabels: {
																additionalProperties: {
																	type: "string"
																}
																type: "object"
															}
														}
														type: "object"
													}
													waitInsteadOfSelfCheck: {
														type: "string"
													}
												}
												type: "object"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
									}
									required: ["privateKeySecretRef", "server"]
									type: "object"
								}
								ca: {
									properties: {
										crlDistributionPoints: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
										issuingCertificateURLs: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
										ocspServers: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
										secretName: {
											type: "string"
										}
									}
									required: ["secretName"]
									type: "object"
								}
								selfSigned: {
									properties: {
										crlDistributionPoints: {
											items: {
												type: "string"
											}
											type:                     "array"
											"x-kubernetes-list-type": "atomic"
										}
									}
									type: "object"
								}
								vault: {
									properties: {
										auth: {
											properties: {
												appRole: {
													properties: {
														path: {
															type: "string"
														}
														roleId: {
															type: "string"
														}
														secretRef: {
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
													required: ["path", "roleId", "secretRef"]
													type: "object"
												}
												aws: {
													properties: {
														iamRoleArn: {
															type: "string"
														}
														mountPath: {
															type: "string"
														}
														region: {
															type: "string"
														}
														role: {
															minLength: 1
															type:      "string"
														}
														serviceAccountRef: {
															properties: {
																audiences: {
																	items: {
																		type: "string"
																	}
																	type:                     "array"
																	"x-kubernetes-list-type": "atomic"
																}
																name: {
																	type: "string"
																}
															}
															required: ["name"]
															type: "object"
														}
														vaultHeaderValue: {
															type: "string"
														}
													}
													required: ["role"]
													type: "object"
												}
												clientCertificate: {
													properties: {
														mountPath: {
															type: "string"
														}
														name: {
															type: "string"
														}
														secretName: {
															type: "string"
														}
													}
													type: "object"
												}
												kubernetes: {
													properties: {
														mountPath: {
															type: "string"
														}
														role: {
															type: "string"
														}
														secretRef: {
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
														serviceAccountRef: {
															properties: {
																audiences: {
																	items: {
																		type: "string"
																	}
																	type:                     "array"
																	"x-kubernetes-list-type": "atomic"
																}
																name: {
																	type: "string"
																}
															}
															required: ["name"]
															type: "object"
														}
													}
													required: ["role"]
													type: "object"
												}
												tokenSecretRef: {
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
											type: "object"
										}
										caBundle: {
											format: "byte"
											type:   "string"
										}
										caBundleSecretRef: {
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
										clientCertSecretRef: {
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
										clientKeySecretRef: {
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
										namespace: {
											type: "string"
										}
										path: {
											type: "string"
										}
										server: {
											type: "string"
										}
										serverName: {
											type: "string"
										}
									}
									required: ["auth", "path", "server"]
									type: "object"
								}
								venafi: {
									properties: {
										cloud: {
											properties: {
												apiTokenSecretRef: {
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
												url: {
													type: "string"
												}
											}
											required: ["apiTokenSecretRef"]
											type: "object"
										}
										ngts: {
											properties: {
												credentialsRef: {
													properties: {
														name: {
															type: "string"
														}
													}
													required: ["name"]
													type: "object"
												}
												tokenEndpoint: {
													type: "string"
												}
												tsgID: {
													type: "string"
												}
												url: {
													type: "string"
												}
											}
											required: ["credentialsRef", "tsgID"]
											type: "object"
										}
										tpp: {
											properties: {
												caBundle: {
													format: "byte"
													type:   "string"
												}
												caBundleSecretRef: {
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
												credentialsRef: {
													properties: {
														name: {
															type: "string"
														}
													}
													required: ["name"]
													type: "object"
												}
												url: {
													type: "string"
												}
											}
											required: ["credentialsRef", "url"]
											type: "object"
										}
										zone: {
											type: "string"
										}
									}
									required: ["zone"]
									type: "object"
									"x-kubernetes-validations": [{
										message: "exactly one of tpp, cloud, or ngts must be configured"
										rule:    "(has(self.tpp) ? 1 : 0) + (has(self.cloud) ? 1 : 0) + (has(self.ngts) ? 1 : 0) == 1"
									}]
								}
							}
							type: "object"
						}
						status: {
							properties: {
								acme: {
									properties: {
										lastPrivateKeyHash: {
											type: "string"
										}
										lastRegisteredEmail: {
											type: "string"
										}
										uri: {
											type: "string"
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
							}
							type: "object"
						}
					}
					required: ["spec"]
					type: "object"
				}
			}
			subresources: {
				status: {}
			}
		}]
	}
}
