

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
