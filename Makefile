# Timoni Module Catalog

.ONESHELL:
SHELL := bash
.SHELLFLAGS += -eo pipefail

OWNER    := timonish
REPO     := catalog
REGISTRY := oci://ghcr.io/$(OWNER)/modules
MODULES  := $(notdir $(wildcard modules/*))
MODULE   ?=

.PHONY: tools
tools: ## Install the required CLIs with Homebrew
	brew bundle

.PHONY: fmt
fmt: ## Format all CUE definitions
	@timoni fmt .

.PHONY: fmt-check
fmt-check: ## Verify that all CUE definitions are formatted
	@timoni fmt --diff .

.PHONY: vet
vet: ## Vet all modules
	@for dir in ./modules/*/ ; do
		[ -d "$$dir" ] || continue
		echo "vetting $$dir"
		timoni mod vet $$dir --debug
	done

PROMETHEUS_OPERATOR_VERSION := v0.93.0

.PHONY: update-shared-schemas
update-shared-schemas: ## Update the shared Timoni, Kubernetes API and Prometheus Operator schemas in ./schemas
	@timoni artifact pull oci://ghcr.io/stefanprodan/timoni/schemas:latest \
		--output schemas/cue.mod/pkg
	@timoni mod vendor k8s ./schemas
	@timoni mod vendor crd ./schemas \
		-f https://github.com/prometheus-operator/prometheus-operator/releases/download/$(PROMETHEUS_OPERATOR_VERSION)/stripped-down-crds.yaml

.PHONY: build
build: ## Render a module (make build MODULE=<name>)
	@test -n "$(MODULE)" || { echo "usage: make build MODULE=<name>"; exit 1; }
	@timoni -n $(MODULE) build $(MODULE) ./modules/$(MODULE)

.PHONY: list-mod
list-mod: ## List the published versions of a module (make list-mod MODULE=<name>)
	@test -n "$(MODULE)" || { echo "usage: make list-mod MODULE=<name>"; exit 1; }
	@timoni mod list $(REGISTRY)/$(MODULE)

.PHONY: status
status: ## Show local VERSION vs GHCR for every module
	@for dir in ./modules/*/ ; do
		[ -d "$$dir" ] || continue
		m="$$(basename $$dir)"
		v="$$(cat $$dir/VERSION)"
		if tags="$$(timoni mod list $(REGISTRY)/$$m --with-digest=false 2>/dev/null)" \
			&& awk 'NR>1 {print $$1}' <<<"$$tags" | grep -Fxq "$$v" ; then
			echo "$$m $$v published"
		else
			echo "$$m $$v not published"
		fi
	done

.PHONY: push-mod
push-mod: ## Push a module to GHCR (make push-mod MODULE=<name>)
	@test -n "$(MODULE)" || { echo "usage: make push-mod MODULE=<name>"; exit 1; }
	@VERSION="$$(cat modules/$(MODULE)/VERSION)"
	DESC="$$(awk 'NR>1 && !/^#/ && /[^[:space:]]/ {print; exit}' modules/$(MODULE)/README.md)"
	timoni mod push ./modules/$(MODULE) $(REGISTRY)/$(MODULE) \
		-v="$$VERSION" --latest \
		--resolve-symlinks \
		--sign cosign \
		-a "org.opencontainers.image.source=https://github.com/$(OWNER)/$(REPO)" \
		-a "org.opencontainers.image.licenses=Apache-2.0" \
		-a "org.opencontainers.image.revision=$${GITHUB_SHA:-$$(git rev-parse HEAD)}" \
		-a "org.opencontainers.image.description=$$DESC" \
		-a "org.opencontainers.image.documentation=https://github.com/$(OWNER)/$(REPO)/blob/main/modules/$(MODULE)/README.md"

.PHONY: push-all
push-all: ## Push all modules to GHCR
	@for m in $(MODULES) ; do
		$(MAKE) push-mod MODULE=$$m
	done

.PHONY: help
help:  ## Display this help menu
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
