---
name: incident-response
description: "SRE incident triage and postmortem workflow — severity, comms, observe/hypothesise/mitigate loop, blameless postmortem template"
---

# Incident response

## 1. Declare & size (first 5 minutes)
| Sev | Meaning |
|---|---|
| SEV1 | Full outage / data loss / security breach |
| SEV2 | Major feature degraded, no workaround |
| SEV3 | Partial degradation, workaround exists |
| SEV4 | Minor / cosmetic |
Record: start time (America/Edmonton), impact, who is affected, what changed recently (deploys, config, certs, DNS, quotas, provider status pages).

## 2. Observe — cheapest, broadest signal first
1. Dashboards/alerts (Grafana `http://sclet:3000`, Prometheus `http://sclet:9090`, CloudWatch/Azure Monitor).
2. Orchestrator state (`docker service ps --no-trunc`, `kubectl get events`).
3. Logs, capped (`--tail 200 --since 30m`; Kibana `http://scarlet:5601`).
4. Dependencies: DNS (both Pi-holes), TLS expiry (`openssl s_client -connect host:443 -servername host </dev/null | openssl x509 -noout -dates`), upstream APIs, disk (`df -h`), memory.
Use the USE method for resources (Utilisation, Saturation, Errors) and RED for services (Rate, Errors, Duration).

## 3. Hypothesise → test
List 1–3 hypotheses with supporting/contradicting evidence; test the cheapest to falsify. Change one thing at a time.

## 4. Mitigate before fixing
Prefer reversible: roll back the last deploy, scale out, fail over, disable a feature flag, restart a single task. Each proposal = exact command + blast radius + rollback — approval required.

## 5. Resolve & follow up
Confirm recovery with the same signal that showed the failure. Then write the postmortem.

## Postmortem template (blameless)
```markdown
# <date> <title> (SEVx)
## Summary            — 3 lines: what, impact, duration
## Timeline (MT)      — detection → mitigation → resolution
## Root cause         — technical cause + contributing factors
## What went well / poorly
## Action items       — | action | type (prevent/detect/mitigate) | priority |
```
