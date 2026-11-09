---
description: Create an architecture diagram (draw.io, Mermaid, C4, Python diagrams, D2) and render it
argument-hint: "<what to diagram>"
---
Create an architecture diagram for: $ARGUMENTS

1. Use the `architecture-diagrams` skill to choose the format (`drawio-diagrams` if I asked for draw.io/diagrams.net or vendor icons with manual layout; Mermaid if it lives in Markdown).
2. Derive components and flows from the repository (IaC, compose/stack files, k8s manifests, code) or from my description — don't invent components; list assumptions.
3. Save the source under `docs/diagrams/` (kebab-case), validate it, render SVG (and PNG if useful), and return the paths plus a short legend.
