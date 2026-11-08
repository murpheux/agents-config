#Requires -Version 7.0
<#
.SYNOPSIS
  Install the VS Code (Copilot Chat) configuration on Windows: merges %APPDATA%\Code\User\settings.json,
  copies mcp.json + prompt files into the profile, and the shared ~/.copilot core (instructions, agents, skills, hooks).
.EXAMPLE
  pwsh -File install.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param([string]$ProfileDir = (Join-Path $env:APPDATA 'Code\User'))
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$cop  = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { Join-Path $env:USERPROFILE '.copilot' }
$py   = (Get-Command py -ErrorAction SilentlyContinue) ?? (Get-Command python -ErrorAction SilentlyContinue)
if (-not $py) { throw 'Python 3 is required (settings merge + guard hook). Install from python.org.' }
$pyArgs = if ($py.Name -like 'py*') { @('-3') } else { @() }

foreach ($d in 'agents', 'instructions', 'hooks', 'skills') {
    if ($PSCmdlet.ShouldProcess("$cop\$d", 'copy')) {
        New-Item -ItemType Directory -Force (Join-Path $cop $d) | Out-Null
        Copy-Item (Join-Path $here "home\.copilot\$d\*") (Join-Path $cop $d) -Recurse -Force
    }
}
foreach ($f in 'mcp-config.json', 'mcp.op.env') {
    if ($PSCmdlet.ShouldProcess("$cop\$f", 'copy')) { Copy-Item (Join-Path $here "home\.copilot\$f") (Join-Path $cop $f) -Force }
}
if ($PSCmdlet.ShouldProcess("$ProfileDir\prompts", 'copy prompt files')) {
    New-Item -ItemType Directory -Force (Join-Path $ProfileDir 'prompts') | Out-Null
    Copy-Item (Join-Path $here 'home\vscode-profile\prompts\*') (Join-Path $ProfileDir 'prompts') -Force
    Copy-Item (Join-Path $here 'home\vscode-profile\mcp.json') (Join-Path $ProfileDir 'mcp.json') -Force
}
if ($PSCmdlet.ShouldProcess("$ProfileDir\settings.json", 'merge')) {
    & $py.Source @pyArgs (Join-Path $here 'lib\merge_json.py') (Join-Path $ProfileDir 'settings.json') (Join-Path $here 'home\vscode-profile\settings.fragment.jsonc')
    & $py.Source @pyArgs (Join-Path $cop 'hooks\guard.py') --self-test | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'guard hook self-test failed' }
}
Write-Information 'Done. Reload VS Code, open Chat and pick the "Router" agent.' -InformationAction Continue
