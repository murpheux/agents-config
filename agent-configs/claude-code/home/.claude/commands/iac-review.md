---
description: Review Terraform/OpenTofu, Ansible, Docker/Compose or Kubernetes for security, reliability and cost
argument-hint: '[path, default whole repo]'
allowed-tools: Bash(git status *), Bash(git --no-pager *), Bash(git ls-files *), Bash(ggshield secret scan *), Bash(tail *), Bash(head *), Bash(grep *)
---

Review the infrastructure-as-code. Target (default: the whole repository): $ARGUMENTS
Run terraform fmt -check / validate / tflint, trivy config, checkov, ansible-lint and hadolint as applicable. Check least-privilege IAM, encryption at rest/in transit, public exposure, state backend security (encryption + locking), pinned versions, tagging and obvious cost waste. Return the findings table.

Context (collected before this prompt):
!`git ls-files | grep -E '\.(tf|hcl|ya?ml)$|Dockerfile|compose' | head -n 150`

Delegate this to the `security` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
