---
description: Incident triage for a failing service/host (Swarm, K8s, cloud) — read-only first
argument-hint: <symptom / service>
---

Load the `incident-response` skill. Triage this incident: $ARGUMENTS
Follow observe → hypothesise → mitigate. Do not change anything without presenting the exact command, blast radius and rollback first.

Delegate this to the `sre` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
