# /review.md — Cheap independent review of uncommitted changes (or a named target)

Review the current changes for correctness, regressions, missing tests and security issues. Focus: the target Murpheux gave with the command
Return "Verdict: PASS | PASS WITH WARNINGS | FAIL | ESCALATE" and findings as "[SEVERITY] path:line — problem → impact → fix" (max 10, no style nits).

## Steps

1. Run this read-only command with `execute_command` and use its output: `git status --short && git --no-pager diff --stat HEAD && git --no-pager diff HEAD`
2. Pass the diff to `subagent_reviewer` if available (next build/CLI); otherwise review in Plan mode.
