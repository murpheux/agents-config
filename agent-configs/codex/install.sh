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

# Codex reads everything (config, agents, hooks, rules) from $CODEX_HOME only.
if [[ -n "${CODEX_HOME:-}" && "$(cd "$CODEX_HOME" 2>/dev/null && pwd -P)" != "$(cd "$HOME/.codex" && pwd -P)" ]]; then
  warn "CODEX_HOME=$CODEX_HOME — Codex will IGNORE $HOME/.codex (no agents, no gateway). Unset it in your shell profile."
fi

# TLS: the macOS platform verifier trusts the home-lab CA via the keychain. A custom bundle replaces
# it and the gateway handshake fails, so Codex must run without one.
for v in CODEX_CA_CERTIFICATE SSL_CERT_FILE; do
  [[ -n "${!v:-}" ]] && warn "$v is set — Codex would use it instead of the macOS trust store and fail on https://scarlet:9443. Run codex via ~/.codex/codex-env.sh."
done
[[ -e "$HOME/.codex/ca-bundle.pem" ]] && { backup_path codex "$HOME/.codex/ca-bundle.pem"; run rm -f "$HOME/.codex/ca-bundle.pem"; }

# Model picker: Codex can't decode the gateway's OpenAI-style /v1/models, so give it a static catalog.
if [[ "$DRY_RUN" == 1 ]]; then echo "DRY: build $HOME/.codex/model-catalog.json"
elif command -v codex >/dev/null; then
  python3 "$HERE/lib/build_model_catalog.py" "$HOME/.codex/model-catalog.json" && log "model catalog written" \
    || die "could not build ~/.codex/model-catalog.json (config.toml points at it)"
fi

need codex    "install: npm i -g @openai/codex  (or brew install codex)"
need python3  "required by the guard hook"
need op       "used by the gateway provider auth command"
need uvx      "needed by the awsdocs MCP server (or remove it from config.toml)"
need docker   "needed by the terraform MCP server (or remove it from config.toml)"

cat <<'EOF'

Next steps
  1. Shell profile:      CODEX_HOME unset (or ~/.codex), and add AFTER the SSL_CERT_FILE block:
                           source ~/.codex/codex-env.sh
                         (runs codex without SSL_CERT_FILE so it trusts the macOS keychain).
                         Then: exec zsh; codex app-server daemon restart; quit + reopen the desktop app.
  2. Gateway auth:       Codex runs `op read` itself — approve the 1Password prompt on first use.
                         `codex login` is not used; all models go through Agentgateway.
  3. Validate config:    codex --strict-config doctor   (unknown keys are otherwise ignored silently)
  4. Trust the hook:     start codex → /hooks → trust guard.py (new/changed hooks need trust)
  5. Test the rules:     codex execpolicy check --pretty --rules ~/.codex/rules/guardrails.rules -- terraform destroy
  6. Export for MCP:     GITHUB_PAT, CONTEXT7_API_KEY (via `op run` or your shell profile — never in config.toml)
EOF
