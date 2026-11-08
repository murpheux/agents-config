<#
.SYNOPSIS
  Install the Cline configuration on Windows (native VS Code / Cline CLI). Backs up what it replaces.
.EXAMPLE
  pwsh -File install.ps1 -WhatIf
  pwsh -File install.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$here   = $PSScriptRoot
$docs   = [Environment]::GetFolderPath('MyDocuments')          # handles OneDrive redirection like Cline does
$home_  = $env:USERPROFILE
$backup = Join-Path $home_ ".agent-config-backups\cline-$(Get-Date -Format yyyyMMdd-HHmmss)"

function Install-Tree([string]$Source, [string]$Dest) {
    Get-ChildItem $Source -Recurse -File | ForEach-Object {
        $rel    = $_.FullName.Substring($Source.Length).TrimStart('\', '/')
        $target = Join-Path $Dest $rel
        if (Test-Path $target) {
            $b = Join-Path $backup ($target.Substring($home_.Length).TrimStart('\'))
            if ($PSCmdlet.ShouldProcess($target, 'backup')) { New-Item -ItemType Directory -Force (Split-Path $b) | Out-Null; Copy-Item $target $b -Force }
        }
        if ($PSCmdlet.ShouldProcess($target, 'install')) {
            New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
            (Get-Content $_.FullName -Raw) -replace '__HOME__', ($home_ -replace '\\', '/') | Set-Content -Path $target -NoNewline -Encoding utf8
        }
    }
}

Install-Tree (Join-Path $here 'home\Documents\Cline') (Join-Path $docs 'Cline')
Install-Tree (Join-Path $here 'home\.cline') (Join-Path $home_ '.cline')
# Windows hook: only PreToolUse.ps1 runs on Windows; remove the POSIX launcher copy.
$hooks = Join-Path $docs 'Cline\Hooks'
if ($PSCmdlet.ShouldProcess($hooks, 'install PreToolUse.ps1')) {
    Copy-Item (Join-Path $here 'windows\PreToolUse.ps1') (Join-Path $hooks 'PreToolUse.ps1') -Force
    Remove-Item (Join-Path $hooks 'PreToolUse') -ErrorAction SilentlyContinue
}
Write-Information "Installed. Launch VS Code with credentials: op run --env-file $home_\.cline\cline.op.env -- code ." -InformationAction Continue
