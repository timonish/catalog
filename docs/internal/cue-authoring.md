# CUE authoring guide

Recurring template-authoring rules learned in this catalog; the error
usually appears far from its cause:

- **`#MetaComponent` names are concrete, not defaults.** Unifying the
  metadata with a different concrete name is "conflicting values", and
  unifying two name fields that each carry a *different default* is an
  "incomplete value" that only plain `build` reports — vet with debug
  values can pass. Objects with user-overridable names
  (ServiceAccounts, Services, Secrets) need hand-built metadata, or
  defaults that resolve to the same string.
- **Embedded-struct fields are invisible to sibling comprehensions.**
  Inside `#X: {#Workload, _guard: [...]}` the guard cannot reference
  the embedded `extraArgs` ("reference not found") — alias the struct
  (`#X: A={...}`) and use `A.extraArgs`.
- **k8s gen schemas type `[]byte` fields as CUE `bytes`.** For
  `Secret.data` use `stringData` instead; for fields with no string
  alternative (webhook `caBundle`) wrap the base64 *text* as a bytes
  literal — `'\(base64.Encode(null, s))'` — since raw bytes render
  verbatim and the API server rejects them.
- **Top-level embedded disjunctions in `#Config` break cross-field
  references** — model variants as optional fields plus a `_guard`
  list that yields an error string for invalid combinations.
- **`{_config: _config}` is a self-cycle** — use `let cfg = _config`
  when passing config into composed objects.
- **CUE package names cannot contain dashes**: a component named
  `admission-controller` lives in `templates/admission` with
  `package admission`; the dashed name stays in labels and object
  names.
