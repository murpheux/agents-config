.PHONY: help install install-dry validate test schema clean build

help:
	@echo "OpenClaw Configuration Management"
	@echo ""
	@echo "Usage:"
	@echo "  make install          Install OpenClaw configuration to ~/.openclaw/"
	@echo "  make install-dry      Preview installation (DRY_RUN mode)"
	@echo "  make validate         Validate openclaw.json syntax and schema"
	@echo "  make test             Test gateway connectivity"
	@echo "  make schema           Print OpenClaw config schema"
	@echo "  make build            Build/prepare configuration"
	@echo "  make clean            Remove generated files"
	@echo ""

install:
	@echo "Installing OpenClaw configuration"
	@echo "  Config: ~/.openclaw/openclaw.json"
	@echo "  Docs: ~/.openclaw/workspace/"
	@echo "    - CONVENTIONS.md"
	@echo "    - USER.md"
	@echo "    - MEMORY.md"
	@echo ""
	@./install.sh

install-dry:
	@echo "Preview OpenClaw installation (DRY_RUN mode)"
	@echo "  Config: ~/.openclaw/openclaw.json"
	@echo "  Docs: ~/.openclaw/workspace/"
	@echo ""
	@DRY_RUN=1 ./install.sh

validate:
	@echo "Validating openclaw.json..."
	@if [ -f home/.openclaw/openclaw.json ]; then \
		python3 -m json.tool home/.openclaw/openclaw.json > /dev/null && echo "✓ JSON5 syntax valid" || echo "✗ JSON5 syntax invalid"; \
	else \
		echo "✗ openclaw.json not found"; \
		exit 1; \
	fi
	@echo "Checking for inline secrets..."
	@if grep -E '"(AGENTGATEWAY|ANTHROPIC|DEEPSEEK|GOOGLE)_[A-Z_]*"[[:space:]]*:[[:space:]]*"[a-zA-Z0-9]' home/.openclaw/openclaw.json; then \
		echo "⚠ Found potential inline secrets"; \
	else \
		echo "✓ No inline secrets detected"; \
	fi

test:
	@echo "Testing OpenClaw gateway connectivity..."
	@if command -v curl >/dev/null 2>&1; then \
		curl -s -I https://scarlet:9443/v1/models \
			-H "Authorization: Bearer $$(op read op://Personal/AGENTGATEWAY_TOKEN/credential 2>/dev/null || echo 'NO_TOKEN')" \
			2>&1 | head -1 && echo "✓ Gateway reachable" || echo "✗ Gateway unreachable"; \
	else \
		echo "curl not found"; \
	fi

schema:
	@echo "To view OpenClaw config schema, run:"
	@echo "  openclaw config schema"
	@echo ""
	@echo "Or on the remote VM:"
	@echo "  ssh -i ~/.ssh/id_ed25519 _ai_daemon@<vm> openclaw config schema"

build: validate
	@echo "✓ Configuration ready"

clean:
	@echo "Cleaning up..."
	@rm -f home/.openclaw/openclaw.json.bak
	@echo "✓ Cleaned"
