---
description: Generate an image — SVG/chart/processed image, or one AI-generated draft via the gateway
agent: Developer
argument-hint: <image description>
---

Load the `image-generation` skill and produce this image: ${input:target:target or focus}
Use a deterministic method (SVG, chart, Pillow/ImageMagick) when it can satisfy the request; use AI generation only for photographic/illustrative content. For AI generation: write the prompt, generate a single standard-quality draft into docs/img/ (requires approval), and report the path, prompt and model. Never print or embed the API key.
