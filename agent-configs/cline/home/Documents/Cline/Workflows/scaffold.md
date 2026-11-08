# /scaffold.md — Scaffold a new repo/project following Murpheux's conventions

Scaffold a new project: the target Murpheux gave with the command
Follow the global conventions: README.md, LICENSE (MIT unless told otherwise), .gitignore for the stack, Makefile with lint/test/build/deploy, src/ or cmd/, tests/, scripts/, docs/, .github/workflows/ci.yml (lint + test, actions pinned to SHAs, minimal permissions), .env.example if configuration is needed. Load the matching language skill first. Validate that `make lint test` passes before reporting.

## Steps

1. Do the work in **Act mode** (approvals and the guard hook apply).
