---
description: Draft a pull request title and description from the current branch
---

Draft a PR for the current branch against `main` (or the base branch named here). Extra context: $ARGUMENTS

Output a Conventional-Commit style title and a body with: Summary, Changes (bullets), Testing, Risk & rollback, Security notes. Then show the exact `gh pr create --title … --body-file -` command, but do not run it unless I say so.

Commits:
!`git log --oneline origin/main..HEAD 2>/dev/null || git log --oneline -15`

Diff summary:
!`git diff --stat origin/main...HEAD 2>/dev/null || git diff --stat HEAD~5`
