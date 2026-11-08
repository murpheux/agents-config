# /threat-model.md — STRIDE threat model for a system, feature or diagram

Load the `threat-modeling` skill and produce a threat model for: the target Murpheux gave with the command
Identify assets, trust boundaries and data flows first (Mermaid DFD), then threats per STRIDE, then mitigations prioritised by risk.

## Steps

1. Use `subagent_security` for the analysis if available (next build/CLI); otherwise review in Plan mode. Never print secret values.
