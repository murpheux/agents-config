---
description: Secret-scan staged changes, then propose and create a signed conventional commit
argument-hint: "[extra guidance]"
---
Prepare a commit for the STAGED changes only. This is cheap/mechanical work — switch to `deepseek-flash` with `/model` first if cost matters. Extra guidance: $ARGUMENTS

1. Run `ggshield secret scan pre-commit` and `git diff --cached --stat && git diff --cached` yourself first.
2. If the secret scan reports any finding, STOP and report it (location + type, never the value). Do not commit.
3. If nothing is staged, say so and stop.
4. Write a Conventional Commit message (`type(scope): summary` ≤ 72 chars, blank line, short body explaining *why*).
5. Run `git commit -S -m "<subject>" -m "<body>"`. Never push.
