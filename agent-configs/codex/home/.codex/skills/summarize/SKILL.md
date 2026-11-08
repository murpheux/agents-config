---
name: summarize
description: "Brief overview of the current project (cheap)"
---

# summarize

Workflow skill (invoke explicitly, e.g. `$summarize`). Treat the user's words after the skill name as the target.

Give a brief overview of this project: what it is, main files and folders, how to build/test/run it, and what it seems to be for. ≤ 25 lines.

Start by running this read-only command and use its output as context: `git ls-files 2>/dev/null | head -n 150`

Delegate the work to the `explorer` subagent with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
