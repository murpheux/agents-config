---
name: powershell
description: "Writing or reviewing PowerShell 7 scripts/modules for Windows or Azure automation — structure, error handling, security, PSScriptAnalyzer and Pester"
---

# PowerShell 7 (pwsh)

Use only for Windows / Azure targets or when asked (bash/zsh for macOS/Linux).

## Script skeleton
```powershell
#Requires -Version 7.4
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ResourceGroup,
    [ValidateSet('dev','prod')][string]$Environment = 'dev'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

try {
    if ($PSCmdlet.ShouldProcess($ResourceGroup, 'Deploy')) {
        # work
    }
}
catch {
    Write-Error -ErrorRecord $_
    exit 1
}
```

## Rules
- Approved verbs (`Get-Verb`), `Verb-Noun` PascalCase names, advanced functions with typed/validated params, comment-based help for public functions.
- Output objects, not formatted text; `Write-Verbose`/`Write-Information` for logs; never `Write-Host` in reusable code.
- `-WhatIf`/`-Confirm` support (`SupportsShouldProcess`) on anything that changes state.
- Secrets: `Microsoft.PowerShell.SecretManagement` (+ 1Password/Key Vault vault), `[SecureString]`/`PSCredential` params; never plain-text passwords, never `ConvertTo-SecureString -AsPlainText` with literals.
- No `Invoke-Expression` / `iex` on downloaded content (blocked by the guardrails). Use `-UseBasicParsing`-free `Invoke-RestMethod` with explicit TLS.
- Cross-platform paths: `Join-Path`, `[IO.Path]::Combine`; avoid aliases (`ls`, `%`, `?`) in scripts.
- Modules: `Az.*` over AzureRM; pin module versions in `#Requires -Modules @{ModuleName='Az.Accounts'; ModuleVersion='x.y'}`.

## Validate
```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Warning,Error
Invoke-Pester -Path ./tests -Output Detailed
```
From WSL/macOS: `pwsh -NoProfile -Command Invoke-ScriptAnalyzer -Path . -Recurse` (read-only, safe to auto-approve).
