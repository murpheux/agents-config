# /image.md — Generate an image — SVG/chart/processed image, or one AI-generated draft via the gateway

Load the `image-generation` skill and produce this image: the target Murpheux gave with the command
Use a deterministic method (SVG, chart, Pillow/ImageMagick) when it can satisfy the request; use AI generation only for photographic/illustrative content. For AI generation: write the prompt, generate a single standard-quality draft into docs/img/ (requires approval), and report the path, prompt and model. Never print or embed the API key.

## Steps

1. Delegate to `subagent_developer` from **Act mode** with a self-contained brief (approvals and the guard hook apply); on the legacy build do the work in Act mode yourself.
