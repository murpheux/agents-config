---
name: wf-image
description: "Generate an image — SVG/chart/processed image, or one AI-generated draft via the gateway"
---

# wf-image

Workflow skill (invoke explicitly, e.g. `/wf-image`). Treat the user's words after the skill name as the target.

Load the `image-generation` skill and produce this image: the user's target
Use a deterministic method (SVG, chart, Pillow/ImageMagick) when it can satisfy the request; use AI generation only for photographic/illustrative content. For AI generation: write the prompt, generate a single standard-quality draft into docs/img/ (requires approval), and report the path, prompt and model. Never print or embed the API key.

Follow the `role-developer` skill (load it with `/role-developer` or `skill_view`). For long or parallel work, hand it to `delegate_task` with a self-contained goal and context that tells the child to load `role-developer` first, then summarise its result.
