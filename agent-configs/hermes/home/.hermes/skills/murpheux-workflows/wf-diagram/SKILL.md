---
name: wf-diagram
description: "Create an architecture diagram (draw.io, Mermaid, C4, Python diagrams, D2) and render it"
---

# wf-diagram

Workflow skill (invoke explicitly, e.g. `/wf-diagram`). Treat the user's words after the skill name as the target.

Create an architecture diagram for: the user's target
1. Load the `architecture-diagrams` skill and choose the format (use the `drawio-diagrams` skill for draw.io/diagrams.net or vendor icons with manual layout; Mermaid if it lives in Markdown).
2. Derive components and flows from the repository (IaC, compose/stack files, k8s manifests, code) or the description — don't invent components; list assumptions.
3. Save the source under docs/diagrams/ (kebab-case), validate it, render SVG (and PNG if useful), and return the paths plus a short legend.

Follow the `role-developer` skill (load it with `/role-developer` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-developer` first, then summarise its result.
