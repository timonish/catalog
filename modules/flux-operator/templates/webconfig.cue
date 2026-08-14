package templates

// WebDuration is a string in the duration format accepted by the Web
// Config API, e.g. `30s` or `1h30m`.
#WebDuration: string & =~"^([0-9]+(\\.[0-9]+)?(ms|s|m|h))+$"

// UserAction is a GitOps action verb of the Flux Status Page.
#UserAction: "delete" | "download" | "reconcile" | "restart" | "resume" | "suspend"

// WebConfig defines the schema for the Flux Status Page configuration —
// the `spec` of the `web.fluxcd.controlplane.io/v1` Config document —
// rendered into a hash-named immutable Secret mounted into the pods.
// The schema is typed but open at every level: fields introduced by
// newer operator releases pass through without a module update.
// Docs: https://fluxoperator.dev/docs/web-ui/web-config-api/
#WebConfig: {
	// The base URL for constructing the Flux Status Page URLs.
	// Required for the OAuth2 authentication type.
	baseURL?: string & =~".+"

	// Use insecure settings across the web application.
	insecure?: bool

	// Search settings.
	search?: {
		// Serve resource listings from the periodically refreshed
		// in-memory search index instead of querying the Kubernetes
		// API in realtime, reducing API server load.
		cached?: bool
		...
	}

	// Pod metrics collection settings.
	metrics?: {
		// Turn off pod metrics collection; no Metrics API queries are
		// made and the resource usage charts are hidden.
		disabled?: bool

		// The interval at which pod metrics are collected from the
		// Kubernetes Metrics API, clamped by the operator to the
		// [15s, 10m] range. Defaults to 60s.
		scrapeInterval?: #WebDuration
		...
	}

	// GitOps user actions settings. All actions are enabled by
	// default; they require the OAuth2 authentication type.
	userActions?: {
		// The actions to audit: a list of action verbs, or `["*"]`
		// for all of them (the wildcard cannot be combined with other
		// actions). Empty audits none.
		audit?: ["*"] | [...#UserAction]

		// How actions are authorized and performed. `Impersonated`
		// (the default) performs the action by impersonating the user,
		// requiring both the custom per-action verb (e.g. `suspend`)
		// and the native Kubernetes verbs (e.g. `patch`) from the
		// user. `FineGrained` performs the action with the web
		// server's own privileges, requiring only the per-action verb
		// from the user; it also extends the ClusterRole rendered in
		// `web.serverOnly` mode with the native permissions the
		// actions need (the operator mode already runs as
		// cluster-admin).
		access?: "Impersonated" | "FineGrained"
		...
	}

	// Authentication settings.
	authentication?: {
		// The authentication type.
		type: "Anonymous" | "OAuth2"

		// The settings of the selected type are required, and the two
		// configurations are mutually exclusive.
		if type == "Anonymous" {
			anonymous: _
		}
		_authGuard: "valid"
		_authGuard: [
			if anonymous != _|_ && oauth2 != _|_ {
				"authentication.anonymous and authentication.oauth2 are mutually exclusive"
			},
			if anonymous != _|_
			if anonymous.username == _|_ && anonymous.groups == _|_ {
				"authentication.anonymous requires username or groups"
			},
			"valid",
		][0]

		// Anonymous authentication settings; at least one of the
		// fields must be set.
		anonymous?: {
			// The username used for Kubernetes RBAC impersonation.
			username?: string & =~".+"

			// The groups used for Kubernetes RBAC impersonation.
			groups?: [...string & =~".+"]
			...
		}

		// OAuth2 authentication settings, required for the OAuth2
		// type.
		if type == "OAuth2" {
			oauth2: _
		}
		oauth2?: {
			// The OAuth2 provider name.
			provider: "OIDC"

			// The OAuth2 client identifier.
			clientID: string & =~".+"

			// The OAuth2 client secret. To keep it out of the instance
			// values, mount the whole configuration from an existing
			// Secret through `web.configSecretName`.
			clientSecret: string & =~".+"

			// The OAuth2 scopes to request; each provider has its own
			// defaults.
			scopes?: [...string & =~".+"]

			// Additional query parameters for the authorization URL,
			// e.g. `"access_type": "offline"` and `"prompt": "consent"`.
			authURLParams?: {[string]: string}

			// Redirect unauthenticated users straight to the OAuth2
			// provider instead of showing the login page.
			autoLogin?: bool

			// The issuer URL used for OIDC provider discovery,
			// required by the OIDC provider.
			issuerURL: string & =~".+"

			// CEL expressions extracting information from the ID token
			// claims into named variables reusable in the other
			// expressions, e.g. `variables.username`.
			variables?: [...{
				name:       string & =~".+"
				expression: string & =~".+"
				...
			}]

			// CEL expressions validating the ID token claims and
			// extracted variables; each must return bool, and its
			// message is returned as the error on failure.
			validations?: [...{
				expression: string & =~".+"
				message:    string & =~".+"
				...
			}]

			// CEL expressions extracting user profile information from
			// the ID token claims and extracted variables.
			profile?: {
				// The user's full name; must return a string.
				name?: string & =~".+"
				...
			}

			// CEL expressions extracting the Kubernetes RBAC
			// impersonation identity from the ID token claims and
			// extracted variables; at least one of the fields must be
			// set.
			impersonation?: {
				// The username; must return a string.
				username?: string & =~".+"

				// The groups; must return a list of strings.
				groups?: string & =~".+"
				...
			}
			...
		}

		// The duration of the user session; defaults to one week.
		sessionDuration?: #WebDuration

		// The size of the user cache in number of users; defaults
		// to 100.
		userCacheSize?: int & >0
		...
	}

	// The OAuth2 authentication type constructs redirect URLs from
	// the base URL.
	if authentication != _|_ if authentication.type == "OAuth2" {
		baseURL: string & =~".+"
	}

	...
}
