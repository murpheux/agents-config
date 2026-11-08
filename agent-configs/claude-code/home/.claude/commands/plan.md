---
description: Produce an implementation plan only (no changes)
argument-hint: <what to plan>
allowed-tools: Bash(git status *), Bash(git --no-pager *), Bash(git ls-files *), Bash(ggshield secret scan *), Bash(tail *), Bash(head *), Bash(grep *)
---

Create an implementation plan for: $ARGUMENTS
Use the planner output format (Objective, Context, Assumptions, Plan, Decisions, Risks, Specialist, Verification, Escalate if). Do not edit files.

Context (collected before this prompt):
!`git --no-pager log --oneline -10 2>/dev/null; git status --short 2>/dev/null | head -n 30`

Delegate this to the `planner` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
