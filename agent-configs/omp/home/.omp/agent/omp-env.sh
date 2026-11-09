# shellcheck shell=bash
# ~/.omp/agent/omp-env.sh — source from ~/.zshrc:  source ~/.omp/agent/omp-env.sh
#
# Key: models.yml reads AGENTGATEWAY_API_KEY (an env-var NAME); this fetches it from 1Password at
#      launch (survives rotation / a 1Password locked at shell start), scoped to the omp process.
# Leak guard: ~/.zshrc also exports the gateway key as OPENAI_API_KEY / OPENROUTER_API_KEY /
#      ANTHROPIC_AUTH_TOKEN. omp auto-enables any provider whose key is in the env, which would send
#      the gateway key to the public endpoint (as Cline did). Variables equal to the gateway key are unset.
# TLS: omp honours NODE_EXTRA_CA_CERTS (`omp --help`); ca-bundle.pem is the OS trust store incl. the
#      home-lab CA, built and verified against scarlet:9443 by install.sh.
# Proxy: panes of a long-lived multiplexer (herdr) can inherit a dead proxy; the LAN gateway bypasses it.
_OMP_KEY_REF="op://private/agent-gateway-api-key/password"   # same item as AGENTGATEWAY_API_KEY in ~/.zshrc
_OMP_NO_PROXY="scarlet,sclet,softcraftscarlet,10.10.2.80,localhost,127.0.0.1"

omp() {
  local dir="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}" key v no_proxy_list
  key="$(op read "$_OMP_KEY_REF" 2>/dev/null)"
  [[ -z "$key" ]] && key="${AGENTGATEWAY_API_KEY:-}"
  if [[ -z "$key" ]]; then
    echo "omp: no gateway key — unlock 1Password (op read $_OMP_KEY_REF failed) or export AGENTGATEWAY_API_KEY" >&2
    return 1
  fi
  if [[ ! -s "$dir/ca-bundle.pem" ]]; then
    echo "omp: $dir/ca-bundle.pem missing — run the omp install.sh (make -C <agent-configs>/omp install)" >&2
    return 1
  fi
  no_proxy_list="${NO_PROXY:-${no_proxy:-}}"
  no_proxy_list="${no_proxy_list:+$no_proxy_list,}$_OMP_NO_PROXY"
  (
    for v in OPENAI_API_KEY OPENROUTER_API_KEY ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN; do
      [[ "$(printenv "$v")" == "$key" ]] && unset "$v"    # printenv: portable across bash and zsh
    done
    NODE_EXTRA_CA_CERTS="$dir/ca-bundle.pem" AGENTGATEWAY_API_KEY="$key" \
    NO_PROXY="$no_proxy_list" no_proxy="$no_proxy_list" \
      command omp "$@"
  )
}
