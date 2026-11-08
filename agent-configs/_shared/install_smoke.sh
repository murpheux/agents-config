#!/usr/bin/env bash
# Smoke-test every installer against a throwaway $HOME (never touches the real home).
set -uo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0; fail=0
ok()  { echo "  ✔ $*"; pass=$((pass + 1)); }
bad() { echo "  ✘ $*"; fail=$((fail + 1)); }
chk() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }
FORCE_PUSH_CLAUDE='{"tool_name":"Bash","tool_input":{"command":"git -C . push --force origin main"},"agent_id":"a1"}'

for tool in aider claude-code codex cline github-copilot-cli vscode opencode; do
  H="$(mktemp -d)"; echo "== $tool  (HOME=$H)"
  mkdir -p "$H/.copilot" && printf '{\n  // existing user setting\n  "theme": "dim"\n}\n' > "$H/.copilot/settings.json"
  mkdir -p "$H/.config/opencode/agents" && echo "old" > "$H/.config/opencode/agents/murpheux.md"
  mkdir -p "$H/.config/Code/User" && echo '{"editor.fontSize": 14}' > "$H/.config/Code/User/settings.json"
  if HOME="$H" USER=tester VSCODE_PROFILE_DIR="$H/.config/Code/User" bash "$ROOT/$tool/install.sh" >"$H/install.log" 2>&1; then ok "installer exits 0"; else bad "installer failed: $(tail -3 "$H/install.log")"; fi
  chk "no __HOME__/__CA_BUNDLE__ tokens left" "! grep -rIl '__HOME__\|__CA_BUNDLE__' '$H' --exclude=install.log >/dev/null 2>&1"
  case "$tool" in
    aider)
      chk "~/.aider.conf.yml parses" "python3 -c 'import yaml,sys; d=yaml.safe_load(open(sys.argv[1])); assert d[\"model\"]==\"openai/claude-sonnet-5\" and \"$H\" in d[\"model-settings-file\"]' '$H/.aider.conf.yml'"
      chk "CONVENTIONS.md + 20 skills + skill loaders" "[[ -s '$H/.aider/CONVENTIONS.md' ]] && [[ \$(ls '$H/.aider/skills' | wc -l) -eq 20 ]] && [[ -f '$H/.aider/commands/skill-terraform.cmds' ]]"
      chk "op env file is 0600" "[[ \$(stat -c %a '$H/.aider/aider.op.env') == 600 ]]" ;;
    claude-code)
      chk "settings.json parses, agent=router" "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d[\"agent\"]==\"router\"' '$H/.claude/settings.json'"
      chk "8 agents, 16 commands, 20 skills" "[[ \$(ls '$H/.claude/agents' | wc -l) -eq 8 && \$(ls '$H/.claude/commands' | wc -l) -eq 16 && \$(ls '$H/.claude/skills' | wc -l) -eq 20 ]]"
      chk "hook denies force-push (subagent)" "echo '$FORCE_PUSH_CLAUDE' | python3 '$H/.claude/hooks/guard.py' --format claude --main-thread-readonly | grep -q '\"deny\"'"
      chk "router gate denies main-thread Edit" "echo '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"a.go\"}}' | python3 '$H/.claude/hooks/guard.py' --format claude --main-thread-readonly | grep -q router"
      chk "statusline renders" "echo '{\"model\":{\"display_name\":\"Haiku\"},\"cost\":{\"total_cost_usd\":0.12},\"context_window\":{\"used_percentage\":41}}' | python3 '$H/.claude/statusline.py' | grep -q '0.12'" ;;
    codex)
      chk "config.toml + profiles parse" "for f in '$H'/.codex/*.toml '$H'/.codex/agents/*.toml; do python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1],\"rb\"))' \"\$f\" || exit 1; done"
      chk "hook command points at installed guard" "grep -q \"python3 $H/.codex/hooks/guard.py\" '$H/.codex/config.toml'"
      chk "20 portable + 16 workflow skills" "[[ \$(ls '$H/.agents/skills' | wc -l) -eq 20 && \$(ls '$H/.codex/skills' | wc -l) -eq 16 ]]"
      chk "hook exits 2 on force-push" "echo '{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":[\"bash\",\"-lc\",\"git push -f\"]}}' | python3 '$H/.codex/hooks/guard.py' --format codex 2>/dev/null; [[ \$? -eq 2 ]]" ;;
    cline)
      chk "rules + 16 workflows installed" "[[ -s '$H/Documents/Cline/Rules/00-murpheux.md' && \$(ls '$H/Documents/Cline/Workflows' | wc -l) -eq 16 ]]"
      chk "hook executable and cancels force-push (next payload)" "[[ -x '$H/Documents/Cline/Hooks/PreToolUse' ]] && echo '{\"tool_call\":{\"name\":\"run_commands\",\"input\":{\"commands\":[\"git push --force\"]}}}' | HOME='$H' '$H/Documents/Cline/Hooks/PreToolUse' | grep -q '\"cancel\": true'"
      chk "hook allows safe legacy command" "echo '{\"preToolUse\":{\"toolName\":\"execute_command\",\"parameters\":{\"command\":\"go test ./...\"}}}' | HOME='$H' '$H/Documents/Cline/Hooks/PreToolUse' | grep -q '\"cancel\":false\|\"cancel\": false'"
      chk "MCP settings rendered with home path" "grep -q '$H/.cline/mcp.op.env' '$H/.cline/data/settings/cline_mcp_settings.json'" ;;
    github-copilot-cli)
      chk "settings merged (kept theme, added subagents)" "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d[\"theme\"]==\"dim\" and d[\"subagents\"][\"agents\"][\"developer\"][\"model\"]==\"claude-sonnet-5\"' '$H/.copilot/settings.json'"
      chk "8 agents, 33 skills, hook json" "[[ \$(ls '$H/.copilot/agents' | wc -l) -eq 8 && \$(ls '$H/.copilot/skills' | wc -l) -eq 33 && -f '$H/.copilot/hooks/guard.json' ]]"
      chk "hook exits 2 on force-push (CLI payload)" "echo '{\"toolName\":\"bash\",\"toolArgs\":{\"command\":\"git push -f\"}}' | python3 '$H/.copilot/hooks/guard.py' --format copilot >/dev/null; [[ \$? -eq 2 ]]" ;;
    vscode)
      chk "VS Code settings merged (kept fontSize)" "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d[\"editor.fontSize\"]==14 and d[\"chat.useHooks\"] is True' '$H/.config/Code/User/settings.json'"
      chk "16 prompt files + mcp.json in profile" "[[ \$(ls '$H/.config/Code/User/prompts' | wc -l) -eq 16 && -f '$H/.config/Code/User/mcp.json' ]]"
      chk "8 vscode agents target vscode" "[[ \$(grep -l '^target: vscode' '$H'/.copilot/agents/vscode-*.agent.md | wc -l) -eq 8 ]]" ;;
    opencode)
      chk "config, 7 agents, 16 commands, 20 skills installed" "[[ -f '$H/.config/opencode/opencode.jsonc' && \$(ls '$H/.config/opencode/agents' | grep -vc murpheux) -eq 7 && \$(ls '$H/.config/opencode/commands' | wc -l) -eq 16 && \$(ls '$H/.config/opencode/skills' | wc -l) -eq 20 ]]"
      chk "service.json / package files NOT copied" "[[ ! -e '$H/.config/opencode/service.json' && ! -e '$H/.config/opencode/package.json' ]]"
      chk "stale agent reported, not deleted" "grep -q 'stale agents/murpheux.md' '$H/install.log' && [[ -f '$H/.config/opencode/agents/murpheux.md' ]]"
      chk "--prune moves stale agent to backup" "HOME='$H' bash '$ROOT/opencode/install.sh' --prune >/dev/null 2>&1 && [[ ! -e '$H/.config/opencode/agents/murpheux.md' ]] && find '$H/.agent-config-backups' -name murpheux.md | grep -q ." ;;
  esac
  rm -rf "$H"
done
echo "== $pass passed, $fail failed"
exit $(( fail > 0 ))
