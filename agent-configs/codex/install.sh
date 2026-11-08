#!/usr/bin/env bash
# Install the Codex CLI configuration into $HOME (macOS or Linux/WSL2). Backs up what it replaces.
#   ./install.sh            install
#   DRY_RUN=1 ./install.sh  preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"

log "Codex config → $HOME/.codex and $HOME/.agents/skills ($(os_kind))"
install_tree codex "$HERE/home/.codex" "$HOME/.codex"   # includes .codex/skills (workflow skills)
install_tree codex "$HERE/home/.agents/skills" "$HOME/.agents/skills"
run chmod +x "$HOME/.codex/hooks/guard.py"

if [[ "$DRY_RUN" != 1 ]]; then
  python3 "$HOME/.codex/hooks/guard.py" --self-test >/dev/null && log "guard hook self-test passed" \
    || die "guard hook self-test failed — hooks would not protect you"
fi

need codex    "install: npm i -g @openai/codex  (or brew install codex)"
need python3  "required by the guard hook"
need op       "used by the gateway provider auth command"
need uvx      "needed by the awsdocs MCP server (or remove it from config.toml)"
need docker   "needed by the terraform MCP server (or remove it from config.toml)"

cat <<'EOF'

Next steps
  1. Sign in:            codex login            (or use --profile gateway with Agentgateway)
  2. Validate config:    codex --strict-config  (unknown keys are otherwise ignored silently)
  3. Trust the hook:     start codex → /hooks → trust guard.py (new/changed hooks need trust)
  4. Test the rules:     codex execpolicy check --pretty --rules ~/.codex/rules/guardrails.rules -- terraform destroy
  5. Export for MCP:     GITHUB_PAT, CONTEXT7_API_KEY (via `op run` or your shell profile — never in config.toml)
EOF
