---
description: Incident triage for a failing service/host (Swarm, K8s, cloud) — read-only first
agent: SRE
argument-hint: <symptom / service>
---

Load the `incident-response` skill. Triage this incident: ${input:target:target or focus}
Follow observe → hypothesise → mitigate. Do not change anything without presenting the exact command, blast radius and rollback first.
