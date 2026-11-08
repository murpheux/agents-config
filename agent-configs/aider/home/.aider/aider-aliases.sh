# ~/.aider/aider-aliases.sh — source from ~/.zshrc / ~/.bashrc:  source ~/.aider/aider-aliases.sh
# Tiered entry points (Aider has no router — these ARE the routing table; see CONVENTIONS.md §14).
#
# The gateway key is fetched from 1Password at LAUNCH and scoped to the aider process. Not via
# `op run`: it pipes stdout through its secret masker, so Aider's interactive prompt loses the TTY.
# Not from a shell-startup export either: if 1Password was locked when the shell started, that
# variable is empty for the shell's lifetime ("OPENAI_API_KEY: Not set"). Plain `aider` is wrapped too.
_AI_KEY_REF="op://private/agent-gateway-api-key/password"   # same item as AGENTGATEWAY_API_KEY in ~/.zshrc

_ai() {
  local key
  key="$(op read "$_AI_KEY_REF" 2>/dev/null)"               # 1Password first: survives rotation / locked-at-startup
  [[ -z "$key" ]] && key="${AGENTGATEWAY_API_KEY:-}"
  if [[ -z "$key" ]]; then
    echo "aider: no gateway key — unlock 1Password (op read $_AI_KEY_REF failed) or export AGENTGATEWAY_API_KEY" >&2
    return 1
  fi
  OPENAI_API_KEY="$key" command aider "$@"
}

aider() { _ai "$@"; }                                                     # plain `aider` gets the key too
alias ai='_ai'                                                          # developer: sonnet, code mode
alias ai-ask='_ai --chat-mode ask --model cheap --reasoning-effort low'  # router / quick answers / explore
alias ai-cheap='_ai --model cheap --map-tokens 512'                      # trivial edits
alias ai-arch='_ai --architect --model arch --editor-model dev'          # planner + architect → sonnet applies
alias ai-review='_ai --chat-mode ask --model cheap --load "$HOME/.aider/commands/review.cmds"'
alias ai-sec='_ai --chat-mode ask --model sec --load "$HOME/.aider/commands/security-review.cmds"'
alias ai-sre='_ai --chat-mode ask --model dev'                          # diagnosis with /run of read-only cmds
