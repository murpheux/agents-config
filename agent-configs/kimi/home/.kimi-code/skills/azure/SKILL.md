---
name: azure
description: "Azure architecture, Entra ID/RBAC, landing zones, Key Vault, networking, AKS and Azure CLI/PowerShell automation"
---

# Azure

## Access
`az login` (or `Connect-AzAccount`) interactively by Murpheux; agents only run read commands (`az … list`, `az account show`). Never print tokens (`az account get-access-token`) or Key Vault secret values.

## Identity & governance
- Management groups → subscriptions per env/workload; Azure Policy (initiatives: Azure Security Benchmark, CIS) with `deny` for public IPs/storage public access where appropriate.
- Entra ID: PIM for privileged roles, Conditional Access + MFA, no standing Owner.
- RBAC at the narrowest scope (resource group/resource); built-in roles first; managed identities for workloads; federated credentials for GitHub Actions (no client secrets).

## Data & network
- Key Vault (RBAC mode, purge protection, soft delete) for secrets/keys/certs; CMK for sensitive storage/SQL.
- Storage: `allowBlobPublicAccess=false`, `minimumTlsVersion=TLS1_2`, private endpoints, shared-key access disabled where possible.
- Hub-spoke or Virtual WAN; NSGs + Azure Firewall; Private Endpoints + Private DNS zones; Bastion instead of public RDP/SSH.

## AKS
Workload Identity, Azure CNI Overlay, private cluster or authorised IP ranges, Defender for Containers, Key Vault CSI driver, availability zones, system/user node pools split.

## Reliability & cost
Zone-redundant SKUs, Azure Backup/Site Recovery with defined RPO/RTO; cost: Reservations/Savings Plan, autoscale, B-series/Spot for dev, Advisor recommendations, budgets + alerts, log retention in Log Analytics.

Use the Microsoft Learn MCP server (when configured) for current service limits, CLI/PowerShell syntax and Bicep/ARM details.
