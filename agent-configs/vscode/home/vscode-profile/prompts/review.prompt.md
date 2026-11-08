---
description: Cheap independent review of uncommitted changes (or a named target)
agent: Reviewer
argument-hint: '[focus or path]'
---

Review the current changes for correctness, regressions, missing tests and security issues. Focus: ${input:target:target or focus}
Return "Verdict: PASS | PASS WITH WARNINGS | FAIL | ESCALATE" and findings as "[SEVERITY] path:line — problem → impact → fix" (max 10, no style nits).

First gather context with the terminal (read-only): `git status --short && git --no-pager diff --stat HEAD && git --no-pager diff HEAD`
