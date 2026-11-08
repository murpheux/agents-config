---
name: threat-model
description: "STRIDE threat model for a system, feature or diagram"
---

# threat-model

Workflow skill (invoke explicitly, e.g. `$threat-model`). Treat the user's words after the skill name as the target.

Load the `threat-modeling` skill and produce a threat model for: the user's target
Identify assets, trust boundaries and data flows first (Mermaid DFD), then threats per STRIDE, then mitigations prioritised by risk.

Delegate the work to the `security` subagent with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
