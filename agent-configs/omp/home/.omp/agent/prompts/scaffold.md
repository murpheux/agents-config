---
description: Scaffold a new repo/project following Murpheux's conventions
argument-hint: "<project description>"
---
Scaffold a new project: $ARGUMENTS

Follow AGENTS.md conventions: README.md, LICENSE (MIT unless told otherwise), .gitignore for the stack, Makefile with `lint`, `test`, `build`, `deploy` targets, `src/` or `cmd/`, `tests/`, `scripts/`, `docs/`, `.github/workflows/ci.yml` (lint + test, actions pinned to SHAs, minimal `permissions:`), and a `.env.example` if configuration is needed. Use the matching language skill first (`golang`, `dotnet`, `python`, `nodejs`, `bash`, `powershell`, …). Validate that `make lint test` passes before reporting.
