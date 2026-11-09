---
name: wf-security-scan
description: "Security review of the repo or a path — secrets, dependencies, IaC, containers, code (OWASP)"
---

# wf-security-scan

Workflow skill (invoke explicitly, e.g. `/wf-security-scan`). Treat the user's words after the skill name as the target.

Perform a security review. Target (default: the whole repository): the user's target
Run the scanners that apply to the stack (ggshield/gitleaks, trivy fs/config, semgrep, checkov, govulncheck, npm audit, pip-audit, dotnet list package --vulnerable), then review the highest-risk code paths manually (authn/authz, input handling, IAM, network exposure, secrets handling). Return the findings table ranked by severity then confidence.

Start by running this read-only command and use its output as context: `git ls-files | head -n 200`

Follow the `role-security` skill (load it with `/role-security` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-security` first, then summarise its result.
