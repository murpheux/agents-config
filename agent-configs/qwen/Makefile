# Qwen Code configuration - see README.md. Tests are offline and never touch ~/.qwen.
SHELL    := /bin/bash
BUILD_PY ?= $(shell d="$$(uv tool dir 2>/dev/null)/aider-chat/bin/python"; [ -x "$$d" ] && echo "$$d" || echo python3)
SCRIPTS  := install.sh home/.qwen/qwen-env.sh lib/install-lib.sh
PYFILES  := home/.qwen/hooks/qwen_guard.py lib/merge_json.py tests/test_config.py

.PHONY: help build lint test install-dry install deploy

help: ## list targets
	@grep -hE '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

build: ## regenerate AGENTS.md, agents and the shared guard from _shared (needs _shared/tools/qwen.yaml + PyYAML)
	cd .. && $(BUILD_PY) _shared/build.py qwen

lint: ## syntax-check shell, Python and config files
	@for f in $(SCRIPTS); do [ -f "$$f" ] && { bash -n "$$f" || exit 1; }; done
	@if command -v shellcheck >/dev/null; then shellcheck -S warning $(SCRIPTS); fi
	@python3 -c "import ast,sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]" $(PYFILES)
	@echo "lint OK"

test: ## offline structure/config/secret checks (guard self-test runs once `make build` has copied guard.py)
	@if [ -f home/.qwen/hooks/guard.py ]; then python3 home/.qwen/hooks/guard.py --self-test; fi
	@python3 -I tests/test_config.py

install-dry: ## preview the install (nothing is changed)
	DRY_RUN=1 ./install.sh

install: lint test ## install into ~/.qwen; backs up what it replaces
	./install.sh

deploy: install ## alias for install (local tool config - nothing remote)
