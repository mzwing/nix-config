# Sprite prompts

Rules for writing sprite prompts by hand.

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

- State what stays fixed: silhouette family, palette, face and eyes, costume or markings, accessories, material language, art style.
- State what may change: pose, animation phase, action energy, size progression, evolution traits, FX intensity.
- For evolution lines, keep visible lineage markers while allowing a larger silhouette, added details, or stronger colors per form.
- The magenta background and containment rules still apply.

## Layout guides

A layout guide is a geometry-only reference for slot count, spacing, centering, and safe padding; it never sets art direction.

```bash
scripts/make_layout_guide.py --rows <rows> --cols <cols> --cell-width 384 --cell-height 384 --output <run-dir>/references/<rows>x<cols>-layout-guide.png
```

Good fits: `3x3` and `4x4` prop packs, tileset-like atlases, fixed multi-row animation grids, and non-directional 16-frame sequences (cast, summon, charge, death, transformation). Possible: `3x3` large idles and showcase loops after earlier runs drifted in scale, spacing, or edge safety. Risky: four-direction walk sheets, where guide pressure centers the poses and weakens locomotion; use a guide there only after an unguided run fails layout or edge safety.

Pass the guide with `--image` and write:

```text
Use the layout guide image as a layout-only reference. Use it only to understand the rows, columns, equal invisible frame slots, centering, spacing, and safe padding. Do not reproduce the guide: no visible boxes, no safe-area rectangles, no center marks, no labels, no borders, no guide background.
```

## Character anchor sheets

For high-value grounded player and hero actions that still drift in scale or feet placement, an anchor sheet beats abstract boxes:

1. Accept one neutral or idle master frame with the right identity, camera distance, standing scale, and padding.
2. Repeat it into every intended cell at one fixed scale and feet line:

   ```bash
   scripts/make_anchor_layout.py --input <accepted-master-frame.png> --rows 2 --cols 3 --cell-width 512 --cell-height 512 --subject-height-ratio 0.66 --feet-ratio 0.82 --output <run-dir>/references/attack-anchor-2x3.png
   ```

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

Animated body grids keep the body centered in each cell inside the central 60-70% safe area, with a stable feet line.

Elongated quadrupeds, serpentine creatures, and actors whose tail or attack nearly fills a cell get a shared-silhouette-envelope contract in every action prompt: the torso center stays fixed, every pose stays inside the same central 70-72% box, and tails and long appendages tuck inward. "Generous margin" alone doesn't contain these silhouettes.

Without detached FX: "no floating detached effects outside the main silhouette". With them: "detached effects stay tightly grouped near the main subject and still fit inside the cell".

## View

- `topdown`: overworld actors, player and NPC sheets
- `side`: projectiles, side-view units, impact FX
- `3/4`: creature battle sprites, bosses, showcase idles, side-view spellcasters

## Default styles by asset

`player` and `npc`, unless another style is asked for: top-down 2D pixel art for a 16-bit RPG overworld, 3/4 view from slightly above, full body visible, chunky readable pixel art with crisp dark outlines, enough margin for clean engine rendering.

Map props follow [props.md](props.md) in the map's style.

`creature`, `spell`, `projectile`, `impact`, `summon`, `fx`: a strong silhouette, readable body colors or effect shape, a battle-ready or gameplay-readable pose, no painterly composition drift between frames, and humanoids clearly non-player unless the user wants a player-like unit.

## Actions

`idle`: neutral stance, subtle motion, a weight shift or aura pulse, the strongest accent just before the loop. A massive grounded boss replaces the weight shift with rooted weight: both feet and the pelvis fixed, vertical torso compression, a pulsing core, settling shoulders, small delayed secondary motion on attached ornaments, and no whole-body left or right translation. `2x2` for standard actors, `3x3` for large creatures and showcase idles.

`cast`, usually `2x3`: readiness, energy gather, stronger gather, release start, release peak, settle or hold.

`attack`: wind-up, strike, follow-through, recovery. For long quadrupeds, wolves, serpentine bodies, and actors with wide tails, don't describe a pounce as travel across the cell: keep the shared silhouette envelope ([Containment](#containment)) and show the energy through in-place compression, neck and limb extension, and recoil. For controllable heroes, main characters, and fixed-cell sprites, attack prompts are body-only: no detached slash arc, wide weapon trail, muzzle flash, projectile, impact burst, or detached dust; the weapon stays close enough that the body bounding box stays near idle and run size; body height and feet anchor match the accepted idle and run sheets.

`hurt`: impact, recoil, stagger, recovery.

`combat`: top-left attack wind-up, top-right attack strike, bottom-left hurt impact, bottom-right hurt recovery.

`projectile`, `2x2` or `1x4`: the same projectile identity in all frames, a consistent travel direction, small loopable shape changes, glow and trail inside the frame.

`impact`, `explode`, usually `2x2`: ignition or contact, expansion, peak burst, fade or collapse. A looping ground-contact effect such as fire gets one horizontal ignition baseline at a fixed percentage of every cell's height; tips deform above it while the contact line, width, camera distance, and scale stay fixed. For a billboarded runtime overlay, forbid baked ground, lava pools, tile plates, shadows, and perspective floor art, which make the effect look offset once placed in the engine.

`walk`, `run`, `hover`: name the travel behavior: grounded stride, hover bob, crawl, slither, mechanical glide.

## Sheets

`4x4` player sheet: row 1 down, row 2 left, row 3 right, row 4 up; column 1 neutral, column 2 left foot forward, column 3 neutral again, column 4 right foot forward. Try it without a layout guide first.

`3x3` large idle: exactly 9 equal cells, the same bounding box in all 9, the subject filling only about 55-65% of each cell, nothing crossing an edge. Add a layout guide after a run with uneven spacing, inconsistent scale, or edge-touching frames.

`4x4` non-directional sequence (casting, summoning, charging, transformation, death, other single-action loops): exactly 16 equal cells read left to right, row by row; describe each phase in order from anticipation through the peak to the settle or loop return; keep identity stable while pose, energy, and compact attached effects change; add a layout guide when portals, circles, summons, or other VFX might cross cells.

`1x4` projectile: exactly 4 equal cells in one row, the same projectile size in every frame, only the internal energy or shape pulse changing.

## Prompt order

1. the asset type and sheet shape
2. the subject's identity
3. the reference's role and invariants, if any
4. the frame-by-frame motion
5. the same-scale and containment rules again
6. the magenta background and no-text rules again
