# Tau (huggingface/tau) configuration — see README.md.
# Tau-specific checks run under Tau's own interpreter so its real schema and extension classes are used.
SHELL      := /bin/bash
TAU_PY     ?= $(shell d="$$(uv tool dir 2>/dev/null)/tau-ai/bin/python"; [ -x "$$d" ] && echo "$$d" || echo python3)
BUILD_PY   ?= $(shell d="$$(uv tool dir 2>/dev/null)/aider-chat/bin/python"; [ -x "$$d" ] && echo "$$d" || echo python3)
SCRIPTS    := install.sh home/.tau/tau-env.sh lib/install-lib.sh
PYFILES    := home/.tau/extensions/guardrails.py lib/scrub-credentials.py lib/merge_json.py tests/test_config.py

.PHONY: help build lint test install-dry install deploy

help: ## list targets
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

build: ## regenerate AGENTS.md, role skills and the shared guard from _shared (needs PyYAML)
	cd .. && $(BUILD_PY) _shared/build.py tau

lint: ## syntax-check shell, Python, TOML and JSON
	@for f in $(SCRIPTS); do bash -n "$$f" || exit 1; done
	@if command -v shellcheck >/dev/null; then shellcheck -S warning $(SCRIPTS); fi
	@python3 -m py_compile $(PYFILES)
	@python3 -c "import tomllib,json; tomllib.load(open('home/.tau/catalog.toml','rb')); json.load(open('home/.tau/providers.fragment.json'))"
	@node --check lib/build-ca-bundle.mjs
	@echo "lint OK"

test: ## offline checks with Tau's interpreter: catalog schema, guard extension, no secrets
	@python3 home/.tau/guard/guard.py --self-test
	@$(TAU_PY) -I tests/test_config.py

install-dry: ## preview the install (nothing is changed)
	DRY_RUN=1 ./install.sh

install: lint test ## install into TAU_HOME (default ~/.tau); backs up what it replaces
	./install.sh

deploy: install ## alias for install (local tool config — nothing remote)
