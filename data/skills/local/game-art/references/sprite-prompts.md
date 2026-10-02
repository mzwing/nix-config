# Sprite prompts

Rules for writing sprite prompts by hand. Don't delegate prompt writing to a script.

## Always

- the background is 100% solid flat magenta `#FF00FF`, with no gradient
- no text, labels, UI, or speech bubbles
- the exact grid count, with no borders or frames between cells
- the same asset identity in every frame
- the same camera distance and standing-equivalent anatomical scale across body frames; natural pose bounding boxes may change, but no pose is zoomed

## Style

Choose the style from the request, the project, the map, or the reference:

- `pixel_art`: the default for classic 2D game actors and animation sheets
- `clean_hd`: clean hand-painted HD 2D game asset style, crisp silhouettes, smooth surfaces, low texture noise, controlled lighting, no chunky pixels
- `pixel_inspired`: clean modern pixel-art-inspired style without 16-bit wording, heavy dithering, or noisy microtexture
- `retro_pixel`: 16-bit or retro JRPG pixel art, only when explicitly requested
- `map_style`, `project-native`: match the reference, the existing game, or the map's chosen style

Don't write `16-bit`, `retro JRPG`, or `chunky pixel-art` unless the user asks for that look. For clean HD map props, say `Do not make pixel art`.

## References

When the user attaches a reference, points to a local image, wants consistency with an earlier image, or asks for an evolution or variant:

- Pass the reference with `--image` and look at it yourself. A path in the prompt is not a visual input.
- In the prompt, say which image is the visual reference ("Image 1 is the visual reference").
- State what stays fixed: silhouette family, palette, face and eyes, costume or markings, accessories, material language, art style.
- State what may change: pose, animation phase, action energy, size progression, evolution traits, FX intensity.
- For animation sheets, keep the same identity in every cell and change only the pose or effect state.
- For evolution lines, keep visible lineage markers while allowing a larger silhouette, added details, or stronger colors per form.
- The magenta background and containment rules still apply.

## Layout guides

Good fits: `3x3` and `4x4` prop packs, tileset-like atlases, fixed atlas rows, and non-directional 16-frame sequences (cast, summon, charge, death, transformation). Possible: `3x3` large idles and showcase loops after earlier runs drifted. Risky: four-direction walk sheets, where guide pressure centers the poses and weakens locomotion.

Pass the guide with `--image` and write:

```text
Use the layout guide image as a layout-only reference. Use it only to understand the rows, columns, equal invisible frame slots, centering, spacing, and safe padding. Do not reproduce the guide: no visible boxes, no safe-area rectangles, no center marks, no labels, no borders, no guide background.
```

The guide only provides geometry; the action plan, style, identity lock, and containment rules stay in your prompt.

## Character anchor sheets

For high-value grounded player and hero actions that still drift in scale or feet placement:

1. Accept one neutral or idle master frame with the right identity, camera distance, standing scale, and padding.
2. Repeat it into every intended cell with `scripts/make_anchor_layout.py`, at one fixed scale and feet line.
3. Pass the master frame as Image 1 (identity, art style, anatomy, camera, materials) and the anchor sheet as Image 2 (slots, scale, body root, feet line, padding).
4. Ask for changed poses only, preserving the anchor sheet's geometry:

```text
Image 1 is the exact character identity and art reference.
Image 2 is a scale-and-root template made from the same accepted character.
Preserve Image 2's exact cell locations, fixed camera distance, standing-equivalent anatomical scale, body-root position, grounded foot-contact line, and padding. Change only the action pose in each slot. Never zoom or resize a pose to fill its cell. Natural crouching may change the visible pose bbox, but torso, head, limb thickness, costume, and weapon scale must remain constant.
```

Not for jumps, falls, knockback, flying or hovering motion, projectiles, impacts, creatures whose attack reshapes their posture, or FX that change scale on purpose; those need center, root, or motion-relative layouts and visual QC. A multi-action bundle reuses the same master image, anchor sheet, raw grid geometry, and generation size for every grounded body action.

## Containment

When consistency matters, say:

- the entire subject fits fully inside each cell
- no body part, effect, weapon, tail, wing tip, orb, spark, or smoke trail crosses a cell edge
- magenta margin on all four sides
- the same silhouette scale in every frame

Without detached FX: "no floating detached effects outside the main silhouette". With them: "detached effects stay tightly grouped near the main subject and still fit inside the cell".

## View

- `topdown`: overworld actors, player and NPC sheets
- `side`: projectiles, side-view units, impact FX
- `3/4`: creature battle sprites, bosses, showcase idles, side-view spellcasters

## Default styles by asset

