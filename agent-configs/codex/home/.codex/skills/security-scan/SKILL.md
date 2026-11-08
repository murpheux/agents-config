---
name: security-scan
description: "Security review of the repo or a path — secrets, dependencies, IaC, containers, code (OWASP)"
---

# security-scan

Workflow skill (invoke explicitly, e.g. `$security-scan`). Treat the user's words after the skill name as the target.

Perform a security review. Target (default: the whole repository): the user's target
Run the scanners that apply to the stack (ggshield/gitleaks, trivy fs/config, semgrep, checkov, govulncheck, npm audit, pip-audit, dotnet list package --vulnerable), then review the highest-risk code paths manually (authn/authz, input handling, IAM, network exposure, secrets handling). Return the findings table ranked by severity then confidence.

Start by running this read-only command and use its output as context: `git ls-files | head -n 200`

Delegate the work to the `security` subagent with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
