---
name: wf-iac-review
description: "Review Terraform/OpenTofu, Ansible, Docker/Compose or Kubernetes for security, reliability and cost"
---

# wf-iac-review

Workflow skill (invoke explicitly, e.g. `/wf-iac-review`). Treat the user's words after the skill name as the target.

Review the infrastructure-as-code. Target (default: the whole repository): the user's target
Run terraform fmt -check / validate / tflint, trivy config, checkov, ansible-lint and hadolint as applicable. Check least-privilege IAM, encryption at rest/in transit, public exposure, state backend security (encryption + locking), pinned versions, tagging and obvious cost waste. Return the findings table.

Start by running this read-only command and use its output as context: `git ls-files | grep -E '\.(tf|hcl|ya?ml)$|Dockerfile|compose' | head -n 150`

Follow the `role-security` skill (load it with `/role-security` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-security` first, then summarise its result.
