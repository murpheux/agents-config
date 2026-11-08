---
description: Draft a pull request title and description from the current branch
agent: Developer
argument-hint: '[base branch, extra context]'
model: GPT-6 Luna (copilot)
---

Draft a PR for the current branch against `main` (or the base branch named here). Extra context: ${input:target:target or focus}
Output a Conventional-Commit style title and a body with: Summary, Changes, Testing, Risk & rollback, Security notes. Then show the exact `gh pr create --title … --body-file -` command, but do not run it unless asked.

First gather context with the terminal (read-only): `git --no-pager log --oneline origin/main..HEAD 2>/dev/null || git --no-pager log --oneline -15; git --no-pager diff --stat origin/main...HEAD 2>/dev/null`
