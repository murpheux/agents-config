---
description: Produce an implementation plan only (no changes)
agent: Planner
argument-hint: <what to plan>
---

Create an implementation plan for: ${input:target:target or focus}
Use the planner output format (Objective, Context, Assumptions, Plan, Decisions, Risks, Specialist, Verification, Escalate if). Do not edit files.

First gather context with the terminal (read-only): `git --no-pager log --oneline -10 2>/dev/null; git status --short 2>/dev/null | head -n 30`
