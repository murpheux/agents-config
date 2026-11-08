<#
.SYNOPSIS
  Render every reports/_src/*.html to reports/*.pdf with headless Microsoft Edge.
.EXAMPLE
  pwsh -File render.ps1            # all reports
  pwsh -File render.ps1 codex      # one report (basename without extension)
#>
[CmdletBinding()]
param([string[]]$Name)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$src  = Join-Path $PSScriptRoot '_src'
$out  = $PSScriptRoot
$edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
        Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $edge) { throw 'Microsoft Edge not found' }

# Edge cannot print from \\wsl.localhost reliably: stage in %TEMP%, render, copy back.
$stage = Join-Path $env:TEMP "agent-reports-$PID"
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Copy-Item (Join-Path $src '*') $stage -Recurse -Force
$profileDir = Join-Path $env:TEMP "edge-pdf-profile-$PID"

try {
    $files = Get-ChildItem $stage -Filter *.html | Where-Object { -not $Name -or $Name -contains $_.BaseName }
    foreach ($f in $files) {
        $pdf = Join-Path $stage ($f.BaseName + '.pdf')
        $uri = 'file:///' + ($f.FullName -replace '\\', '/')
        $p = Start-Process -FilePath $edge -PassThru -Wait -ArgumentList @(
            '--headless=new', '--disable-gpu', '--no-first-run', "--user-data-dir=$profileDir",
            '--no-pdf-header-footer', "--print-to-pdf=$pdf", $uri)
        if ($p.ExitCode -ne 0 -or -not (Test-Path $pdf)) { throw "render failed: $($f.Name)" }
        Copy-Item $pdf (Join-Path $out ($f.BaseName + '.pdf')) -Force
        Write-Information "rendered $($f.BaseName).pdf ($([math]::Round((Get-Item $pdf).Length / 1KB)) KB)" -InformationAction Continue
    }
}
finally {
    Remove-Item $stage, $profileDir -Recurse -Force -ErrorAction SilentlyContinue
}