`player` and `npc`, unless another style is asked for: top-down 2D pixel art for a 16-bit RPG overworld, 3/4 view from slightly above, full body visible, chunky readable pixel art with crisp dark outlines, enough margin for clean engine rendering.

Map props match the map's style:

- `clean_hd`: clean hand-painted HD 2D game asset, crisp silhouette, smooth painted surfaces, low texture noise, controlled accent lighting, no chunky pixels
- `pixel_inspired`: clean modern pixel-art-inspired prop, crisp readable shape, no 16-bit wording, no heavy dithering
- `retro_pixel`: 16-bit or retro JRPG pixel-art prop, only when the map is explicitly retro pixel

Clean HD props use a mostly front-facing top-down RPG object view: upright objects vertical and centered, only a small visible top face, no strong isometric diagonal unless requested.

`creature`, `spell`, `projectile`, `impact`, `summon`, `fx`: a strong silhouette, readable body colors or effect shape, a battle-ready or gameplay-readable pose, no painterly composition drift between frames, and humanoids clearly non-player unless the user wants a player-like unit.

## Actions

`idle`: neutral stance, subtle motion, a weight shift or aura pulse, the strongest accent just before the loop. A massive grounded boss replaces the weight shift with rooted weight: both feet and the pelvis fixed, vertical torso compression, a pulsing core, settling shoulders, small delayed secondary motion on attached ornaments, and no whole-body left or right translation. `2x2` for standard actors, `3x3` for large creatures and showcase idles.

`cast`, usually `2x3`: readiness, energy gather, stronger gather, release start, release peak, settle or hold.

`attack`: wind-up, strike, follow-through, recovery. For long quadrupeds, wolves, serpentine bodies, and actors with wide tails, don't describe a pounce as travel across the cell: lock one silhouette envelope (fixed torso center, central 70-72% safe width and height, tail and long appendages tucked in) and show the energy through in-place compression, neck and limb extension, and recoil. For controllable heroes, main characters, and fixed-cell sprites, attack prompts are body-only: no detached slash arc, wide weapon trail, muzzle flash, projectile, impact burst, or detached dust; the weapon stays close enough that the body bounding box stays near idle and run size; body height and feet anchor match the accepted idle and run sheets. A large slash, trail, flash, or spark becomes its own `fx`, `projectile`, or `impact` sheet.

`hurt`: impact, recoil, stagger, recovery.

`combat`: top-left attack wind-up, top-right attack strike, bottom-left hurt impact, bottom-right hurt recovery.

`projectile`, `2x2` or `1x4`: the same projectile identity in all frames, a consistent travel direction, small loopable shape changes, glow and trail inside the frame.

`impact`, `explode`, usually `2x2`: ignition or contact, expansion, peak burst, fade or collapse. A looping ground-contact effect such as fire gets one horizontal ignition baseline at a fixed percentage of every cell's height; tips deform above it while the contact line, width, camera distance, and scale stay fixed. For a billboarded runtime overlay, forbid baked ground, lava pools, tile plates, shadows, and perspective floor art, which make the effect look offset once placed in the engine.

`walk`, `run`, `hover`: name the travel behavior: grounded stride, hover bob, crawl, slither, mechanical glide.

## Sheets

Never prompt unrelated actions into one raw sheet ("row 1 idle, row 2 run, row 3 shoot, row 4 jump", "first row walk, second row attack, third row hurt"). Generate each action as its own multi-row grid and assemble atlases after QC ([sprites.md](sprites.md)).

`4x4` player sheet: row 1 down, row 2 left, row 3 right, row 4 up; column 1 neutral, column 2 left foot forward, column 3 neutral again, column 4 right foot forward. Try it without a layout guide first.

`3x3` large idle: exactly 9 equal cells, the same bounding box in all 9, the subject filling only about 55-65% of each cell, nothing crossing an edge. Add a layout guide after a run with uneven spacing, inconsistent scale, or edge-touching frames.

`4x4` non-directional sequence (casting, summoning, charging, transformation, death, other single-action loops): exactly 16 equal cells read left to right, row by row; describe each phase in order from anticipation through the peak to the settle or loop return; keep identity stable while pose, energy, and compact attached effects change; add a layout guide when portals, circles, summons, or other VFX might cross cells.

`5x5` and custom grids: only for one coherent action family, a prop pack, a tileset-like atlas, or one long sequence.

`1x4` projectile: exactly 4 equal cells in one row, the same projectile size in every frame, only the internal energy or shape pulse changing.

## Bundles

Write each asset's prompt independently: caster, projectile, impact; or idle, combat, walk. Never force unrelated assets into one giant sheet.

## Prompt order

1. the asset type and sheet shape
2. the subject's identity
3. the reference's role and invariants, if any
4. the frame-by-frame motion
5. the same-scale and containment rules again
6. the magenta background and no-text rules again
