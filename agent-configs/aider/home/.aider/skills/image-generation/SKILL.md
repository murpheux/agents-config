---
name: image-generation
description: "Create images — programmatic SVG/PNG (icons, badges, charts, diagrams), image processing (resize, convert, optimise), and AI image generation through the agentgateway Images API with cost controls"
---

# Image generation

Pick the cheapest method that produces the result. Deterministic > generative.

| Need | Method |
|---|---|
| Icons, logos, badges, simple illustrations, banners with text | Hand-written **SVG** (then convert if a raster is required) |
| Metrics / cost / capacity charts | **matplotlib** or **plotly** (Python) — data in, PNG/SVG out |
| Architecture / flow diagrams | `architecture-diagrams` or `drawio-diagrams` skill |
| Resize, crop, convert, composite, watermark | **Pillow** or **ImageMagick** (`magick`) |
| Photographic / artistic / hero images, illustrations | **AI generation** via agentgateway (below) |

## Programmatic
```bash
# SVG → PNG
rsvg-convert -w 1200 -o out.png in.svg            # or: uv run --with cairosvg python -c "import cairosvg; cairosvg.svg2png(url='in.svg', write_to='out.png', output_width=1200)"
# Convert / resize / optimise
magick in.png -resize 1600x -strip -quality 85 out.webp
npx -y svgo in.svg -o in.min.svg
```
```python
# Chart: uv run --with matplotlib python chart.py
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
fig, ax = plt.subplots(figsize=(8, 4), dpi=150)
ax.plot(days, cost_cad, marker="o"); ax.set_title("Monthly AWS cost (C$)"); ax.set_ylabel("C$")
ax.grid(alpha=.3); fig.tight_layout(); fig.savefig("docs/img/aws-cost.png")
```
SVG rules: `viewBox` set, no external fonts/URLs, `<title>` for accessibility, text as `<text>` (not paths) unless it must be pixel-exact.

## AI image generation (agentgateway, OpenAI-compatible Images API)
Prerequisite: the gateway exposes an image model (check `GET https://scarlet:4000/v1/models`; e.g. an OpenAI `gpt-image-*`, Google Imagen, or FLUX route configured in the gateway). Use its exact model name.

```bash
mkdir -p docs/img
curl -sS https://scarlet:4000/v1/images/generations \
  -H "Authorization: Bearer $AGENTGATEWAY_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"<image-model>","prompt":"<prompt>","size":"1024x1024","n":1}' \
  | jq -r '.data[0].b64_json' | base64 -d > docs/img/<name>.png
```
- The key is expanded by the shell from the environment — never echo it or paste its value into commands or files.
- This call costs money per image and asks for approval: generate **one** image at standard/low quality first, show it, then iterate; ask before batches (`n>1`) or high quality/large sizes.
- If a response has `url` instead of `b64_json`, download it with `curl -sS -o`.

## Prompt recipe
`<subject> · <setting/context> · <style (e.g. isometric vector, flat illustration, photo, 35mm)> · <composition & camera> · <lighting> · <palette> · <aspect ratio> · <what to avoid>`
- Keep text out of generated images (models garble it) — overlay text afterwards with SVG or Pillow.
- No real people's likeness, logos/trademarks, or copyrighted characters; nothing harmful or deceptive.
- For brand consistency reuse the same style/palette block across prompts.

## Checking results
File-read tools can show PNG/JPEG/WebP to multimodal models, but images cost many tokens — downscale first (`magick in.png -resize 768x preview.png`) and only inspect when a visual check is needed.
