---
description: Review Terraform/OpenTofu, Ansible, Docker/Compose or Kubernetes for security, reliability and cost
agent: Security
argument-hint: '[path, default whole repo]'
---

Review the infrastructure-as-code. Target (default: the whole repository): ${input:target:target or focus}
Run terraform fmt -check / validate / tflint, trivy config, checkov, ansible-lint and hadolint as applicable. Check least-privilege IAM, encryption at rest/in transit, public exposure, state backend security (encryption + locking), pinned versions, tagging and obvious cost waste. Return the findings table.

First gather context with the terminal (read-only): `git ls-files | grep -E '\.(tf|hcl|ya?ml)$|Dockerfile|compose' | head -n 150`
