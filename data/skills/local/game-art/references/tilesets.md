# Tilesets

Seamless textures, terrain transitions, autotiles, ground and platform tiles, and terrain atlases. A tile's job is invisibility in repetition: judge everything by whether the player will notice the grid, and apply all of this even when the request never mentions it.

## Seamless single tiles

- Prompt for a uniform stochastic texture: even density, even lighting, no directional shadows, "the pattern continues off every edge".
- The repetition killer is a distinctive motif: one recognizable clump, flower, or rock repeats forever. Prompt for anonymous texture, and hunt for anything you could point at twice.
- Always check a real repeat: `scripts/tile_preview.py --input <tile> --output <preview>` (`--repeat 3` makes motifs easier to spot). Look for seam lines at the joins, a motif visible in every repeat, and large tone gradients that checkerboard. Any of the three means a retry.
- When the texture is right but the edges don't meet, move the seams to the middle and repaint only them: `scripts/tile_preview.py --input <tile> --offset --output <shifted> --mask <mask>` writes the tile shifted by half with a mask that is transparent along the seam cross; then `imagegen.py edit --image <shifted> --mask <mask>` with a prompt to continue the texture across the cross. The shifted tile's own edges came from the original's interior, so they already tile. Check the result with a repeat preview again.

## Transition tilesets

- Prompt a transition set (grass to dirt and so on) as one continuous painted image that happens to be sliceable, never as "tiles" or "cells with borders", which invites separate sticker tiles with gaps. Cells are filled edge to edge, with painted content flowing across cell boundaries so neighbors genuinely match.
- A 3x3 layout: the center is pure inner material, edge cells are straight transitions facing outward, corner cells are outer corners. Verify the direction of every cell: the top-center cell's grass runs along its top edge, and so on.

## Rotation economy

With neutral lighting (pure top-down, no directional shading), one straight edge and one outer corner rotate in the engine into all four of each. When the tile count is yours to choose:

- Make 1 center fill, 1 straight edge, 1 outer corner, and 1 inner corner, and spend the rest of the budget on 2-3 anonymous variants of the center fill, which break up repetition far better than four identical rotated edges.
- Rotation only works when nothing in the art encodes direction: no directional light, no gravity cues such as hanging blades or drips, no text or emblems. Side-view platformer tiles almost always encode gravity and light, so every orientation is painted. Say in the delivery notes which tiles are rotation-safe.
- When the request fixes the grid ("3x3 with all 8 transitions"), deliver exactly that and mention rotation economy in the notes instead.

## Platforms and props

Isolated on a keyable background, lit consistently with their tileset, with no baked ground shadow: engines composite shadows separately. Platform strips and caps follow [props.md](props.md).

## Terrain tile atlases

For a fixed grid, tactical board, card-board arena, or 2.5D tile mesh where each cell shows one of several opaque surfaces, generate a terrain atlas and keep the tile mesh and collision separate from the art.

- One terrain family per row with 2-4 variants each; add a geometry layout guide when exact cells matter.
- Full-bleed top-down orthographic surfaces with no gutters, labels, borders, perspective, tile thickness, actors, tall props, or UI.
- `--edge-policy isolated` when visible gaps or separate meshes divide the cells; `seamless` only when neighbors must visually join.
- One surface scale, lighting direction, grain density, and palette relationship across every family.
- Slice and validate with the extractor, which writes portable relative paths, per-variant luminance and contrast, variant-difference QC, material hints, and a Godot mesh-top runtime contract:

```bash
scripts/extract_terrain_tiles.py --input <terrain-atlas.png> --output-dir <assets/tilesets/name> --rows 2 --cols 3 --terrain-row plain=0 --terrain-row forest=1 --tile-size 512 --prompt <terrain-atlas.prompt.txt> --runtime-world-size 0.94 --surface-y 0.011 --strict-qc
```

- A low-contrast or near-duplicate variant failure means regenerate the art; never invent final texture procedurally. Runtime tint, roughness, emission, highlighting, mesh depth, and destruction animation may stay engine-native.
- Animated terrain states (flame tongues, smoke, frost glints, corruption pulses, void wisps) stay out of the opaque atlas: make them transparent FX sheets per [sprites.md](sprites.md) with a fixed ground-contact anchor and a shared silhouette envelope, and reference their runtime contract from the terrain metadata.
- A 2.5D `Sprite3D` status overlay on a horizontal tile records and validates `ground_lift`, `depth_policy`, `render_priority`, and `occupantPolicy`; a correct pixel size and offset don't prove the vertical card survives intersecting the surface. The safe default for a walkable animated status renders above the tile surface, behind unit sprites, with `rear_shift_and_fade` while occupied. Don't solve tile clipping by drawing the FX over every actor.
