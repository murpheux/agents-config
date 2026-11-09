---
name: wf-explain
description: "Explain code, a file, a command or an error cheaply (read-only)"
---

# wf-explain

Workflow skill (invoke explicitly, e.g. `/wf-explain`). Treat the user's words after the skill name as the target.

Explain clearly and concisely for a senior engineer (no basics): the user's target
Cover what it does, how data/control flows, non-obvious edge cases and any risks. Cite file paths and lines.

Answer directly with `read_file` / `search_files` (read-only); no delegation needed.
