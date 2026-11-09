---
description: Review Terraform/OpenTofu, Ansible, Docker/Compose or Kubernetes manifests for security, reliability and cost
---

Review the infrastructure-as-code. Target (default: the whole repository): $ARGUMENTS

Run `terraform fmt -check`/`terraform validate`/`tflint`, `trivy config`, `checkov`, `ansible-lint`, `hadolint` as applicable. Then check least-privilege IAM, encryption at rest/in transit, public exposure, state backend security (encryption + locking), pinned provider/module/image versions, tagging, and obvious cost waste. Return the findings table.

IaC files:
!`git ls-files | grep -E '\.(tf|tfvars\.example|hcl|ya?ml|yml)$|Dockerfile|compose' | head -n 150`
