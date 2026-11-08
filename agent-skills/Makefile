SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show available targets
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

.PHONY: validate
validate: ## Validate every SKILL.md manifest
	@scripts/validate-skills.sh

.PHONY: list
list: ## List skill names and descriptions
	@scripts/list-skills.sh

.PHONY: clean
clean: ## Remove editor and OS cruft
	@find . -name '.DS_Store' -delete
