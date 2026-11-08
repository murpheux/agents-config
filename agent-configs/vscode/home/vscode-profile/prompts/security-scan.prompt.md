---
description: Security review of the repo or a path — secrets, dependencies, IaC, containers, code (OWASP)
agent: Security
argument-hint: '[path, default whole repo]'
---

Perform a security review. Target (default: the whole repository): ${input:target:target or focus}
Run the scanners that apply to the stack (ggshield/gitleaks, trivy fs/config, semgrep, checkov, govulncheck, npm audit, pip-audit, dotnet list package --vulnerable), then review the highest-risk code paths manually (authn/authz, input handling, IAM, network exposure, secrets handling). Return the findings table ranked by severity then confidence.

First gather context with the terminal (read-only): `git ls-files | head -n 200`
