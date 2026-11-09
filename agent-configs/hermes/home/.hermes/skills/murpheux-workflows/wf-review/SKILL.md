---
name: wf-review
description: "Cheap independent review of uncommitted changes (or a named target)"
---

# wf-review

Workflow skill (invoke explicitly, e.g. `/wf-review`). Treat the user's words after the skill name as the target.

Review the current changes for correctness, regressions, missing tests and security issues. Focus: the user's target
Return "Verdict: PASS | PASS WITH WARNINGS | FAIL | ESCALATE" and findings as "[SEVERITY] path:line — problem → impact → fix" (max 10, no style nits).

Start by running this read-only command and use its output as context: `git status --short && git --no-pager diff --stat HEAD && git --no-pager diff HEAD`

Follow the `role-reviewer` skill (load it with `/role-reviewer` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-reviewer` first, then summarise its result.
