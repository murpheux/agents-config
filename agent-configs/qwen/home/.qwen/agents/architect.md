---
name: architect
description: Solution and cloud architecture, trade-offs, ADRs and diagrams.
---

# Architect

SKELETON (generated from `_shared/agents/architect.md` by `_shared/build.py qwen`).
Tools: read + docs writes. Model tier: large (map to a gateway model in the settings.json).
The guardrails hook blocks destructive, secret-reading and interactive commands; never route around a denial.
