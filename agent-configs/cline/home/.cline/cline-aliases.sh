# ~/.cline/cline-aliases.sh — source from ~/.zshrc / ~/.bashrc:  source ~/.cline/cline-aliases.sh
#
# The Cline CLI's TUI needs a real terminal. `op run --env-file … -- cline` pipes the child's
# stdout/stderr through 1Password's secret masker, so Cline sees a pipe and refuses to start
# ("interactive mode requires a TTY"). This wrapper fetches the gateway key itself and runs the
# real cline attached to your terminal, with the key scoped to that process tree.
# The openai-compatible provider reads OPENAI_API_KEY (no key is stored in providers.json).
#
# Runs execute in Cline's long-lived hub daemon when one is running, with the environment the hub
# was STARTED with. So the hub is restarted whenever the key changes (rotation, or a hub that was
# spawned by a plain `cline` / VS Code without the key); a 12-char SHA-256 prefix is kept to detect that.
_CLN_KEY_REF="op://private/agent-gateway-api-key/password"   # same item as AGENTGATEWAY_API_KEY in ~/.zshrc
_CLN_FP_FILE="$HOME/.cline/.hub-key-fingerprint"

_cln_key() {
  local key
  key="$(op read "$_CLN_KEY_REF" 2>/dev/null)"                 # 1Password first: survives key rotation
  [[ -z "$key" ]] && key="${AGENTGATEWAY_API_KEY:-}"
  [[ -z "$key" ]] && { echo "cline: no gateway key (op read $_CLN_KEY_REF failed and AGENTGATEWAY_API_KEY unset)" >&2; return 1; }
  printf '%s' "$key"
}

_cln_fp() { printf '%s' "$1" | shasum -a 256 | cut -c1-12; }

cline() {
  local key fp
  key="$(_cln_key)" || return 1
  fp="$(_cln_fp "$key")"
  if [[ "$(cat "$_CLN_FP_FILE" 2>/dev/null)" != "$fp" ]]; then
    command cline hub stop >/dev/null 2>&1 || true            # next run starts a hub with this key
    ( umask 077; printf '%s\n' "$fp" > "$_CLN_FP_FILE" )
  fi
  OPENAI_API_KEY="$key" command cline "$@"
}

# VS Code (extension `next` build shares ~/.cline and its hub): GUI apps don't need a TTY, so op run
# works here. Stop the hub first so it is restarted with the key, as above.
cline-code() {
  command cline hub stop >/dev/null 2>&1 || true
  rm -f "$_CLN_FP_FILE"
  op run --env-file "$HOME/.cline/cline.op.env" -- code "${@:-.}"
}
