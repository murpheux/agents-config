---
name: review
description: "Cheap independent review of uncommitted changes (or a named target)"
---

# review

Workflow skill (invoke explicitly, e.g. `$review`). Treat the user's words after the skill name as the target.

Review the current changes for correctness, regressions, missing tests and security issues. Focus: the user's target
Return "Verdict: PASS | PASS WITH WARNINGS | FAIL | ESCALATE" and findings as "[SEVERITY] path:line — problem → impact → fix" (max 10, no style nits).

Start by running this read-only command and use its output as context: `git status --short && git --no-pager diff --stat HEAD && git --no-pager diff HEAD`

Delegate the work to the `reviewer` subagent with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
