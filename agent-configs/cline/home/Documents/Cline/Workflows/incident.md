# /incident.md — Incident triage for a failing service/host (Swarm, K8s, cloud) — read-only first

Load the `incident-response` skill. Triage this incident: the target Murpheux gave with the command
Follow observe → hypothesise → mitigate. Do not change anything without presenting the exact command, blast radius and rollback first.

## Steps

1. Delegate to `subagent_sre` from **Act mode**: read-only commands first; any mutating command is presented with blast radius and rollback before it runs. On the legacy build diagnose in Act mode yourself.
