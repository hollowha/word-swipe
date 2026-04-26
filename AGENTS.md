# Codex Project Instructions

## Image Generation Workflow

This project may use AI-generated raster assets for app visuals, learning illustrations, UI mockups, promotional screenshots, or lightweight concept exploration.

When a user asks Codex to generate or edit images:

- Use the `imagegen` skill and the built-in `image_gen` tool first.
- Do not use SVG, CSS, or placeholder drawings when the request is clearly for a bitmap image, illustration, mockup, texture, or app asset.
- If the image is only for brainstorming, it can remain as a preview.
- If the image will be used by WordSwipe, copy the final image into the workspace before finishing.
- Prefer project-bound generated assets under `assets/generated/` with descriptive names such as `smart-deck-hero.png` or `streak-badge-v1.png`.
- Do not overwrite existing assets unless the user explicitly asks for replacement.
- If adding an image that Flutter must load at runtime, also update `pubspec.yaml` so the asset is bundled.
- For transparent images, use the built-in image tool with a removable chroma-key background first; only use API/CLI fallback for true native transparency if the user confirms and `OPENAI_API_KEY` is available.

For OpenAI API-backed image features inside app code or scripts:

- Use the Image API for one-shot generation or editing from a single request.
- Use the Responses API with the `image_generation` tool for conversational, multi-turn, or iterative image workflows.
- Keep API keys out of source control. Read them from environment variables or a secure backend.
- Never call OpenAI APIs directly from the public Flutter web client with a secret key.
