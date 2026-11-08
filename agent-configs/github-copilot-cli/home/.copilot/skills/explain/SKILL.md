---
name: explain
description: "Explain code, a file, a command or an error cheaply (read-only)"
---

# explain

Workflow skill (invoke explicitly, e.g. "use the explain skill"). Treat the user's words after the skill name as the target.

Explain clearly and concisely for a senior engineer (no basics): the user's target
Cover what it does, how data/control flows, non-obvious edge cases and any risks. Cite file paths and lines.

Delegate the work to the `explorer` custom agent (agent tool) with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
