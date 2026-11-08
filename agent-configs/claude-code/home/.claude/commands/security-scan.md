---
description: Security review of the repo or a path — secrets, dependencies, IaC, containers, code (OWASP)
argument-hint: '[path, default whole repo]'
allowed-tools: Bash(git status *), Bash(git --no-pager *), Bash(git ls-files *), Bash(ggshield secret scan *), Bash(tail *), Bash(head *), Bash(grep *)
---

Perform a security review. Target (default: the whole repository): $ARGUMENTS
Run the scanners that apply to the stack (ggshield/gitleaks, trivy fs/config, semgrep, checkov, govulncheck, npm audit, pip-audit, dotnet list package --vulnerable), then review the highest-risk code paths manually (authn/authz, input handling, IAM, network exposure, secrets handling). Return the findings table ranked by severity then confidence.

Context (collected before this prompt):
!`git ls-files | head -n 200`

Delegate this to the `security` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
