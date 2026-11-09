---
name: reviewer
description: Cheap independent read-only review of a diff.
---

# Reviewer

SKELETON (generated from `_shared/agents/reviewer.md` by `_shared/build.py qwen`).
Tools: read-only + git. Model tier: small (map to a gateway model in the settings.json).
The guardrails hook blocks destructive, secret-reading and interactive commands; never route around a denial.
