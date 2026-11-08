# ~/.copilot/copilot-aliases.ps1 — dot-source from your PowerShell profile:  . "$HOME\.copilot\copilot-aliases.ps1"
# Windows equivalents of copilot-aliases.sh: BYOK via Agentgateway, secret stripping, push denial.
# Windows Node uses the Windows certificate store only with NODE_USE_SYSTEM_CA; set it so the home-lab CA
# (imported into Trusted Root Certification Authorities) is honoured.
$script:CopGateway = 'https://scarlet:9443/v1'
$script:CopKeyRef  = 'op://private/agent-gateway-api-key/password'
$script:CopSecrets = 'COPILOT_PROVIDER_API_KEY,COPILOT_PROVIDER_BEARER_TOKEN,AGENTGATEWAY_API_KEY,LITELLM_API_KEY,OPENROUTER_API_KEY,OPENAI_API_KEY,ANTHROPIC_AUTH_TOKEN,GEMINI_API_KEY,OLLAMA_API_KEY,GITHUB_PAT,CONTEXT7_API_KEY,OP_SERVICE_ACCOUNT_TOKEN,AI_VAULT_ACCOUNT_TOKEN,AWS_SECRET_ACCESS_KEY,AWS_SESSION_TOKEN'

function Invoke-CopilotSafe {
    [CmdletBinding(PositionalBinding = $false)]
    param([string]$Model = $(if ($env:COP_MODEL) { $env:COP_MODEL } else { 'claude-sonnet-5' }),
          [Parameter(ValueFromRemainingArguments)][string[]]$Rest)
    $key = (& op read $script:CopKeyRef 2>$null)               # 1Password first: survives rotation
    if (-not $key) { $key = $env:AGENTGATEWAY_API_KEY }
    if (-not $key) { Write-Error "cop: no gateway key (AGENTGATEWAY_API_KEY unset and op read $script:CopKeyRef failed)"; return }
    $vars = @{ COPILOT_PROVIDER_TYPE = 'openai'; COPILOT_PROVIDER_BASE_URL = $script:CopGateway; COPILOT_PROVIDER_WIRE_API = 'completions'
               COPILOT_PROVIDER_API_KEY = $key; COPILOT_MODEL = $Model; NODE_USE_SYSTEM_CA = '1' }
    $saved = @{}; foreach ($k in $vars.Keys) { $saved[$k] = [Environment]::GetEnvironmentVariable($k, 'Process'); [Environment]::SetEnvironmentVariable($k, $vars[$k], 'Process') }
    try { & copilot "--secret-env-vars=$script:CopSecrets" '--deny-tool=shell(git push)' '--deny-tool=shell(gh auth token)' @Rest }
    finally { foreach ($k in $saved.Keys) { [Environment]::SetEnvironmentVariable($k, $saved[$k], 'Process') } }
}
function cop       { Invoke-CopilotSafe --agent router @args }
function cop-dev   { Invoke-CopilotSafe --agent developer @args }
function cop-sre   { Invoke-CopilotSafe --agent sre @args }
function cop-plan  { Invoke-CopilotSafe --agent planner --plan @args }
function cop-sec   { Invoke-CopilotSafe --agent security @args }
function cop-cheap { Invoke-CopilotSafe -Model 'deepseek-flash' --model deepseek-flash --effort low @args }
function cop-cap   { $c = if ($env:COP_MAX_CREDITS) { $env:COP_MAX_CREDITS } else { '200' }; Invoke-CopilotSafe --agent router --max-ai-credits $c @args }
