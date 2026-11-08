---
name: write-adr
description: "Write an Architecture Decision Record for a decision"
---

# write-adr

Workflow skill (invoke explicitly, e.g. "use the write-adr skill"). Treat the user's words after the skill name as the target.

Load the `adr` skill. Write an ADR for this decision: the user's target
Inspect existing ADRs first (docs/adr/, docs/decisions/) to continue their numbering and format. Save the ADR (requires approval) and return its path plus a 3-line summary.

Delegate the work to the `architect` custom agent (agent tool) with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
