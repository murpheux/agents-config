#!/usr/bin/env bash
# Install the GitHub Copilot CLI configuration into ~/.copilot (macOS or Linux/WSL). Backs up what it replaces.
# ~/.copilot/settings.json is MERGED (your keys are kept); everything else is copied.
#   ./install.sh              install
#   ./install.sh --managed    also install the optional root-owned managed-settings.json (sudo)
#   DRY_RUN=1 ./install.sh    preview
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib/install-lib.sh"
C="${COPILOT_HOME:-$HOME/.copilot}"

log "GitHub Copilot CLI config → $C ($(os_kind))"
for d in agents instructions hooks; do install_tree copilot-cli "$HERE/home/.copilot/$d" "$C/$d"; done
install_file copilot-cli "$HERE/home/.copilot/mcp-config.json" "$C/mcp-config.json"
install_file copilot-cli "$HERE/home/.copilot/copilot-aliases.sh" "$C/copilot-aliases.sh"

# Skills: skip portable skills already provided identically via ~/.agents/skills (Codex config), which the CLI also reads.
while IFS= read -r -d '' s; do
  id="$(basename "$s")"
  if [[ -f "$HOME/.agents/skills/$id/SKILL.md" ]] && cmp -s "$s/SKILL.md" "$HOME/.agents/skills/$id/SKILL.md"; then
    log "skill $id already in ~/.agents/skills — not duplicating"; continue
  fi
  install_tree copilot-cli "$s" "$C/skills/$id"
done < <(find "$HERE/home/.copilot/skills" -mindepth 1 -maxdepth 1 -type d -print0)

run chmod +x "$C/hooks/guard.py"
if [[ "$DRY_RUN" != 1 ]]; then
  backup_path copilot-cli "$C/settings.json"
  python3 "$HERE/lib/merge_json.py" "$C/settings.json" "$HERE/home/.copilot/settings.fragment.jsonc"
  python3 "$C/hooks/guard.py" --self-test >/dev/null && log "guard hook self-test passed" || die "guard hook self-test failed (preToolUse would fail closed)"
fi

if [[ "${1:-}" == "--managed" ]]; then
  case "$(os_kind)" in
    macos) dest="/Library/Application Support/GitHubCopilot/managed-settings.json" ;;
    *)     dest="/etc/github-copilot/managed-settings.json" ;;
  esac
  log "installing managed policy → $dest (sudo)"
  run sudo mkdir -p "$(dirname "$dest")"
  run sudo python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); d.pop("_comment",None); json.dump(d,open(sys.argv[2],"w"),indent=2)' "$HERE/managed/managed-settings.json" "$dest"
  run sudo chown root "$dest"; run sudo chmod 644 "$dest"
fi

need copilot "install: brew install copilot-cli  |  npm i -g @github/copilot  |  winget install GitHub.Copilot"
need python3 "required by the guard hook"
cat <<'EOF'

Next steps
  1. Add to ~/.zshrc:  source ~/.copilot/copilot-aliases.sh      then start with:  cop
  2. Inside the CLI check:  /env  (instructions, agents, skills, hooks, MCP)   /subagents   /usage
  3. Optional hard policy:  ./install.sh --managed   (deny/ask/allow rules the model cannot bypass)
EOF
