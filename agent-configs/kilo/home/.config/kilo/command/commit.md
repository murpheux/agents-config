---
description: Secret-scan staged changes, then propose and create a signed conventional commit
---

Prepare a commit for the STAGED changes only. Extra guidance: $ARGUMENTS

1. If the secret scan below reports any finding, STOP and report it (location + type, never the value). Do not commit.
2. If nothing is staged, say so and stop.
3. Write a Conventional Commit message (`type(scope): summary` ≤ 72 chars, blank line, short body explaining *why*).
4. Run `git commit -S -m "<subject>" -m "<body>"` (this will ask for approval). Never push.

Secret scan:
!`ggshield secret scan pre-commit 2>&1 | tail -n 20 || true`

Staged diff:
!`git diff --cached --stat && git diff --cached`
