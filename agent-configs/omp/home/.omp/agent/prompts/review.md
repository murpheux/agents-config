---
description: Cheap independent review of uncommitted changes (or a target you name)
argument-hint: "[focus]"
---
Delegate this to the `reviewer` subagent with the task tool (self-contained brief), then summarise its result — read-only. Review these changes for correctness, regressions, missing tests and security issues. Focus: $ARGUMENTS

First gather yourself: `git status --short && git diff --stat && git diff HEAD`.
