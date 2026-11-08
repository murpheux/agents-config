---
name: plan
description: "Produce an implementation plan only (no changes)"
---

# plan

Workflow skill (invoke explicitly, e.g. `$plan`). Treat the user's words after the skill name as the target.

Create an implementation plan for: the user's target
Use the planner output format (Objective, Context, Assumptions, Plan, Decisions, Risks, Specialist, Verification, Escalate if). Do not edit files.

Start by running this read-only command and use its output as context: `git --no-pager log --oneline -10 2>/dev/null; git status --short 2>/dev/null | head -n 30`

Delegate the work to the `planner` subagent with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
