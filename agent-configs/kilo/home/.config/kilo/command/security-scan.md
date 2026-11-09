---
description: Security review of the repo or a path — secrets, dependencies, IaC, containers, code (OWASP)
---

Perform a security review. Target (default: the whole repository): $ARGUMENTS

Run the scanners that apply to the stack you find (ggshield/gitleaks, trivy fs/config, semgrep, checkov, govulncheck, npm audit, pip-audit, dotnet list package --vulnerable), then review the highest-risk code paths manually (authn/authz, input handling, IAM, network exposure, secrets handling).

Return the findings table from your instructions, ranked by severity then confidence.

Repository overview:
!`git ls-files | head -n 200`
