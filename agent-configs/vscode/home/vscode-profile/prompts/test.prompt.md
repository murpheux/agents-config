---
description: Run the project's build/lint/tests and fix failures
agent: Developer
argument-hint: '[scope]'
---

Run the relevant build, lint and test commands for this repository (Makefile/Taskfile targets first), then fix the failures. Scope: ${input:target:target or focus}
Stop after two unsuccessful fix attempts on the same failure and report the evidence.
