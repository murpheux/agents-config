# /security-scan.md — Security review of the repo or a path — secrets, dependencies, IaC, containers, code (OWASP)

Perform a security review. Target (default: the whole repository): the target Murpheux gave with the command
Run the scanners that apply to the stack (ggshield/gitleaks, trivy fs/config, semgrep, checkov, govulncheck, npm audit, pip-audit, dotnet list package --vulnerable), then review the highest-risk code paths manually (authn/authz, input handling, IAM, network exposure, secrets handling). Return the findings table ranked by severity then confidence.

## Steps

1. Run this read-only command with `execute_command` and use its output: `git ls-files | head -n 200`
2. Use `subagent_security` for the analysis if available (next build/CLI); otherwise review in Plan mode. Never print secret values.
