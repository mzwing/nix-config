# Props and scene objects

Reusable transparent props and visible scene objects for maps. Write each prop prompt yourself in the map's `art_style`: clean HD props explicitly forbid pixel art, `pixel_inspired` props avoid retro chunkiness, and `retro_pixel` props ask for 16-bit or retro JRPG pixel art.

## Classify first

Before generating any prop or object, classify every visible runtime object from the reference mockup:

- `compact_prop`: small or medium, roughly square or vertical, decorative or a simple blocker, no exact alignment requirement
- `wide_or_long_object`: wider than about 1.6:1, such as platforms, floors, bridges, ledges, wall runs, fence rows, long traps, rails, pipes, roads, conveyors, long signs
- `tall_or_large_object`: taller than about 1.6:1 or visually dominant, such as buildings, gates, large trees, towers, doors, banners, statues, shrine pieces
- `collision_bearing_object`: lines up with collision, walkable edges, build pads, hazards, doors, gates, checkpoints, exits, or engine editor handles
- `tileset_or_strip_piece`: repeats seamlessly or assembles from caps, middles, corners, slopes, tops, sides, or tile pieces

The class decides the shape:

- Only `compact_prop` objects may share a square `2x2`, `3x3`, or `4x4` pack.
- Everything else goes one by one, as a platform strip, in a custom wide pack, or as tile, object-layer, or engine-native art.
- Never mix classes in one sheet. Small rocks, crates, lamps, and grass together are fine; rocks next to platforms, floor pieces, gates, ladders, or spike hazards are not.
- When a square pack fails because a wide or tall object touches an edge, don't retry the same pack or loosen QC: reclassify that object and regenerate it in a fitting shape.

Also classify props that share space with actors:

- `blocker`: actors can't share the footprint; normal depth sorting is enough.
- `walkable_low_dressing`: actors may share the tile or lane, and the prop stays below the important body silhouette.
- `walkable_tall_dressing`: actors may share the tile or lane but the prop can cover the body, so it needs an actor-safe placement and a runtime occupant policy.

Shrubs, grass clusters, and rubble that share a walkable tile prefer a low silhouette or a rear-biased cluster that leaves the actor-safe center clear. On a fixed isometric board, never center tall walkable dressing on the actor anchor; if the art still overlaps the actor, use `rear_shift_and_fade` at runtime, fading only the tall decoration and keeping the ground. Render priority alone is not an occlusion policy.

## Shapes

- `one_by_one`: the safest, for large, important, animated, irregular, identity-sensitive, or collision-aligned objects
- `prop_pack_2x2`: 4 related compact props, the safest batch
- `prop_pack_3x3`: 9 compact small or medium props, the default for a compact set with no stated count
- `prop_pack_4x4`: 16 very simple small props, the fastest and the most likely to drift or touch edges
- `platform_strip_1x3`: a repeatable floor or platform as left cap, seamless middle, and right cap
- `platform_strip_1x4`: the same plus one slope, corner, broken, end, or underside piece
- `custom_wide_pack`: several similar wide objects of one category in explicit non-square cells such as `768x256` or `1024x384`

Packs save generation calls but cost per-prop control. They suit rocks, shrubs, flowers, mushrooms, logs, crates, barrels, sacks, pots, small signs, lamps, lanterns, posts, floor ornaments, small statues, ruins, debris, and repeated dressing for one biome. They never hold buildings, gates, wide-canopy trees, bridges, floors, platforms, terrain chunks, ledges, wall runs, rails, ladders, roads, fence rows, long hazards, pipes, conveyors, ramps, slopes, hero objects, key story artifacts, readable statues, animated or multi-state props, or anything that must be pixel-exact, collision-aligned, or too wide or tall for a square cell. Platform strips are not animation frames: never use them for characters, enemies, creatures, NPCs, summons, or animated bodies.

Side-scroller platformers build one shared structural library (strips, tiles, terrain chunks) per stage style before any decoration, and reuse it across segments ([side-scroll.md](side-scroll.md)); compact decorations, pickups, small terminals, crates, lamps, and debris go into square packs only afterwards. Platform placement and collision live in metadata or engine nodes; the image is only the skin.

## Pack prompt

