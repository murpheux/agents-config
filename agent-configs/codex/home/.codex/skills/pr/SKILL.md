---
name: pr
description: "Draft a pull request title and description from the current branch"
---

# pr

Workflow skill (invoke explicitly, e.g. `$pr`). Treat the user's words after the skill name as the target.

Draft a PR for the current branch against `main` (or the base branch named here). Extra context: the user's target
Output a Conventional-Commit style title and a body with: Summary, Changes, Testing, Risk & rollback, Security notes. Then show the exact `gh pr create --title … --body-file -` command, but do not run it unless asked.

Start by running this read-only command and use its output as context: `git --no-pager log --oneline origin/main..HEAD 2>/dev/null || git --no-pager log --oneline -15; git --no-pager diff --stat origin/main...HEAD 2>/dev/null`

Delegate the work to the `developer` subagent with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
