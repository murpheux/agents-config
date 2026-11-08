---
description: Cheap independent review of uncommitted changes (or a named target)
argument-hint: '[focus or path]'
allowed-tools: Bash(git status *), Bash(git --no-pager *), Bash(git ls-files *), Bash(ggshield secret scan *), Bash(tail *), Bash(head *), Bash(grep *)
---

Review the current changes for correctness, regressions, missing tests and security issues. Focus: $ARGUMENTS
Return "Verdict: PASS | PASS WITH WARNINGS | FAIL | ESCALATE" and findings as "[SEVERITY] path:line — problem → impact → fix" (max 10, no style nits).

Context (collected before this prompt):
!`git status --short && git --no-pager diff --stat HEAD && git --no-pager diff HEAD`

Delegate this to the `reviewer` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
