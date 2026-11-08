#!/usr/bin/env bash
# Install the VS Code (Copilot Chat) configuration on macOS / Linux / WSL. Backs up what it replaces.
#  - <profile>/settings.json is MERGED; <profile>/mcp.json and prompts are copied.
#  - ~/.copilot (instructions, agents, skills, hooks, mcp-config.json) is shared with the Copilot CLI folder.
# On Windows + WSL run install.ps1 on Windows too: each harness reads the host it runs on.
#   ./install.sh   |   DRY_RUN=1 ./install.sh   |   VSCODE_PROFILE_DIR=/path ./install.sh
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"

case "$(os_kind)" in
  macos) P="${VSCODE_PROFILE_DIR:-$HOME/Library/Application Support/Code/User}" ;;
  wsl)   P="${VSCODE_PROFILE_DIR:-$HOME/.vscode-server/data/Machine}"; warn "WSL: user settings/prompts live on Windows — run install.ps1 there; installing ~/.copilot + remote machine settings here" ;;
  *)     P="${VSCODE_PROFILE_DIR:-$HOME/.config/Code/User}" ;;
esac
C="${COPILOT_HOME:-$HOME/.copilot}"
log "VS Code profile → $P ; shared Copilot home → $C"

for d in agents instructions hooks; do install_tree vscode "$HERE/home/.copilot/$d" "$C/$d"; done
install_file vscode "$HERE/home/.copilot/mcp-config.json" "$C/mcp-config.json"
install_file vscode "$HERE/home/.copilot/mcp.op.env" "$C/mcp.op.env" 600
while IFS= read -r -d '' s; do
  id="$(basename "$s")"
  if [[ -f "$HOME/.agents/skills/$id/SKILL.md" ]] && cmp -s "$s/SKILL.md" "$HOME/.agents/skills/$id/SKILL.md"; then continue; fi
  install_tree vscode "$s" "$C/skills/$id"
done < <(find "$HERE/home/.copilot/skills" -mindepth 1 -maxdepth 1 -type d -print0)
run chmod +x "$C/hooks/guard.py"

if [[ "$(os_kind)" != wsl || -n "${VSCODE_PROFILE_DIR:-}" ]]; then
  install_tree vscode "$HERE/home/vscode-profile/prompts" "$P/prompts"
  install_file vscode "$HERE/home/vscode-profile/mcp.json" "$P/mcp.json"
fi
if [[ "$DRY_RUN" != 1 ]]; then
  python3 "$HERE/lib/merge_json.py" "$P/settings.json" "$HERE/home/vscode-profile/settings.fragment.jsonc"
  python3 "$C/hooks/guard.py" --self-test >/dev/null && log "guard hook self-test passed" || die "guard self-test failed"
fi
[[ "$(os_kind)" == wsl ]] && { need bwrap "VS Code terminal sandbox on WSL2: sudo apt install bubblewrap socat"; need socat "terminal sandbox"; }

cat <<'EOF'

Next steps
  1. Reload VS Code → Chat → agent picker → "Router".  Check: Chat: Diagnostics (loaded agents/tools/hooks).
  2. Confirm model names in "Chat: Manage Language Models" (agents use fallbacks + Auto if a name differs).
  3. Optional plugins (awesome-copilot marketplace is built in): Extensions view → @agentPlugins.
EOF
