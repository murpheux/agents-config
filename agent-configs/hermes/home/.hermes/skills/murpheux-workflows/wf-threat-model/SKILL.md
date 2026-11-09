---
name: wf-threat-model
description: "STRIDE threat model for a system, feature or diagram"
---

# wf-threat-model

Workflow skill (invoke explicitly, e.g. `/wf-threat-model`). Treat the user's words after the skill name as the target.

Load the `threat-modeling` skill and produce a threat model for: the user's target
Identify assets, trust boundaries and data flows first (Mermaid DFD), then threats per STRIDE, then mitigations prioritised by risk.

Follow the `role-security` skill (load it with `/role-security` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-security` first, then summarise its result.
