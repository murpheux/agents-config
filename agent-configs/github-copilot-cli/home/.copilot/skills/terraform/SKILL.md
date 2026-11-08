---
name: terraform
description: "Writing, reviewing or planning Terraform/OpenTofu — module layout, state backends, provider pinning, security defaults, safe plan/apply workflow"
---

# Terraform / OpenTofu

## Layout
```
terraform/
  versions.tf      # required_version + required_providers (pinned ~> minor)
  providers.tf     # default_tags, assume_role, region
  backend.tf       # remote state
  variables.tf     # typed, described, validated; sensitive = true where needed
  main.tf / <domain>.tf
  outputs.tf       # sensitive = true for secrets
  envs/<env>.tfvars  # non-secret only
```
`snake_case` names. Modules: small, single purpose, no provider blocks inside, inputs typed with `validation` blocks.

## State
- Remote backend with encryption + locking (S3 with `use_lockfile = true` + SSE-KMS, or azurerm with blob lease). Bucket: versioning on, public access blocked, TLS-only bucket policy.
- State contains secrets → never read/print `*.tfstate`; agent guardrails block reading it. Use `terraform state list` / `terraform output -json <name>` only for non-sensitive outputs.
- Note backend + workspace (`terraform workspace show`) before proposing changes.

## Security defaults (flag deviations)
- IAM: least privilege, no `"*"` actions/resources without justification; use `aws_iam_policy_document` data sources.
- Encryption at rest (KMS CMK for sensitive data) and in transit; `enable_key_rotation = true`.
- No `0.0.0.0/0` ingress; S3 `block_public_*` = true; RDS `publicly_accessible = false`; IMDSv2 required.
- Secrets via `data "aws_secretsmanager_secret_version"` / Key Vault / SSM — never literals or committed tfvars.
- `lifecycle { prevent_destroy = true }` on stateful resources (DBs, buckets, KMS keys).
- Tags: `owner`, `env`, `app`, `cost-center` via provider `default_tags`.

## Workflow (agents)
1. `terraform fmt -recursive` · `terraform validate` · `tflint` · `trivy config .` / `checkov -d .` — read-only (safe to auto-approve).
2. `op plugin run -- terraform plan -out=tfplan` — requires approval (touches cloud APIs).
3. Summarise the plan: adds/changes/**destroys**, replacements (`-/+`), IAM & network changes called out explicitly.
4. `apply` is always Murpheux's call; `destroy` and `-auto-approve` are blocked by the guardrails.

Use the Terraform registry MCP server (when configured) for provider argument details instead of guessing.
