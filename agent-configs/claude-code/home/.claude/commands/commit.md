---
description: Secret-scan staged changes, then propose and create a signed conventional commit
argument-hint: '[extra guidance]'
model: haiku
allowed-tools: Bash(git status *), Bash(git --no-pager *), Bash(git ls-files *), Bash(ggshield secret scan *), Bash(tail *), Bash(head *), Bash(grep *)
---

Prepare a commit for the STAGED changes only. Extra guidance: $ARGUMENTS
1. If the secret scan reports any finding, STOP and report it (location + type, never the value). Do not commit.
2. If nothing is staged, say so and stop.
3. Write a Conventional Commit message (`type(scope): summary` ≤ 72 chars, blank line, short body explaining why).
4. Run `git commit -S -m "<subject>" -m "<body>"` (requires approval). Never push.

Context (collected before this prompt):
!`ggshield secret scan pre-commit 2>&1 | tail -n 20; git --no-pager diff --cached --stat && git --no-pager diff --cached`

Delegate this to the `developer` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
