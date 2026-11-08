#Requires -Version 7.0
<#
.SYNOPSIS
  Install the GitHub Copilot CLI configuration on Windows into %USERPROFILE%\.copilot (settings.json is merged).
.PARAMETER Managed
  Also install the optional managed policy to %ProgramFiles%\GitHubCopilot\managed-settings.json (run elevated).
.EXAMPLE
  pwsh -File install.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Managed)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot
$dest = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { Join-Path $env:USERPROFILE '.copilot' }
$src  = Join-Path $here 'home\.copilot'
$py   = (Get-Command py -ErrorAction SilentlyContinue) ?? (Get-Command python -ErrorAction SilentlyContinue)
if (-not $py) { throw 'Python 3 is required (guard hook + settings merge). Install from python.org (includes the py launcher).' }
$pyArgs = if ($py.Name -like 'py*') { @('-3') } else { @() }

foreach ($d in 'agents', 'instructions', 'hooks', 'skills') {
    if ($PSCmdlet.ShouldProcess("$dest\$d", 'copy')) {
        New-Item -ItemType Directory -Force (Join-Path $dest $d) | Out-Null
        Copy-Item (Join-Path $src "$d\*") (Join-Path $dest $d) -Recurse -Force
    }
}
foreach ($f in 'mcp-config.json', 'copilot-aliases.ps1') {
    if ($PSCmdlet.ShouldProcess("$dest\$f", 'copy')) { Copy-Item (Join-Path $src $f) (Join-Path $dest $f) -Force }
}
if ($PSCmdlet.ShouldProcess("$dest\settings.json", 'merge')) {
    # Windows sandbox backend cannot enforce per-path deny rules, so drop deniedPaths here.
    & $py.Source @pyArgs (Join-Path $here 'lib\merge_json.py') (Join-Path $dest 'settings.json') (Join-Path $src 'settings.fragment.jsonc') --drop sandbox.userPolicy.deniedPaths
    & $py.Source @pyArgs (Join-Path $dest 'hooks\guard.py') --self-test | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'guard hook self-test failed' }
}
if ($Managed -and $PSCmdlet.ShouldProcess("$env:ProgramFiles\GitHubCopilot\managed-settings.json", 'install managed policy')) {
    $m = Get-Content (Join-Path $here 'managed\managed-settings.json') -Raw | ConvertFrom-Json
    $m.PSObject.Properties.Remove('_comment')
    New-Item -ItemType Directory -Force "$env:ProgramFiles\GitHubCopilot" | Out-Null
    $m | ConvertTo-Json -Depth 10 | Set-Content "$env:ProgramFiles\GitHubCopilot\managed-settings.json" -Encoding utf8
}
Write-Information "Done. Add to your profile:  . `"$dest\copilot-aliases.ps1`"   then run: cop" -InformationAction Continue
