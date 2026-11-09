---
description: Security review of the repo or a path — secrets, dependencies, IaC, containers, code (OWASP)
argument-hint: "[target]"
---
Delegate this to the `security` subagent with the task tool (self-contained brief), then summarise its result. Perform a security review. Target (default: the whole repository): $ARGUMENTS (if empty: the whole repository)

First get a repository overview yourself: `git ls-files | head -n 200`.

Run the scanners that apply to the stack you find (ggshield/gitleaks, trivy fs/config, semgrep, checkov, govulncheck, npm audit, pip-audit, dotnet list package --vulnerable), then review the highest-risk code paths manually (authn/authz, input handling, IAM, network exposure, secrets handling). Return the findings table, ranked by severity then confidence.
