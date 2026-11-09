# shellcheck shell=bash
# ~/.grok/grok-env.sh — source from ~/.zshrc:  source ~/.grok/grok-env.sh
#
# Runs grok-cli (@vibe-kit/grok-cli) against Agentgateway with everything scoped to the grok process:
#   GROK_API_KEY      from 1Password at launch (grok-cli reads GROK_API_KEY before user-settings.json's
#                     apiKey — install.sh removes that plaintext key). Set explicitly so a project .env
#                     (grok-cli calls dotenv.config(), which never overrides set vars) can't swap it.
#   GROK_BASE_URL     pinned to the gateway for the same reason.
#   NODE_OPTIONS      --require ~/.grok/grok-preload.cjs: guard, secret-free shells, gateway default
#                     model, strips xAI-only `search_parameters`.
#   NODE_EXTRA_CA_CERTS  OS trust store (public roots + keychain-trusted gateway cert); Node never
#                     reads the macOS keychain by itself.
#   MORPH_API_KEY     unset: Morph fast-apply would send file contents to api.morphllm.com.
#   GROK_MAX_TOKENS   grok-cli's default output cap is 1536 tokens (grok/client.js) — too small to code.
_GROK_KEY_REF="op://private/agent-gateway-api-key/password"   # same item as AGENTGATEWAY_API_KEY in ~/.zshrc
_GROK_GATEWAY="https://scarlet:9443/v1"
_GROK_MODELS="deepseek-flash,claude-sonnet-5,openrouter/openai/gpt-6-sol,openrouter/anthropic/claude-opus-5-5"
_GROK_NO_PROXY="scarlet,sclet,softcraftscarlet,10.10.2.80,localhost,127.0.0.1"

grok() {
  local home="$HOME/.grok" key
  key="$(op read "$_GROK_KEY_REF" 2>/dev/null)"
  [[ -z "$key" ]] && key="${AGENTGATEWAY_API_KEY:-}"
  if [[ -z "$key" ]]; then
    echo "grok: no gateway key — unlock 1Password (op read $_GROK_KEY_REF failed) or export AGENTGATEWAY_API_KEY" >&2
    return 1
  fi
  local f
  for f in ca-bundle.pem grok-preload.cjs guard/guard.py; do
    [[ -s "$home/$f" ]] || { echo "grok: $home/$f missing — run the grok install.sh (make -C <agent-configs>/grok install)" >&2; return 1; }
  done
  local no_proxy_list="${NO_PROXY:-${no_proxy:-}}"
  no_proxy_list="${no_proxy_list:+$no_proxy_list,}$_GROK_NO_PROXY"
  ( unset MORPH_API_KEY
    GROK_API_KEY="$key" GROK_BASE_URL="$_GROK_GATEWAY" GROK_MAX_TOKENS="${GROK_MAX_TOKENS:-16384}" \
    GROK_DEFAULT_MODEL="${GROK_DEFAULT_MODEL:-claude-sonnet-5}" GROK_GATEWAY_MODELS="$_GROK_MODELS" \
    GROK_GUARD="$home/guard/guard.py" NODE_EXTRA_CA_CERTS="$home/ca-bundle.pem" \
    NODE_OPTIONS="--require $home/grok-preload.cjs${NODE_OPTIONS:+ $NODE_OPTIONS}" \
    NO_PROXY="$no_proxy_list" no_proxy="$no_proxy_list" \
      command grok "$@" )
}
