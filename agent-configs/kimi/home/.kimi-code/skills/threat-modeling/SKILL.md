---
name: threat-modeling
description: "STRIDE threat modeling for systems, features, APIs and cloud architectures — DFD, trust boundaries, threats, risk rating, mitigations"
---

# Threat modeling (STRIDE)

## Steps
1. **Scope** — system, assets (data, credentials, availability), actors, assumptions, out-of-scope.
2. **Model** — Mermaid data-flow diagram with processes, data stores, external entities and **trust boundaries** (internet ↔ edge, edge ↔ app, app ↔ data, CI/CD ↔ cloud, home LAN ↔ WAN).
3. **Enumerate** — for each element/flow crossing a boundary:

| STRIDE | Question | Typical controls |
|---|---|---|
| **S**poofing | Can someone pretend to be a user/service? | MFA, OIDC, mTLS, workload identity |
| **T**ampering | Can data/code be modified in transit/at rest/in the pipeline? | TLS, signing, integrity checks, immutable artifacts, branch protection |
| **R**epudiation | Can actions be denied later? | Audit logs (CloudTrail), tamper-evident storage |
| **I**nfo disclosure | Can data leak? | Encryption, least privilege, secret managers, output encoding |
| **D**enial of service | Can it be exhausted? | Rate limits, quotas, autoscaling, WAF, timeouts |
| **E**levation of privilege | Can someone gain more rights? | RBAC, input validation, sandboxing, `PassRole` limits |

4. **Rate** — Likelihood (1–3) × Impact (1–3) → Critical ≥ 7, High 5–6, Medium 3–4, Low ≤ 2.
5. **Mitigate** — control, owner, status (existing / planned / accepted risk).

## Output
```markdown
## Scope & assumptions
## Data-flow diagram (Mermaid)
## Threats
| ID | Element / flow | STRIDE | Threat | L | I | Risk | Mitigation | Status |
## Top 5 actions
## Residual risk
```
Also consider supply chain (dependencies, CI runners, GitHub Actions), secrets lifecycle, and abuse cases (LLM prompt injection if the system uses AI agents).
