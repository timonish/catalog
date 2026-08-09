# Timoni Module Catalog

MODULE ?=
FORCE  ?=

.PHONY: tools
tools: ## Install the required CLIs with Homebrew
	brew bundle

.PHONY: fmt
fmt: ## Format all CUE definitions
	@timoni fmt .

.PHONY: fmt-check
fmt-check: ## Verify that all CUE definitions are formatted
	@timoni fmt --diff .

.PHONY: deps
deps: ## Install the upengine dependencies
	@cd upengine && bun install

.PHONY: lint
lint: ## Typecheck the upengine sources
	@cd upengine && bunx tsc --noEmit -p tsconfig.json

.PHONY: test
test: ## Run the upengine tests
	@cd upengine && bun test

.PHONY: lint-modules
lint-modules: ## Validate the modules metadata against sources.ts
	@bun upengine/src/main.ts lint

.PHONY: vet
vet: ## Vet all modules with debug values
	@bun upengine/src/main.ts vet

.PHONY: build
build: ## Render a module (make build MODULE=<name>)
	@timoni -n $(MODULE) build $(MODULE) ./modules/$(MODULE)

.PHONY: list-mod
list-mod: ## List the published versions of a module (make list-mod MODULE=<name>)
	@timoni mod list oci://ghcr.io/timonish/modules/$(MODULE)

.PHONY: status
status: ## Show local VERSION vs GHCR for every module
	@bun upengine/src/main.ts status

.PHONY: push-mod
push-mod: ## Publish a module to GHCR (make push-mod MODULE=<name>)
	@bun upengine/src/main.ts publish --source $(MODULE)

.PHONY: push-all
push-all: ## Publish all missing module versions to GHCR
	@bun upengine/src/main.ts publish

.PHONY: sync
sync: ## Sync modules with their upstream releases (make sync [MODULE=<name>] [FORCE=1])
	@bun upengine/src/main.ts sync \
		$(if $(MODULE),--source $(MODULE)) \
		$(if $(FORCE),--force)

.PHONY: cluster-up
cluster-up: ## Create the local kind cluster used for e2e testing
	@kind create cluster --name timoni-test --config test/cluster/kind.yaml

.PHONY: cluster-down
cluster-down: ## Delete the local kind cluster
	@kind delete cluster --name timoni-test

.PHONY: e2e
e2e: ## Run a module e2e test on the current cluster (make e2e MODULE=<name>)
	@bun upengine/src/main.ts e2e --source $(MODULE)

.PHONY: update-shared-schemas
update-shared-schemas: ## Update the shared Timoni, Kubernetes API and CRD schemas in ./schemas
	@bun upengine/src/main.ts vendor-schemas

.PHONY: help
help:  ## Display this help menu
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-24s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
