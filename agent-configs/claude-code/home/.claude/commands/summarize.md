---
description: Brief overview of the current project (cheap)
model: haiku
allowed-tools: Bash(git status *), Bash(git --no-pager *), Bash(git ls-files *), Bash(ggshield secret scan *), Bash(tail *), Bash(head *), Bash(grep *)
---

Give a brief overview of this project: what it is, main files and folders, how to build/test/run it, and what it seems to be for. ≤ 25 lines.

Context (collected before this prompt):
!`git ls-files 2>/dev/null | head -n 150`

Delegate this to the `Explore` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
