# /pr.md — Draft a pull request title and description from the current branch

Draft a PR for the current branch against `main` (or the base branch named here). Extra context: the target Murpheux gave with the command
Output a Conventional-Commit style title and a body with: Summary, Changes, Testing, Risk & rollback, Security notes. Then show the exact `gh pr create --title … --body-file -` command, but do not run it unless asked.

## Steps

1. Run this read-only command with `execute_command` and use its output: `git --no-pager log --oneline origin/main..HEAD 2>/dev/null || git --no-pager log --oneline -15; git --no-pager diff --stat origin/main...HEAD 2>/dev/null`
2. Delegate to `subagent_developer` from **Act mode** with a self-contained brief (approvals and the guard hook apply); on the legacy build do the work in Act mode yourself.
