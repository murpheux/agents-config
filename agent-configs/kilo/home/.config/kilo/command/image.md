---
description: Generate an image — SVG/chart/processed image, or an AI-generated image via agentgateway (one draft first)
---

Load the `image-generation` skill and produce this image: $ARGUMENTS

Use a deterministic method (SVG, chart, Pillow/ImageMagick) when it can satisfy the request; use AI generation only for photographic/illustrative content. For AI generation: write the prompt, generate a single standard-quality draft into `docs/img/` (the request will ask for approval), and report the path, prompt and model used. Never print or embed the API key.
