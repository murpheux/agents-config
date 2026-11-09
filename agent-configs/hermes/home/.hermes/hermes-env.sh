# shellcheck shell=bash
# ~/.hermes/hermes-env.sh — source from ~/.zshrc:  source ~/.hermes/hermes-env.sh
#
# Key and TLS need no wrapper: config.yaml's agentgateway provider mints the key itself (key_cmd →
# `op read`) and pins its own CA bundle (ssl_ca_cert). This only fixes the proxy case: Hermes' httpx
# honours HTTP(S)_PROXY/ALL_PROXY, and panes of a long-lived multiplexer (herdr, tmux) inherit the
# environment their server started with — e.g. a dead sandbox proxy — so every gateway call fails with
# "All connection attempts failed". The gateway is on the LAN, so it always bypasses any proxy.
# (The Hermes desktop app and `hermes gateway` services don't go through this function.)
_HERMES_NO_PROXY="scarlet,sclet,softcraftscarlet,10.10.2.80,localhost,127.0.0.1"

hermes() {
  local list="${NO_PROXY:-${no_proxy:-}}"
  list="${list:+$list,}$_HERMES_NO_PROXY"
  NO_PROXY="$list" no_proxy="$list" command hermes "$@"
}
