---
description: STRIDE threat model for a system, feature or diagram
argument-hint: <system or feature>
---

Load the `threat-modeling` skill and produce a threat model for: $ARGUMENTS
Identify assets, trust boundaries and data flows first (Mermaid DFD), then threats per STRIDE, then mitigations prioritised by risk.

Delegate this to the `security` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
