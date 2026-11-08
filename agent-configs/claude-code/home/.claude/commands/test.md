---
description: Run the project's build/lint/tests and fix failures
argument-hint: '[scope]'
---

Run the relevant build, lint and test commands for this repository (Makefile/Taskfile targets first), then fix the failures. Scope: $ARGUMENTS
Stop after two unsuccessful fix attempts on the same failure and report the evidence.

Delegate this to the `developer` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
