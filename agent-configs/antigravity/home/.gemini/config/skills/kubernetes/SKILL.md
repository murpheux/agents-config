---
name: kubernetes
description: "Kubernetes manifests, Helm, EKS/AKS/GKE — secure pod specs, probes, resources, RBAC, NetworkPolicy, rollout and debugging workflow"
---

# Kubernetes

## Workload baseline (flag deviations)
- `resources.requests` + `limits` (memory limit = request for predictable QoS); HPA on CPU/custom metrics where load varies.
- `readinessProbe`, `livenessProbe` (conservative), `startupProbe` for slow starts.
- `securityContext`: `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `seccompProfile: RuntimeDefault`. No `privileged`, `hostPath`, `hostNetwork`.
- Images pinned by digest; `imagePullPolicy: IfNotPresent`.
- `PodDisruptionBudget` + `topologySpreadConstraints` across zones for HA; ≥ 2 replicas.
- Default-deny `NetworkPolicy` per namespace, then explicit allows.
- RBAC: namespace-scoped Roles; no `cluster-admin` for workloads; dedicated ServiceAccount with `automountServiceAccountToken: false` unless needed.
- Secrets from External Secrets / CSI Secrets Store (AWS SM, Key Vault) — not plain `Secret` manifests in git. Cloud access via IRSA / EKS Pod Identity / AKS Workload Identity / GKE Workload Identity.
- Pod Security Admission `restricted` on app namespaces.

## Debug order
```bash
kubectl get events -n <ns> --sort-by=.lastTimestamp | tail -30
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns> --previous --tail=200
kubectl top pod -n <ns>
```
| Symptom | Usual cause |
|---|---|
| `CrashLoopBackOff` | app error / bad config / failing liveness probe |
| `ImagePullBackOff` | tag, registry auth, arch mismatch |
| `Pending` | requests too high, taints, PVC unbound, affinity |
| `OOMKilled` | memory limit too low / leak |
| `CreateContainerConfigError` | missing ConfigMap/Secret key |

## Changes
`kubectl diff -f` / `helm diff upgrade` first; apply/upgrade requires approval; `kubectl delete namespace` is blocked by the guardrails.
