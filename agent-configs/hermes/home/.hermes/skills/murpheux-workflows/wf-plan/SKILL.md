---
name: wf-plan
description: "Produce an implementation plan only (no changes)"
---

# wf-plan

Workflow skill (invoke explicitly, e.g. `/wf-plan`). Treat the user's words after the skill name as the target.

Create an implementation plan for: the user's target
Use the planner output format (Objective, Context, Assumptions, Plan, Decisions, Risks, Specialist, Verification, Escalate if). Do not edit files.

Start by running this read-only command and use its output as context: `git --no-pager log --oneline -10 2>/dev/null; git status --short 2>/dev/null | head -n 30`

Follow the `role-planner` skill (load it with `/role-planner` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-planner` first, then summarise its result.
