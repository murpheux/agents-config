---
name: test
description: "Run the project's build/lint/tests and fix failures"
---

# test

Workflow skill (invoke explicitly, e.g. "use the test skill"). Treat the user's words after the skill name as the target.

Run the relevant build, lint and test commands for this repository (Makefile/Taskfile targets first), then fix the failures. Scope: the user's target
Stop after two unsuccessful fix attempts on the same failure and report the evidence.

Delegate the work to the `developer` custom agent (agent tool) with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
