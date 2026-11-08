---
name: image
description: "Generate an image — SVG/chart/processed image, or one AI-generated draft via the gateway"
---

# image

Workflow skill (invoke explicitly, e.g. "use the image skill"). Treat the user's words after the skill name as the target.

Load the `image-generation` skill and produce this image: the user's target
Use a deterministic method (SVG, chart, Pillow/ImageMagick) when it can satisfy the request; use AI generation only for photographic/illustrative content. For AI generation: write the prompt, generate a single standard-quality draft into docs/img/ (requires approval), and report the path, prompt and model. Never print or embed the API key.

Delegate the work to the `developer` custom agent (agent tool) with a self-contained brief (GOAL, CONTEXT, CONSTRAINTS, ACCEPTANCE, RETURN), then summarise its result.
