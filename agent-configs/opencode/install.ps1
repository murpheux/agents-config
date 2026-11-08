#Requires -Version 7.0
<#
.SYNOPSIS
  Install the OpenCode v2 configuration on Windows into %USERPROFILE%\.config\opencode (or $env:XDG_CONFIG_HOME\opencode).
  Everything it replaces is backed up to %USERPROFILE%\.agent-config-backups\opencode-<timestamp>\.
.PARAMETER Prune
  Also move agents/commands/skills that are not part of this config into the backup.
.EXAMPLE
  pwsh -File install.ps1 -WhatIf
.NOTES
  Copy this folder to a local drive first: unsigned scripts on \\wsl.localhost paths are blocked by RemoteSigned.
#>
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Prune)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$src    = Join-Path $PSScriptRoot '.config\opencode'
$cfg    = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:USERPROFILE '.config' }
$dest   = Join-Path $cfg 'opencode'
$backup = Join-Path $env:USERPROFILE ".agent-config-backups\opencode-$(Get-Date -Format yyyyMMdd-HHmmss)"
if (-not (Test-Path (Join-Path $src 'opencode.jsonc'))) { throw "source config not found at $src" }

# Never copied: service registration (contains the service password), OS junk, files OpenCode manages itself.
$skip = '^(service\.json|package\.json|package-lock\.json|bun\.lock|cli\.json)$|(^|[\\/])\.DS_Store$|^(node_modules|\.git)[\\/]'

function Backup-Item([string]$Path) {
    if (-not (Test-Path $Path)) { return }
    $b = Join-Path $backup ($Path.Substring($dest.Length).TrimStart('\', '/'))
    New-Item -ItemType Directory -Force (Split-Path $b) | Out-Null
    Copy-Item $Path $b -Recurse -Force
}

Get-ChildItem $src -Recurse -File -Force | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length).TrimStart('\', '/')
    if ($rel -match $skip) { return }
    $target = Join-Path $dest $rel
    if ($PSCmdlet.ShouldProcess($target, 'install')) {
        Backup-Item $target
        New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
        Copy-Item $_.FullName $target -Force
    }
}
$cli = Join-Path $src 'cli.json'
if ((Test-Path $cli) -and -not (Test-Path (Join-Path $dest 'cli.json')) -and $PSCmdlet.ShouldProcess("$dest\cli.json", 'install')) {
    Copy-Item $cli (Join-Path $dest 'cli.json')
}

# Stale agents/commands/skills from an older config would still be loaded by OpenCode.
foreach ($d in 'agents', 'commands', 'skills') {
    $dd = Join-Path $dest $d
    if (-not (Test-Path $dd)) { continue }
    foreach ($entry in Get-ChildItem $dd -Force) {
        if (Test-Path (Join-Path (Join-Path $src $d) $entry.Name)) { continue }
        if ($Prune -and $PSCmdlet.ShouldProcess($entry.FullName, 'prune (moved to backup)')) {
            Backup-Item $entry.FullName
            Remove-Item $entry.FullName -Recurse -Force
        }
        elseif (-not $Prune) { Write-Warning "stale $d\$($entry.Name) is not part of this config (use -Prune)" }
    }
}

if (-not $WhatIfPreference) {
    try { Get-Content (Join-Path $dest 'opencode.jsonc') -Raw | ConvertFrom-Json | Out-Null; Write-Information 'opencode.jsonc parses' -InformationAction Continue }
    catch { Write-Warning "opencode.jsonc did not parse with ConvertFrom-Json (JSONC comments are fine for OpenCode): $_" }
}
Write-Information @"
Installed to $dest (backup: $backup)
Next: set AGENTGATEWAY_API_KEY / GITHUB_PAT / CONTEXT7_API_KEY for the service (opencode service set env ...),
      opencode service set env NODE_EXTRA_CA_CERTS <ca.pem>; opencode service unset env NODE_TLS_REJECT_UNAUTHORIZED;
      opencode service restart; then /connect OpenRouter and check: opencode mcp list
"@ -InformationAction Continue
