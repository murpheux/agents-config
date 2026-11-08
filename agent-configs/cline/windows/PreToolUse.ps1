# Cline PreToolUse hook for Windows (legacy build runs PreToolUse.ps1 via `powershell -File`;
# next build runs .ps1 with powershell). Delegates to the shared guard (Python 3 via the `py` launcher).
$ErrorActionPreference = 'Stop'
$guard = if ($env:CLINE_GUARD) { $env:CLINE_GUARD } else { Join-Path $env:USERPROFILE '.cline\guard\guard.py' }
$payload = [Console]::In.ReadToEnd()
$py = Get-Command py -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command python -ErrorAction SilentlyContinue }
if (-not $py -or -not (Test-Path $guard)) {
    '{"cancel":false,"contextModification":"WARNING: Cline guard hook is not active (Python or guard.py missing). Apply the global guardrails manually."}'
    exit 0
}
$pyArgs = @()
if ($py.Name -like 'py*') { $pyArgs += '-3' }
$out = $payload | & $py.Source @pyArgs $guard --format cline
if ([string]::IsNullOrWhiteSpace($out)) { '{"cancel":false}' } else { $out }
