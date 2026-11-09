# shellcheck shell=bash
# ~/.config/kilo/kilo-env.sh - source from ~/.zshrc.  SKELETON (Phase 0 research).
# Key: AGENTGATEWAY_API_KEY is read from 1Password at launch, scoped to the process, never stored.
# Leak guard: unset public-provider variables that equal the gateway key.
_KILO_KEY_REF="op://private/agent-gateway-api-key/password"
_KILO_NO_PROXY="scarlet,sclet,softcraftscarlet,10.10.2.80,localhost,127.0.0.1"

kilo() {
  local key v npl
  key="$(op read "$_KILO_KEY_REF" 2>/dev/null)"
  [[ -z "$key" ]] && key="${AGENTGATEWAY_API_KEY:-}"
  if [[ -z "$key" ]]; then
    echo "kilo: no gateway key - unlock 1Password or export AGENTGATEWAY_API_KEY" >&2
    return 1
  fi
  npl="${NO_PROXY:-${no_proxy:-}}"
  npl="${npl:+$npl,}$_KILO_NO_PROXY"
  (
    for v in OPENAI_API_KEY OPENROUTER_API_KEY ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN; do
      [[ "$(printenv "$v")" == "$key" ]] && unset "$v"
    done
    AGENTGATEWAY_API_KEY="$key" NO_PROXY="$npl" no_proxy="$npl" command kilo "$@"
  )
}
