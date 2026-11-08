---
description: Explain code, a file, a command or an error cheaply (read-only)
argument-hint: <code, file, command or error>
model: haiku
---

Explain clearly and concisely for a senior engineer (no basics): $ARGUMENTS
Cover what it does, how data/control flows, non-obvious edge cases and any risks. Cite file paths and lines.

Delegate this to the `Explore` subagent with the Agent tool, passing a self-contained brief (GOAL, CONTEXT incl. the output above, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result for Murpheux.
