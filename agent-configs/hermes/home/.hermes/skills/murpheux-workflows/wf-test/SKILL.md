---
name: wf-test
description: "Run the project's build/lint/tests and fix failures"
---

# wf-test

Workflow skill (invoke explicitly, e.g. `/wf-test`). Treat the user's words after the skill name as the target.

Run the relevant build, lint and test commands for this repository (Makefile/Taskfile targets first), then fix the failures. Scope: the user's target
Stop after two unsuccessful fix attempts on the same failure and report the evidence.

Follow the `role-developer` skill (load it with `/role-developer` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-developer` first, then summarise its result.
