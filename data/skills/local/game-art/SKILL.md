---
name: game-art
description: Generate and clean up 2D game art with an image model (sprites and animation sheets, characters and their variants, tilesets and terrain, maps and props, UI kits and icons), then key, slice, align, and check it into engine-ready files. Use when a game or prototype needs real art instead of code-drawn placeholders, or when reviewing generated game assets.
---

# Game art

Game developers ask for what they need, not for how to make it engine-ready; that part is yours. An asset that needs manual cleanup is a miss even when the user never named the requirement. Wiring the files into the game is the game-dev skill's job.

## Generating images

Every raw image comes from the image model through `scripts/imagegen.py`. Never draw final art with code (canvas, SVG, HTML/CSS, three.js, PIL shapes) unless the user asks for placeholders; scripts only make layout guides, process generated images, and compose previews.

```bash
scripts/imagegen.py generate --prompt-file hero/idle.prompt.txt --quality high --out hero/idle-raw.png
scripts/imagegen.py edit --image hero/master.png --image hero/anchor-2x3.png --prompt-file hero/attack.prompt.txt --out hero/attack-raw.png
```

- The endpoint comes from `IMAGEGEN_BASE_URL` plus `IMAGEGEN_API_KEY` or `IMAGEGEN_API_KEY_FILE`, falling back to `OPENAI_BASE_URL` and `OPENAI_API_KEY`; `IMAGEGEN_MODEL` replaces the default `gpt-image-2`. If none are set, ask the user rather than guessing. `--dry-run` prints the request without sending it.
- Sizes are `1024x1024`, `1536x1024`, and `1024x1536`; crop or pad other canvases deterministically afterwards. Use `--quality high` for sheets you mean to keep.
- The model sees only the images passed with `--image`, in order. Call them Image 1, Image 2 in the prompt and say what each one locks. A path or filename written inside the prompt is not a reference. Look at every reference yourself first, so the prompt can name what to preserve.
- Recurring subjects are edited from their accepted base image, never regenerated from text.
- Each output gets its prompt saved beside it as `<name>.prompt.txt`; keep it with accepted assets. Existing files are never overwritten without `--force`, so give retries new names.
- A call spends the user's quota and can take a minute or more. Plan the asset list, then generate; don't spray variants.
- Open every result with your file-reading tool before judging or processing it.
- A moderation refusal ends that line of prompting: don't rephrase around it; tell the user and offer another direction.
- Image models garble exact text, digits, and structure. HUD numbers, labels, item names, and charts are rendered by the game with real fonts. A wordmark logo is read back letter by letter, and any wrong, merged, or extra letter means a retry.

The scripts are executable; run them by their full path inside this skill's directory, without a `python3` prefix. `imagegen.py` needs only Python's standard library. The others need Pillow and numpy and start through `nix shell`, which fetches them on first use. One-off image work (assembling an atlas, pasting a frame into a cell, normalizing a canvas) runs in the same environment: `nix shell --impure --expr '(import <nixpkgs> { }).python3.withPackages (ps: [ ps.numpy ps.pillow ])' --command python3 <script>`.

## Engine-ready defaults

Apply these whenever the request doesn't say otherwise:

| When asked for | Deliver, unprompted |
|---|---|
| a character, creature, or prop sprite | an isolated subject on solid `#FF00FF` for keying, a clean silhouette, no baked ground, scene, or cast shadow |
| anything that moves | a looping frame sequence ([animation.md](references/animation.md)), generated as a multi-row grid and processed into frames, a transparent sheet, and a GIF ([sprites.md](references/sprites.md)) |
| a sprite sheet | uniform implicit cells without divider lines, the subject at the same position and scale in every cell |
| ground, terrain, water, walls | seamless tiling proven on a real repeat, no landmark motifs, non-directional light where tiles may rotate ([tilesets.md](references/tilesets.md)) |
| UI panels, frames, buttons | 9-slice-safe edges, no text, state variants with identical geometry ([ui-icons.md](references/ui-icons.md)) |
| the same character or object again | edits of the accepted base image ([characters.md](references/characters.md)) |
| icons | one style contract across the set, uniform padding, legible at 32px |
| a playable map | a separate base, props, collision, and zones, never one baked image ([maps.md](references/maps.md)) |

Name files exactly, frames zero-padded in play order. When counts or names are yours to choose, pick sensible ones and record them in a manifest.

## Working discipline

1. Keep a private spec checklist: every stated property plus the defaults above that apply. Verify against it; never paste it into prompts.
2. Prompt in the generator's language. Describe the subject in a few vivid sentences of natural prose with style and medium words, then state the hard constraints plainly: background, grid shape, containment, no text. Put exact geometry into a layout guide image or into nameable visual configurations (clock positions, colored markers) rather than abstract measurements. For an edit, state what stays fixed, then the one change.
3. Verify by describing blind, then diffing: write down what the image shows before rereading the spec. Every stated property and every applicable default is pass or fail; a hedge in your own description is a fail.
4. Escalate the representation, then the strategy. Retry once with a more concrete visual re-expression. If the generator repeats the failure, treat it as a prior: build from parts (generate pieces, then rotate, mirror, and assemble them deterministically, minding asymmetries), or keep the best result and flag it. About two discards per point is the limit.
5. Deliver and report: make a final pass across all files for cohesion and the checklist, and state every unfixed defect and every default you knowingly broke.

## Keying and processing

Anything that will be cut out is generated on 100% solid flat `#FF00FF`, with no gradient, floor, or shadow, and with generous margin; keep magenta and pink out of the subject. `generate2dsprite.py process` keys, splits, aligns, and measures sheets; `extract_prop_pack.py` does the same for prop sheets; `chroma_key.py` gives soft painted edges a clean matte first. Read what the processors report (edge touches, clamped pastes, scale drift), look at the output, and regenerate rather than loosen QC.

## References

| Read | When |
|---|---|
| [sprites.md](references/sprites.md) | any sprite, sheet, animation, FX, or prop sprite: planning, generating, processing, QC, Godot export |
| [sprite-modes.md](references/sprite-modes.md) | the asset type, action, bundle, or sheet shape is ambiguous |
| [sprite-prompts.md](references/sprite-prompts.md) | writing a sprite prompt |
| [animation.md](references/animation.md) | anything that moves: motion laws and the flip test |
| [characters.md](references/characters.md) | turnarounds, variants, and any recurring character |
| [ui-icons.md](references/ui-icons.md) | buttons, panels, bars, logos, icon sets |
| [tilesets.md](references/tilesets.md) | seamless textures, transition sets, terrain tile atlases |
| [maps.md](references/maps.md) | any map, level, stage, room, or background |
| [map-strategies.md](references/map-strategies.md) | choosing the map mode and pipeline axes |
| [layered-maps.md](references/layered-maps.md) | a top-down base plus props: prompts, placement, collision, render order |
| [props.md](references/props.md) | map props and scene objects: classification, prop packs, platform strips, extraction |
| [side-scroll.md](references/side-scroll.md) | side-scroller, platformer, runner, and brawler stages |
