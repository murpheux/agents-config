#!/usr/bin/env bash
# Install the Claude Code configuration into ~/.claude (macOS or Linux/WSL2). Backs up what it replaces.
#   ./install.sh               install (Anthropic account / subscription)
#   ./install.sh --gateway     also route through Agentgateway (merges settings.gateway.json)
#   DRY_RUN=1 ./install.sh     preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"
GATEWAY=0; [[ "${1:-}" == "--gateway" ]] && GATEWAY=1

log "Claude Code config → $HOME/.claude ($(os_kind))"
install_tree claude-code "$HERE/home/.claude" "$HOME/.claude"
run chmod +x "$HOME/.claude/hooks/guard.py" "$HOME/.claude/statusline.py"

if [[ "$DRY_RUN" != 1 ]]; then
  python3 "$HOME/.claude/hooks/guard.py" --self-test >/dev/null && log "guard hook self-test passed" \
    || die "guard hook self-test failed — the PreToolUse gate would fail open"
  if [[ "$GATEWAY" == 1 ]]; then
    python3 - "$HOME/.claude/settings.json" "$HOME/.claude/settings.gateway.json" <<'PY'
import json, sys
base, overlay = (json.load(open(p)) for p in sys.argv[1:3])
for k, v in overlay.items():
    if k.startswith("_"):
        continue
    if isinstance(v, dict) and isinstance(base.get(k), dict):
        base[k].update(v)
    else:
        base[k] = v
json.dump(base, open(sys.argv[1], "w"), indent=2)
print("merged gateway overlay into", sys.argv[1])
PY
  fi
fi

need claude  "install: curl -fsSL https://claude.ai/install.sh | bash   (review the script first)"
need python3 "required by the guard hook and status line"
[[ "$(os_kind)" == wsl ]] && { need bwrap "sandbox on WSL2 needs: sudo apt install bubblewrap socat"; need socat "sandbox on WSL2"; }

cat <<'EOF'

Next steps
  1. Register MCP servers (user scope):   ./mcp/add-mcp-servers.sh
  2. Start:                               claude            (main session = router on Haiku)
     Direct session without the router:   ROUTER_MODE=off claude --agent developer
  3. Check the setup:                     /agents   /hooks   /permissions   /context
  4. Cost reports (optional):             npx ccusage@latest
EOF
