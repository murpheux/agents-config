# /plan.md — Produce an implementation plan only (no changes)

Create an implementation plan for: the target Murpheux gave with the command
Use the planner output format (Objective, Context, Assumptions, Plan, Decisions, Risks, Specialist, Verification, Escalate if). Do not edit files.

## Steps

1. Run this read-only command with `execute_command` and use its output: `git --no-pager log --oneline -10 2>/dev/null; git status --short 2>/dev/null | head -n 30`
2. Use `subagent_planner` if available (next build/CLI); otherwise plan in **Plan mode**. Do not implement.
