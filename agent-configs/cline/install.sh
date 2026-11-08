#!/usr/bin/env bash
# Install the Cline configuration (macOS or Linux/WSL). Backs up what it replaces.
#   ./install.sh            install      DRY_RUN=1 ./install.sh   preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"

# Cline resolves "Documents" per OS (xdg-user-dir on Linux; often ~/Documents, sometimes ~/Cline on WSL).
DOCS="$HOME/Documents"
if [[ "$(os_kind)" != macos ]] && command -v xdg-user-dir >/dev/null 2>&1; then
  d="$(xdg-user-dir DOCUMENTS 2>/dev/null || true)"; [[ -n "$d" && "$d" != "$HOME" ]] && DOCS="$d"
fi

log "Cline config → $DOCS/Cline (rules, workflows, hooks) and $HOME/.cline (skills, agents, guard, MCP)"
install_tree cline "$HERE/home/Documents/Cline" "$DOCS/Cline"
install_tree cline "$HERE/home/.cline" "$HOME/.cline"
run chmod +x "$DOCS/Cline/Hooks/PreToolUse" "$HOME/.cline/guard/guard.py"
run chmod 600 "$HOME/.cline/mcp.op.env" "$HOME/.cline/cline.op.env"
# Cline also reads ~/Cline/Rules on next/CLI; mirror rules there when Documents is not ~/Documents.
[[ "$DOCS" != "$HOME/Documents" ]] && log "rules installed under $DOCS/Cline (xdg Documents dir)"

if [[ "$DRY_RUN" != 1 ]]; then
  python3 "$HOME/.cline/guard/guard.py" --self-test >/dev/null && log "guard hook self-test passed" \
    || die "guard hook self-test failed"
  printf '%s' '{"hookName":"PreToolUse","tool_call":{"name":"run_commands","input":{"commands":["git push --force"]}}}' \
    | "$DOCS/Cline/Hooks/PreToolUse" | grep -q '"cancel": true' && log "hook blocks force-push ✔" || die "hook smoke test failed"
fi

# Provider: openai-compatible → Agentgateway, key-free (OPENAI_API_KEY from op run / your shell).
# Shared by the Cline CLI and the extension's `next` build (both use ~/.cline/data).
GATEWAY_URL="https://scarlet:9443/v1"
for f in models.json providers.json; do backup_path cline "$HOME/.cline/data/settings/$f"; done
if [[ "$DRY_RUN" == 1 ]]; then python3 "$HERE/lib/configure-gateway-provider.py" "$HOME/.cline/data" --dry-run
else python3 "$HERE/lib/configure-gateway-provider.py" "$HOME/.cline/data" && log "Cline provider configured"; fi

need cline   "Cline CLI (npm i -g cline)"
need python3 "required by the guard hook"
need op      "1Password CLI — MCP servers and providers get credentials via op run"
need docker  "github + terraform MCP servers"
need uvx     "awsdocs MCP server"

cat <<EOF

Next steps (in the Cline panel → Settings; these live in extension state, not files)
  1. Pin the build: add templates/vscode-settings.fragment.json to VS Code user settings ("cline.rollout.bundleOverride": "next").
  2. Provider is OpenAI Compatible → Agentgateway ($GATEWAY_URL), model claude-sonnet-5 (all ids are gateway ids;
     /model openrouter/openai/gpt-6-sol for planning). Leave the API key empty — it comes from OPENAI_API_KEY:
       add to ~/.zshrc:  source ~/.cline/cline-aliases.sh
       CLI:      cline …          (wrapper: fetches the key, keeps the TTY; "op run -- cline" cannot, it pipes stdout)
       VS Code:  cline-code .     (= op run --env-file ~/.cline/cline.op.env -- code .)
     Smoke test:  cline -P openai-compatible -m deepseek-flash --auto-approve false "Reply with: ok"
  3. Auto-approve: Read ✔, Edit ✗, Execute commands ✗, Browser ✗, MCP ✔ (read-only servers). Hooks: enabled. Auto-condense: on.
  4. Per repo: copy templates/.clineignore (legacy build) and add project rules under .clinerules/.
EOF
