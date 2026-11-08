---
name: aws
description: "AWS architecture, IAM, security baselines, CLI via 1Password, and cost optimisation — use for any AWS design, review or operations task"
---

# AWS

## Access
All CLI calls: `op plugin run -- aws <service> <op> --region <r> --output json`. Check identity first: `op plugin run -- aws sts get-caller-identity`. Never export keys into the shell or print credentials.

## Account & identity baseline
- AWS Organizations + SCPs; IAM Identity Center for humans; no IAM users with access keys; root with MFA and unused.
- CI: GitHub OIDC → role with `token.actions.githubusercontent.com:sub` condition scoped to repo + branch/environment.
- Workloads: instance profiles / IRSA / ECS task roles / Lambda execution roles.
- Policies: specific actions and ARNs; conditions (`aws:SourceArn`, `aws:SourceAccount`, `aws:PrincipalOrgID`, `aws:SecureTransport`); watch `iam:PassRole`, `sts:AssumeRole` trust, resource policies (`Principal: "*"`).
- Guardrails: CloudTrail (org trail, log file validation), GuardDuty, Security Hub (FSBP + CIS), AWS Config, IAM Access Analyzer.

## Data & network
- KMS CMKs with rotation for sensitive data; S3 Block Public Access (account level), bucket policies deny non-TLS; RDS/Aurora encrypted, private, IAM auth where possible; Secrets Manager with rotation.
- VPC: private subnets for compute/data, VPC endpoints (S3/DynamoDB gateway, interface endpoints for SSM/ECR/Secrets Manager) to cut NAT cost; security groups reference SGs, not CIDRs; no SSH — use SSM Session Manager; IMDSv2 required.

## Reliability
Multi-AZ by default; backups via AWS Backup with vault lock for critical data; define RPO/RTO; Route 53 health checks for failover; quotas checked (Service Quotas) before scale events.

## Cost levers
Graviton, right-sizing (Compute Optimizer), Savings Plans for steady load, Spot for stateless/batch, S3 lifecycle + Intelligent-Tiering, gp3 over gp2, NAT Gateway egress reduction via endpoints, CloudWatch log retention, delete idle EIPs/volumes/snapshots, budgets + anomaly detection.

Use the AWS Documentation MCP server (when configured in mcp.json) for service limits and API details.
