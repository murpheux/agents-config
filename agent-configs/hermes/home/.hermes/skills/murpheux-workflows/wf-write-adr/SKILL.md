---
name: wf-write-adr
description: "Write an Architecture Decision Record for a decision"
---

# wf-write-adr

Workflow skill (invoke explicitly, e.g. `/wf-write-adr`). Treat the user's words after the skill name as the target.

Load the `adr` skill. Write an ADR for this decision: the user's target
Inspect existing ADRs first (docs/adr/, docs/decisions/) to continue their numbering and format. Save the ADR (requires approval) and return its path plus a 3-line summary.

Follow the `role-architect` skill (load it with `/role-architect` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-architect` first, then summarise its result.
