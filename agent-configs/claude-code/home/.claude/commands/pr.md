---
description: Draft a pull request title and description from the current branch
argument-hint: '[base branch, extra context]'
model: haiku
allowed-tools: Bash(git status *), Bash(git --no-pager *), Bash(git ls-files *), Bash(ggshield secret scan *), Bash(tail *), Bash(head *), Bash(grep *)
---

Draft a PR for the current branch against `main` (or the base branch named here). Extra context: $ARGUMENTS
Output a Conventional-Commit style title and a body with: Summary, Changes, Testing, Risk & rollback, Security notes. Then show the exact `gh pr create --title … --body-file -` command, but do not run it unless asked.

Context (collected before this prompt):
!`git --no-pager log --oneline origin/main..HEAD 2>/dev/null || git --no-pager log --oneline -15; git --no-pager diff --stat origin/main...HEAD 2>/dev/null`

Delegate this to the `developer` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
