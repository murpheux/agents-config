---
description: Scaffold a new repo/project following Murpheux's conventions
argument-hint: <project description>
---

Scaffold a new project: $ARGUMENTS
Follow the global conventions: README.md, LICENSE (MIT unless told otherwise), .gitignore for the stack, Makefile with lint/test/build/deploy, src/ or cmd/, tests/, scripts/, docs/, .github/workflows/ci.yml (lint + test, actions pinned to SHAs, minimal permissions), .env.example if configuration is needed. Load the matching language skill first. Validate that `make lint test` passes before reporting.

Delegate this to the `developer` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
