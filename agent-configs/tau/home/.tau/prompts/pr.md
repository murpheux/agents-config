---
description: Draft a pull request title and description from the current branch
argument-hint: "[base branch / extra context]"
---
This is cheap/mechanical work — switch to `deepseek-flash` with `/model` first if cost matters. Draft a PR for the current branch against `main` (or the base branch named here). Extra context: $ARGUMENTS

First gather yourself: `git log --oneline origin/main..HEAD` (or `git log --oneline -15` if there's no upstream) and `git diff --stat origin/main...HEAD` (or `git diff --stat HEAD~5`).

Output a Conventional-Commit style title and a body with: Summary, Changes (bullets), Testing, Risk & rollback, Security notes. Then show the exact `gh pr create --title … --body-file -` command, but do not run it unless I say so.
