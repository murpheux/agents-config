---
name: wf-incident
description: "Incident triage for a failing service/host (Swarm, K8s, cloud) — read-only first"
---

# wf-incident

Workflow skill (invoke explicitly, e.g. `/wf-incident`). Treat the user's words after the skill name as the target.

Load the `incident-response` skill. Triage this incident: the user's target
Follow observe → hypothesise → mitigate. Do not change anything without presenting the exact command, blast radius and rollback first.

Follow the `role-sre` skill (load it with `/role-sre` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-sre` first, then summarise its result.
