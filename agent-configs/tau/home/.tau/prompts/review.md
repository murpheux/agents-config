---
description: Cheap independent review of uncommitted changes (or a target you name)
argument-hint: "[focus]"
---
Use the `role-reviewer` skill's process — read-only. Review these changes for correctness, regressions, missing tests and security issues. Focus: $ARGUMENTS

First gather yourself: `git status --short && git diff --stat && git diff HEAD`.
