---
name: wf-commit
description: "Secret-scan staged changes, then propose and create a signed conventional commit"
---

# wf-commit

Workflow skill (invoke explicitly, e.g. `/wf-commit`). Treat the user's words after the skill name as the target.

Prepare a commit for the STAGED changes only. Extra guidance: the user's target
1. If the secret scan reports any finding, STOP and report it (location + type, never the value). Do not commit.
2. If nothing is staged, say so and stop.
3. Write a Conventional Commit message (`type(scope): summary` ≤ 72 chars, blank line, short body explaining why).
4. Run `git commit -S -m "<subject>" -m "<body>"` (requires approval). Never push.

Start by running this read-only command and use its output as context: `ggshield secret scan pre-commit 2>&1 | tail -n 20; git --no-pager diff --cached --stat && git --no-pager diff --cached`

Follow the `role-developer` skill (load it with `/role-developer` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-developer` first, then summarise its result.
