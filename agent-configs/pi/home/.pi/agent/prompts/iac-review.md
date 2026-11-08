---
description: Review Terraform/OpenTofu, Ansible, Docker/Compose or Kubernetes manifests for security, reliability and cost
argument-hint: "[target]"
---
Use the `role-security` skill's judgement for this. Review the infrastructure-as-code. Target (default: the whole repository): ${@:-the whole repository}

First list the relevant files yourself: `git ls-files | grep -E '\.(tf|tfvars\.example|hcl|ya?ml|yml)$|Dockerfile|compose'`.

Then run `terraform fmt -check`/`terraform validate`/`tflint`, `trivy config`, `checkov`, `ansible-lint`, `hadolint` as applicable. Check least-privilege IAM, encryption at rest/in transit, public exposure, state backend security (encryption + locking), pinned provider/module/image versions, tagging, and obvious cost waste. Return the findings table, ranked by severity then confidence.
