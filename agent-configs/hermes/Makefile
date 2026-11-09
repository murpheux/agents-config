# Hermes Agent (NousResearch/hermes-agent) configuration — see README.md.
# Hermes-specific checks run under Hermes' own interpreter so its real schema, provider resolver,
# shell-hook parser, prompt scanner and command registry are used.
SHELL      := /bin/bash
HERMES_PY  ?= $(HOME)/.hermes/hermes-agent/venv/bin/python3
BUILD_PY   ?= $(shell d="$$(uv tool dir 2>/dev/null)/aider-chat/bin/python"; [ -x "$$d" ] && echo "$$d" || echo python3)
SCRIPTS    := install.sh home/.hermes/hermes-env.sh lib/install-lib.sh
PYFILES    := home/.hermes/agent-hooks/guardrails-hook.py lib/configure-hermes.py lib/merge_json.py tests/test_config.py

.PHONY: help build lint test install-dry install deploy

help: ## list targets
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

build: ## regenerate SOUL.md, role/workflow skills and the shared guard from _shared (needs PyYAML)
	cd .. && $(BUILD_PY) _shared/build.py hermes

lint: ## syntax-check shell, Python, YAML and the CA helper
	@for f in $(SCRIPTS); do bash -n "$$f" || exit 1; done
	@if command -v shellcheck >/dev/null; then shellcheck -S warning $(SCRIPTS); fi
	@python3 -c "import ast,sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]" $(PYFILES)
	@$(HERMES_PY) -c "import yaml; yaml.safe_load(open('home/.hermes/config.fragment.yaml'))"
	@node --check lib/build-ca-bundle.mjs
	@echo "lint OK"

test: ## offline checks with Hermes' interpreter: schema, resolver, hook protocol, scanner, no secrets
	@python3 home/.hermes/guard/guard.py --self-test
	@$(HERMES_PY) tests/test_config.py

install-dry: ## preview the install (nothing is changed)
	DRY_RUN=1 ./install.sh

install: lint test ## install into HERMES_HOME (default ~/.hermes); backs up what it changes
	./install.sh

deploy: install ## alias for install (local tool config — nothing remote)