For `3x3` and `4x4` packs, make a layout guide first and pass it with `--image` as a layout-only reference ([sprite-prompts.md](sprite-prompts.md#layout-guides)):

```bash
scripts/make_layout_guide.py --rows <ROWS> --cols <COLS> --cell-width 384 --cell-height 384 --output assets/props/raw/<name>-layout-guide.png
```

```text
Create exactly one <ROWS>x<COLS> prop sheet for a top-down 2D RPG map.
Each cell contains one separate static environmental prop from this list, in row-major order:
1. <prop>
2. <prop>
...
All props share the same biome, palette, camera angle, selected map art style, and scale.
Use clean hand-painted HD 2D game asset style by default: crisp silhouettes, smooth surfaces, low texture noise, controlled accent lighting. Do not make pixel art unless the user asked for it.
Mostly front-facing top-down RPG object view: upright objects are vertical and centered, with only a small visible top face. Avoid strong isometric diagonal rotation; crates and barrels should not become diamond-shaped or tilted unless the user explicitly asks for isometric art.
Full object visible, centered in its own cell, crisp but not chunky outlines.
Each prop must fit fully inside the central 50% to 60% of its cell with generous flat magenta gutters on all four sides.
No prop, branch, roof, sign, glow, cable, smoke, sparkle, shadow, or fragment may touch or cross a cell edge.
This square prop sheet must contain only compact props. Do not include floors, platforms, bridges, wall runs, ladders, long hazards, gates, doors, buildings, wide trees, roads, ramps, slopes, or any object that needs exact collision or walkable-edge alignment.
Background must be 100% solid flat #FF00FF magenta in every cell, no gradients, no texture, no shadows, no floor plane.
No text, labels, UI, watermark, numbers, arrows, borders, grid lines, or readable letters.
```

An intentionally empty cell is written as `empty magenta cell`. After a reference mockup, derive the list from the mockup and the base you passed as references, never from memory.

## Platform strip prompt

```text
Create exactly one 1x3 platform strip asset sheet for a 2D game map.
Cells, left to right:
1. left end cap of the platform
2. seamless middle repeat segment
3. right end cap of the platform

Each cell is a wide non-square cell, intended for platform/floor collision alignment.
Every segment must have a perfectly horizontal walkable top edge at the same y-position across all cells.
The middle segment must tile seamlessly left-to-right.
No segment may touch or cross its cell edge except intentional seamless side edges on the middle repeat cell.
Use solid flat #FF00FF magenta background, no floor plane, no shadows, no labels, no UI, no guide lines.
```

Use a layout guide with wide cells. A unique, large, or important platform is generated one by one on a wide canvas instead.

## Extraction

A sheet with antialiased magenta fringe, or props that will sit on a dark or detailed base, gets a soft key first:

```bash
scripts/chroma_key.py --input assets/props/raw/forest-props-sheet.png --output assets/props/raw/forest-props-sheet-alpha.png --edge-contract 1
```

Then extract:

```bash
scripts/extract_prop_pack.py --input assets/props/raw/forest-props-sheet-alpha.png --rows 3 --cols 3 --labels mossy-rock,shrub,fallen-log,small-lantern,wooden-sign,flower-patch,stump,crate,grass-tuft --output-dir assets/props --manifest assets/props/forest-prop-pack.json --component-mode largest --component-padding 8 --min-component-area 200 --reject-edge-touch
```

This writes `assets/props/<label>/prop.png` per cell and a manifest with source cells, crop boxes, alpha bounds, sizes, component counts, and `edge_touch` flags. When large props touch cell edges, regenerate with stricter occupancy ("each prop must fit inside the central 50% of its cell") rather than relaxing QC, unless the clipped prop is deliberately dropped. Noisy particles or edge debris: `--component-mode largest`. Intentional multi-part props: `--component-mode all` with more margin in the prompt.

## Placement

Placement JSON follows [layered-maps.md](layered-maps.md#prop-metadata). Tall walkable vegetation on a fixed isometric grid carries an explicit policy:

```json
{
  "occlusionClass": "tall",
  "actorSafeArea": { "shape": "ellipse", "cx": 0.5, "cy": 0.76, "rx": 0.24, "ry": 0.18 },
  "occupantPolicy": {
    "mode": "rear_shift_and_fade",
    "rearOffsetCells": [-0.18, -0.18],
    "occupiedScale": 0.91,
    "occupiedOpacity": 0.28
  }
}
```

These are runtime placement values, never baked into the PNG. Then compose a QA preview with `scripts/compose_layered_preview.py`.

## QC

Reject or regenerate a pack when:

- any accepted prop has `edge_touch: true`
- labels don't match the requested cells
- a prop has text, UI, shadows, or a floor baked in
- a prop drifts into character or NPC-like art
- a prop is too large for its intended placement scale
- a square pack contains a wide, long, tall, large, collision-bearing, platform, floor, bridge, wall, ladder, gate, door, or strip object
- walkable tall dressing has no actor-safe area or occupant policy
- an actor-in-place preview at gameplay camera scale hides the actor's head, torso, weapon or action silhouette, selection ring, or path cues
