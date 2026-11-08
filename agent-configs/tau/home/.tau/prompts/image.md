---
description: Generate an image — SVG/chart/processed image, or an AI-generated image via agentgateway (one draft first)
argument-hint: "<what to produce>"
---
Use the `image-generation` skill's conventions (`/skill:image-generation` first if it hasn't auto-loaded). Produce this image: $ARGUMENTS

Use a deterministic method (SVG, chart, Pillow/ImageMagick) when it can satisfy the request; use AI generation only for photographic/illustrative content. For AI generation: write the prompt, generate a single standard-quality draft into `docs/img/`, and report the path, prompt and model used. Never print or embed the API key.
