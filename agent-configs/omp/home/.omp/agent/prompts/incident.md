---
description: Incident triage for a failing service/host (Swarm, K8s, cloud) — read-only first
argument-hint: "<what's failing>"
---
Delegate to the `sre` subagent with the task tool, applying the `incident-response` skill. Triage this incident: $ARGUMENTS

Follow the observe → hypothesise → mitigate loop. Do not change anything without presenting the exact command, blast radius and rollback first.
