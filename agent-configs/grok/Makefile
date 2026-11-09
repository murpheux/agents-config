# grok-cli (@vibe-kit/grok-cli) configuration — see README.md.
SHELL      := /bin/bash
BUILD_PY   ?= $(shell d="$$(uv tool dir 2>/dev/null)/aider-chat/bin/python"; [ -x "$$d" ] && echo "$$d" || echo python3)
SCRIPTS    := install.sh home/.grok/grok-env.sh lib/install-lib.sh
PYFILES    := lib/configure-settings.py lib/merge_json.py tests/test_config.py

.PHONY: help build lint test install-dry install deploy

help: ## list targets
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

build: ## regenerate GROK.md and the shared guard copy from _shared (needs PyYAML)
	cd .. && $(BUILD_PY) _shared/build.py grok

lint: ## syntax-check shell, Python, JS and JSON
	@for f in $(SCRIPTS); do bash -n "$$f" || exit 1; done
	@if command -v shellcheck >/dev/null; then shellcheck -S warning $(SCRIPTS); fi
	@python3 -c "import ast,sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]" $(PYFILES)
	@python3 -c "import json; json.load(open('home/.grok/user-settings.fragment.json'))"
	@node --check home/.grok/grok-preload.cjs && node --check lib/build-ca-bundle.mjs && node --check tests/test-preload.mjs
	@echo "lint OK"

test: ## offline checks: guard self-test, settings/secrets, preload against grok-cli's real tools
	@python3 home/.grok/guard/guard.py --self-test
	@python3 -B tests/test_config.py
	@env -u GROK_API_KEY node tests/test-preload.mjs

install-dry: ## preview the install (nothing is changed)
	DRY_RUN=1 ./install.sh

install: lint test ## install into ~/.grok (backs up what it replaces)
	./install.sh

deploy: install ## alias for install (local tool config — nothing remote)
