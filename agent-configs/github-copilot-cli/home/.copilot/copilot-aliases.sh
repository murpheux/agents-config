# ~/.copilot/copilot-aliases.sh — source from ~/.zshrc / ~/.bashrc:  source ~/.copilot/copilot-aliases.sh
# Tiered entry points for the GitHub Copilot CLI, all routed through Agentgateway (BYOK).
#
# BYOK is environment-only (see `copilot help providers`), so _cop sets it per invocation and
# overrides any global COPILOT_PROVIDER_* in your shell. Every agent uses this one provider, so the
# agent models in settings.json must be gateway model IDs.
# --secret-env-vars strips these variables from shell/MCP environments and redacts them from output;
# --deny-tool blocks pushes outright (the guard hook covers the rest).
_COP_GATEWAY="https://scarlet:9443/v1"
_COP_KEY_REF="op://private/agent-gateway-api-key/password"   # same item as AGENTGATEWAY_API_KEY in ~/.zshrc
_COP_SECRETS="COPILOT_PROVIDER_API_KEY,COPILOT_PROVIDER_BEARER_TOKEN,AGENTGATEWAY_API_KEY,LITELLM_API_KEY,OPENROUTER_API_KEY,OPENAI_API_KEY,ANTHROPIC_AUTH_TOKEN,GEMINI_API_KEY,OLLAMA_API_KEY,GITHUB_PAT,CONTEXT7_API_KEY,OP_SERVICE_ACCOUNT_TOKEN,AI_VAULT_ACCOUNT_TOKEN,AWS_SECRET_ACCESS_KEY,AWS_SESSION_TOKEN"

_cop() {
  local key
  key="$(op read "$_COP_KEY_REF" 2>/dev/null)"              # 1Password first: survives rotation / locked-at-startup
  [[ -z "$key" ]] && key="${AGENTGATEWAY_API_KEY:-}"
  [[ -z "$key" ]] && { echo "cop: no gateway key — unlock 1Password (op read $_COP_KEY_REF failed) or export AGENTGATEWAY_API_KEY" >&2; return 1; }
  COPILOT_PROVIDER_TYPE=openai \
  COPILOT_PROVIDER_BASE_URL="$_COP_GATEWAY" \
  COPILOT_PROVIDER_WIRE_API=completions \
  COPILOT_PROVIDER_API_KEY="$key" \
  COPILOT_MODEL="${COP_MODEL:-claude-sonnet-5}" \
  NODE_EXTRA_CA_CERTS="$HOME/.copilot/ca-bundle.pem" \
    copilot --secret-env-vars="$_COP_SECRETS" --deny-tool='shell(git push)' --deny-tool='shell(gh auth token)' "$@"
}

cop()       { _cop --agent router "$@"; }                       # default: cheap router delegates to specialists
cop-dev()   { _cop --agent developer "$@"; }                    # direct implementation session
cop-sre()   { _cop --agent sre "$@"; }                          # incident / live-system diagnosis
cop-plan()  { _cop --agent planner --plan "$@"; }               # plan only
cop-sec()   { _cop --agent security "$@"; }                     # security review (premium)
cop-cheap() { COP_MODEL=deepseek-flash _cop --model deepseek-flash "$@"; }   # quick Q&A on the cheapest tier
cop-cap()   { _cop --agent router --max-ai-credits "${COP_MAX_CREDITS:-200}" "$@"; }   # hard session budget (GitHub-billed sessions only)
