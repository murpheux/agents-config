# /iac-review.md — Review Terraform/OpenTofu, Ansible, Docker/Compose or Kubernetes for security, reliability and cost

Review the infrastructure-as-code. Target (default: the whole repository): the target Murpheux gave with the command
Run terraform fmt -check / validate / tflint, trivy config, checkov, ansible-lint and hadolint as applicable. Check least-privilege IAM, encryption at rest/in transit, public exposure, state backend security (encryption + locking), pinned versions, tagging and obvious cost waste. Return the findings table.

## Steps

1. Run this read-only command with `execute_command` and use its output: `git ls-files | grep -E '\.(tf|hcl|ya?ml)$|Dockerfile|compose' | head -n 150`
2. Use `subagent_security` for the analysis if available (next build/CLI); otherwise review in Plan mode. Never print secret values.
