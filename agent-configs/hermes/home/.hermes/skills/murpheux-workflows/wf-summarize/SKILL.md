---
name: wf-summarize
description: "Brief overview of the current project (cheap)"
---

# wf-summarize

Workflow skill (invoke explicitly, e.g. `/wf-summarize`). Treat the user's words after the skill name as the target.

Give a brief overview of this project: what it is, main files and folders, how to build/test/run it, and what it seems to be for. ≤ 25 lines.

Start by running this read-only command and use its output as context: `git ls-files 2>/dev/null | head -n 150`

Answer directly with `read_file` / `search_files` (read-only); no delegation needed.
