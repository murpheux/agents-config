---
description: Create an architecture diagram (draw.io, Mermaid, C4, Python diagrams, D2) and render it
agent: Developer
argument-hint: <what to diagram, optional format>
---

Create an architecture diagram for: ${input:target:target or focus}
1. Load the `architecture-diagrams` skill and choose the format (use the `drawio-diagrams` skill for draw.io/diagrams.net or vendor icons with manual layout; Mermaid if it lives in Markdown).
2. Derive components and flows from the repository (IaC, compose/stack files, k8s manifests, code) or the description — don't invent components; list assumptions.
3. Save the source under docs/diagrams/ (kebab-case), validate it, render SVG (and PNG if useful), and return the paths plus a short legend.
