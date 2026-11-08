---
description: Secret-scan staged changes, then propose and create a signed conventional commit
agent: Developer
argument-hint: '[extra guidance]'
model: GPT-6 Luna (copilot)
---

Prepare a commit for the STAGED changes only. Extra guidance: ${input:target:target or focus}
1. If the secret scan reports any finding, STOP and report it (location + type, never the value). Do not commit.
2. If nothing is staged, say so and stop.
3. Write a Conventional Commit message (`type(scope): summary` ≤ 72 chars, blank line, short body explaining why).
4. Run `git commit -S -m "<subject>" -m "<body>"` (requires approval). Never push.

First gather context with the terminal (read-only): `ggshield secret scan pre-commit 2>&1 | tail -n 20; git --no-pager diff --cached --stat && git --no-pager diff --cached`
