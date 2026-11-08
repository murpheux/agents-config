---
name: incident
description: "Incident triage for a failing service/host (Swarm, K8s, cloud) — read-only first"
---

# incident

Workflow skill (invoke explicitly, e.g. `$incident`). Treat the user's words after the skill name as the target.

Load the `incident-response` skill. Triage this incident: the user's target
Follow observe → hypothesise → mitigate. Do not change anything without presenting the exact command, blast radius and rollback first.

Delegate the work to the `sre` subagent with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
