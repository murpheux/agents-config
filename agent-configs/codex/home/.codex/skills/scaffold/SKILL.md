---
name: scaffold
description: "Scaffold a new repo/project following Murpheux's conventions"
---

# scaffold

Workflow skill (invoke explicitly, e.g. `$scaffold`). Treat the user's words after the skill name as the target.

Scaffold a new project: the user's target
Follow the global conventions: README.md, LICENSE (MIT unless told otherwise), .gitignore for the stack, Makefile with lint/test/build/deploy, src/ or cmd/, tests/, scripts/, docs/, .github/workflows/ci.yml (lint + test, actions pinned to SHAs, minimal permissions), .env.example if configuration is needed. Load the matching language skill first. Validate that `make lint test` passes before reporting.

Delegate the work to the `developer` subagent with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
