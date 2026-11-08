# /incident.md — Incident triage for a failing service/host (Swarm, K8s, cloud) — read-only first

Load the `incident-response` skill. Triage this incident: the target Murpheux gave with the command
Follow observe → hypothesise → mitigate. Do not change anything without presenting the exact command, blast radius and rollback first.

## Steps

1. Diagnose in **Act mode** with read-only commands first; present any mutating command with blast radius and rollback before running it.
