# /commit.md — Secret-scan staged changes, then propose and create a signed conventional commit

Prepare a commit for the STAGED changes only. Extra guidance: the target Murpheux gave with the command
1. If the secret scan reports any finding, STOP and report it (location + type, never the value). Do not commit.
2. If nothing is staged, say so and stop.
3. Write a Conventional Commit message (`type(scope): summary` ≤ 72 chars, blank line, short body explaining why).
4. Run `git commit -S -m "<subject>" -m "<body>"` (requires approval). Never push.

## Steps

1. Run this read-only command with `execute_command` and use its output: `ggshield secret scan pre-commit 2>&1 | tail -n 20; git --no-pager diff --cached --stat && git --no-pager diff --cached`
2. Delegate to `subagent_developer` from **Act mode** with a self-contained brief (approvals and the guard hook apply); on the legacy build do the work in Act mode yourself.
