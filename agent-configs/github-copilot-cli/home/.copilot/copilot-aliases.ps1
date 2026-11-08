# ~/.copilot/copilot-aliases.ps1 — dot-source from your PowerShell profile:  . "$HOME\.copilot\copilot-aliases.ps1"
# Windows equivalents of copilot-aliases.sh (tiered entry points, secret stripping, push denial).
$script:CopSecrets = 'AGENTGATEWAY_API_KEY,LITELLM_API_KEY,OPENROUTER_API_KEY,GITHUB_PAT,CONTEXT7_API_KEY,OP_SERVICE_ACCOUNT_TOKEN,AWS_SECRET_ACCESS_KEY,AWS_SESSION_TOKEN'

function Invoke-CopilotSafe {
    [CmdletBinding()]
    param([Parameter(ValueFromRemainingArguments)][string[]]$Rest)
    & copilot "--secret-env-vars=$script:CopSecrets" '--deny-tool=shell(git push)' '--deny-tool=shell(gh auth token)' @Rest
}
function cop       { Invoke-CopilotSafe --agent router @args }
function cop-dev   { Invoke-CopilotSafe --agent developer @args }
function cop-sre   { Invoke-CopilotSafe --agent sre @args }
function cop-plan  { Invoke-CopilotSafe --agent planner --plan @args }
function cop-sec   { Invoke-CopilotSafe --agent security @args }
function cop-cheap { Invoke-CopilotSafe --model gpt-5-mini --effort low @args }
function cop-cap   { $c = if ($env:COP_MAX_CREDITS) { $env:COP_MAX_CREDITS } else { '200' }; Invoke-CopilotSafe --agent router --max-ai-credits $c @args }
