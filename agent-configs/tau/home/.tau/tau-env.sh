# shellcheck shell=bash
# ~/.tau/tau-env.sh — source from ~/.zshrc (after the SSL_CERT_FILE block):  source ~/.tau/tau-env.sh
#
# TLS: Tau's provider calls use httpx, which trusts ONLY $SSL_CERT_FILE (else $SSL_CERT_DIR, else
# certifi) and never the macOS keychain. The shell's SSL_CERT_FILE is the public Mozilla bundle, so
# the gateway's self-signed cert fails ("self-signed certificate"); pointing it at the gateway cert
# alone breaks every public endpoint ("unable to get local issuer certificate"). ~/.tau/ca-bundle.pem
# (built by install.sh from the OS trust store) holds both.
# Key: fetched from 1Password at launch (survives rotation / a 1Password locked at shell start) and
# scoped to the tau process — catalog.toml reads it from AGENTGATEWAY_API_KEY.
_TAU_KEY_REF="op://private/agent-gateway-api-key/password"   # same item as AGENTGATEWAY_API_KEY in ~/.zshrc

tau() {
  local home="${TAU_HOME:-$HOME/.tau}" key
  key="$(op read "$_TAU_KEY_REF" 2>/dev/null)"
  [[ -z "$key" ]] && key="${AGENTGATEWAY_API_KEY:-}"
  if [[ -z "$key" ]]; then
    echo "tau: no gateway key — unlock 1Password (op read $_TAU_KEY_REF failed) or export AGENTGATEWAY_API_KEY" >&2
    return 1
  fi
  if [[ ! -s "$home/ca-bundle.pem" ]]; then
    echo "tau: $home/ca-bundle.pem missing — run the Tau install.sh (make -C <agent-configs>/tau install)" >&2
    return 1
  fi
  ( unset SSL_CERT_DIR
    SSL_CERT_FILE="$home/ca-bundle.pem" REQUESTS_CA_BUNDLE="$home/ca-bundle.pem" AGENTGATEWAY_API_KEY="$key" \
      command tau "$@" )
}
