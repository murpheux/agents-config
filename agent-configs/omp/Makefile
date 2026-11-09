# oh-my-pi (omp) configuration — see README.md. Tests drive the installed omp binary offline
# against a throwaway HOME, so nothing under ~/.omp is touched.
SHELL    := /bin/bash
BUILD_PY ?= $(shell d="$$(uv tool dir 2>/dev/null)/aider-chat/bin/python"; [ -x "$$d" ] && echo "$$d" || echo python3)
SCRIPTS  := install.sh home/.omp/agent/omp-env.sh lib/install-lib.sh
PYFILES  := home/.omp/agent/guard/omp_guard.py lib/merge_json.py tests/test_config.py

.PHONY: help build lint test install-dry install deploy

help: ## list targets
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

build: ## regenerate AGENTS.md, the 7 subagents and the shared guard from _shared (needs PyYAML)
	cd .. && $(BUILD_PY) _shared/build.py omp

lint: ## syntax-check shell, Python, JSON and the CA helper
	@for f in $(SCRIPTS); do bash -n "$$f" || exit 1; done
	@zsh -n home/.omp/agent/omp-env.sh
	@if command -v shellcheck >/dev/null; then shellcheck -S warning $(SCRIPTS); fi
	@python3 -c "import ast,sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]" $(PYFILES)
	@python3 -c "import json; json.load(open('home/.omp/agent/config.settings.json'))"
	@node --check lib/build-ca-bundle.mjs
	@echo "lint OK"

test: ## offline checks via omp itself: models.yml, key resolution, settings, agents, guard extension
	@python3 home/.omp/agent/guard/guard.py --self-test
	@python3 -I tests/test_config.py

install-dry: ## preview the install (nothing is changed)
	DRY_RUN=1 ./install.sh

install: lint test ## install into PI_CODING_AGENT_DIR (default ~/.omp/agent); backs up what it replaces
	./install.sh

deploy: install ## alias for install (local tool config — nothing remote)
