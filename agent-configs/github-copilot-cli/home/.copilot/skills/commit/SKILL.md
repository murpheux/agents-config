---
name: commit
description: "Secret-scan staged changes, then propose and create a signed conventional commit"
---

# commit

Workflow skill (invoke explicitly, e.g. "use the commit skill"). Treat the user's words after the skill name as the target.

Prepare a commit for the STAGED changes only. Extra guidance: the user's target
1. If the secret scan reports any finding, STOP and report it (location + type, never the value). Do not commit.
2. If nothing is staged, say so and stop.
3. Write a Conventional Commit message (`type(scope): summary` ≤ 72 chars, blank line, short body explaining why).
4. Run `git commit -S -m "<subject>" -m "<body>"` (requires approval). Never push.

Start by running this read-only command and use its output as context: `ggshield secret scan pre-commit 2>&1 | tail -n 20; git --no-pager diff --cached --stat && git --no-pager diff --cached`

Delegate the work to the `developer` custom agent (agent tool) with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
