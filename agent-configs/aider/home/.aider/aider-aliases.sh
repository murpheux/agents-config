# ~/.aider/aider-aliases.sh — source from ~/.zshrc / ~/.bashrc:  source ~/.aider/aider-aliases.sh
# Tiered entry points (Aider has no router — these ARE the routing table; see CONVENTIONS.md §14).
# Secrets are injected per process by 1Password and never written to disk or shell history.

_ai() {
  if command -v op >/dev/null 2>&1; then
    op run --no-masking --env-file "$HOME/.aider/aider.op.env" -- aider "$@"
  else
    echo "op (1Password CLI) not found — refusing to start aider without injected credentials" >&2
    return 1
  fi
}

alias ai='_ai'                                                          # developer: sonnet, code mode
alias ai-ask='_ai --chat-mode ask --model cheap --reasoning-effort low'  # router / quick answers / explore
alias ai-cheap='_ai --model cheap --map-tokens 512'                      # trivial edits
alias ai-arch='_ai --architect --model arch --editor-model dev'          # planner + architect → sonnet applies
alias ai-review='_ai --chat-mode ask --model cheap --load "$HOME/.aider/commands/review.cmds"'
alias ai-sec='_ai --chat-mode ask --model sec --load "$HOME/.aider/commands/security-review.cmds"'
alias ai-sre='_ai --chat-mode ask --model dev'                          # diagnosis with /run of read-only cmds
