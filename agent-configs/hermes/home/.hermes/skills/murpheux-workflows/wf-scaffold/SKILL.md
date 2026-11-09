---
name: wf-scaffold
description: "Scaffold a new repo/project following Murpheux's conventions"
---

# wf-scaffold

Workflow skill (invoke explicitly, e.g. `/wf-scaffold`). Treat the user's words after the skill name as the target.

Scaffold a new project: the user's target
Follow the global conventions: README.md, LICENSE (MIT unless told otherwise), .gitignore for the stack, Makefile with lint/test/build/deploy, src/ or cmd/, tests/, scripts/, docs/, .github/workflows/ci.yml (lint + test, actions pinned to SHAs, minimal permissions), .env.example if configuration is needed. Load the matching language skill first. Validate that `make lint test` passes before reporting.

Follow the `role-developer` skill (load it with `/role-developer` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-developer` first, then summarise its result.
