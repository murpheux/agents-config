# ~/.copilot/copilot-aliases.sh — source from ~/.zshrc / ~/.bashrc:  source ~/.copilot/copilot-aliases.sh
# Tiered entry points for the GitHub Copilot CLI. --secret-env-vars strips these variables from shell/MCP
# environments and redacts them from output; --deny-tool blocks pushes outright (the guard hook covers the rest).
_COP_SECRETS="AGENTGATEWAY_API_KEY,LITELLM_API_KEY,OPENROUTER_API_KEY,GITHUB_PAT,CONTEXT7_API_KEY,OP_SERVICE_ACCOUNT_TOKEN,AWS_SECRET_ACCESS_KEY,AWS_SESSION_TOKEN"
_cop() { copilot --secret-env-vars="$_COP_SECRETS" --deny-tool='shell(git push)' --deny-tool='shell(gh auth token)' "$@"; }

cop()       { _cop --agent router "$@"; }                       # default: cheap router delegates to specialists
cop-dev()   { _cop --agent developer "$@"; }                    # direct implementation session
cop-sre()   { _cop --agent sre "$@"; }                          # incident / live-system diagnosis
cop-plan()  { _cop --agent planner --plan "$@"; }               # plan only
cop-sec()   { _cop --agent security "$@"; }                     # security review (premium)
cop-cheap() { _cop --model gpt-5-mini --effort low "$@"; }      # quick Q&A on the cheapest tier
cop-cap()   { _cop --agent router --max-ai-credits "${COP_MAX_CREDITS:-200}" "$@"; }   # hard session budget
