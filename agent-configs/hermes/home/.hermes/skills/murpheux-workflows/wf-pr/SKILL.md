---
name: wf-pr
description: "Draft a pull request title and description from the current branch"
---

# wf-pr

Workflow skill (invoke explicitly, e.g. `/wf-pr`). Treat the user's words after the skill name as the target.

Draft a PR for the current branch against `main` (or the base branch named here). Extra context: the user's target
Output a Conventional-Commit style title and a body with: Summary, Changes, Testing, Risk & rollback, Security notes. Then show the exact `gh pr create --title … --body-file -` command, but do not run it unless asked.

Start by running this read-only command and use its output as context: `git --no-pager log --oneline origin/main..HEAD 2>/dev/null || git --no-pager log --oneline -15; git --no-pager diff --stat origin/main...HEAD 2>/dev/null`

Follow the `role-developer` skill (load it with `/role-developer` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-developer` first, then summarise its result.
