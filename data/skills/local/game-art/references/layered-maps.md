# Layered raster maps

Hand-painted or generated 2D RPG scenes, monster-taming exploration maps, shrine, town, and dungeon maps, and any top-down scene where actors interact with props.

## Layers

1. `base`: one raster image with only terrain and ground-level detail
2. `props`: transparent sprites anchored in map coordinates
3. `actors`: player, NPCs, monsters, pickups, moving objects
4. `foreground`: optional transparent sprites that cover actors
5. `collision`: structured metadata, not pixels
6. `zones`: structured metadata for encounters, rest, triggers, exits, dialogue
7. `preview`: a flattened QA artifact only

## Base map prompt

Default to clean HD for gameplay readability unless the user asks for pixel art:

```text
Create a clean hand-painted top-down 2D RPG game map.
This is a BASE GROUND MAP ONLY for a layered raster exploration scene.
Style: clean HD game asset style, sharp readable terrain shapes, crisp silhouettes, smooth painted surfaces, low texture noise, controlled accent lighting.
Do not make pixel art. Avoid chunky pixels, retro dithering, noisy microtexture, tiny debris, clutter, blurry painterly mush, and over-detailed grime.
Include terrain, paths, grass/water/floor materials, ground markings, floor patterns, and flat anchor pads.
Do not include tall collidable objects: no buildings, gates, fences, lanterns, trees, signs, barrels, NPCs, monsters, UI, or text.
Leave clear empty spaces where props will be placed later.
Make walkable paths and zone boundaries easy to trace.
```

For a pixel-adjacent look write `clean modern pixel-art-inspired` and still forbid heavy dithering and noisy microtexture. Use `16-bit pixel art`, `retro JRPG pixel art`, or similar only when the user asks for a retro pixel look.

## Dressed reference

1. Generate the base as ground-only terrain.
2. Pass it with `--image` to `imagegen.py edit` and ask for a dressed version that only adds props.
3. Preserve the exact camera, framing, dimensions, terrain, paths, water, anchor pads, collision-relevant boundaries, and map edges.
4. Use the dressed reference to choose prop identities and placements, but compose the runtime preview from the original base plus the final transparent props ([maps.md](maps.md#after-the-mockup)).

```text
Image 1 is the exact base map reference.
Create a dressed-reference version of the same map by adding props only.
Preserve exactly: camera, framing, image size, terrain, paths, water, anchor pads, rocks, map boundaries, and all walkable routes.
Do not crop, zoom, rotate, repaint, or redesign the terrain.
Add these props naturally on top of the existing map: <list>.
Props should feel intentionally placed along paths, landmarks, encounter-zone edges, rest points, and entrances.
No UI, no text, no labels, no watermark.
```

## One-by-one props

One-by-one props are safest for large, important, irregular, animated, or identity-critical objects; sets of small static props can share a pack ([props.md](props.md)).

```text
Create a single <prop> prop for a top-down 2D RPG map.
Use the same selected map art style: clean HD hand-painted by default, pixel-inspired only when requested, retro pixel only when explicitly requested.
Mostly front-facing top-down RPG object view: upright objects are vertical and centered, with only a small visible top face. Avoid strong isometric diagonal rotation.
Full object visible, centered, crisp but not chunky outlines.
Background must be 100% solid flat #FF00FF magenta, no gradients, no texture, no shadows, no floor plane.
No text, labels, UI, or watermark.
Entire prop must fit fully inside the image with generous magenta margin on all sides; no part may touch or cross the image edge.
```

Process it:

```bash
scripts/generate2dsprite.py process --input <raw.png> --target asset --mode single --rows 1 --cols 1 --cell-size 256 --output-dir assets/props/<prop> --fit-scale 0.9 --align feet --component-mode largest --component-padding 8 --min-component-area 200 --threshold 100 --edge-threshold 150 --edge-clean-depth 2
```

The 1x1 grid gives the cut-out edge and component QC; it lands in `single-1.png`, so rename it to `prop.png` to match the folders that pack extraction writes. Use a larger `--cell-size` for buildings, trees, gates, statues, and large signs.

## Prop metadata

Use explicit map-space dimensions:

```json
{
  "props": [
    {
      "id": "torii",
      "image": "assets/props/torii/prop.png",
      "x": 836,
      "y": 850,
      "w": 380,
      "h": 306,
      "sortY": 850,
      "layer": "props",
      "occlusionClass": "tall",
      "actorSafeArea": { "shape": "ellipse", "cx": 0.5, "cy": 0.82, "rx": 0.18, "ry": 0.12 },
      "occupantPolicy": { "mode": "y_sort" }
    }
  ]
}
```

- `x`: the center of the prop's base; `y`: the bottom of the prop in map coordinates
- `w`, `h`: the rendered size in map units
- `sortY`: the depth for render ordering, normally the base `y`
- `layer`: `props` for y-sorted objects, `foreground` for overlays that always cover actors
- `occlusionClass`: `low`, `tall`, or `foreground`, by how much of an actor it can cover
- `actorSafeArea`: the normalized area that must keep the actor's actionable silhouette readable
- `occupantPolicy`: the runtime treatment when an actor shares or selects the footprint, `y_sort` for normal blockers and `rear_shift_and_fade` for tall decoration on walkable cells

An actor-safe area is a readability contract, not collision; collision still uses explicit blockers. Slight foot overlap is fine, but the head, torso, held weapon or action silhouette, selection state, and path cues stay visible.

## Render order

```text
base map
ground effects / zone glimmers
renderables sorted by sortY:
  props
  actors
foreground overlays
debug collision
HUD/UI
```

An NPC that must always appear above the player is drawn after the y-sorted pass or gets a high `sortY`.

## Collision metadata

Keep it readable and hand-editable:

```json
{
  "mapSize": { "width": 1672, "height": 941 },
  "spawn": { "x": 836, "y": 782 },
  "walkBounds": [
    { "id": "main-courtyard", "type": "ellipse", "x": 838, "y": 548, "rx": 604, "ry": 304 }
  ],
  "blockers": [
    { "id": "torii-left-pillar", "type": "rect", "x": 704, "y": 668, "w": 52, "h": 176 }
  ],
  "zones": {
    "grass": { "type": "rect", "x": 180, "y": 306, "w": 382, "h": 302 },
    "rest": { "type": "circle", "x": 760, "y": 548, "radius": 122 }
  }
}
```

- Blockers cover prop bases, not whole sprite silhouettes.
- Keep entrances open by testing path centers.
- Ellipses for lanterns, rocks, trees, and basins; rectangles for fences, walls, buildings, gates, bridges, and posts; polygons only when rectangles and ellipses walk badly.

## Preview

```bash
scripts/compose_layered_preview.py --base assets/map/shrine-base.png --placements data/shrine-props.json --output assets/map/shrine-layered-preview.png
```

Placements anchor at the center bottom unless a prop sets `anchor` (`top-left`, `center`, `bottom-left`); `opacity` and `foreground` layers are honored, and `--report` writes what was pasted where.

## QA checklist

- The spawn point and the main path centers are walkable.
- Gate centers are walkable when the player should pass; gate pillars block.
- Fences block while entrances stay open.
- Interactables block at their base but can be approached.
- Encounter and rest zones are reachable.
- Actors sort correctly walking in front of and behind tall props.
- Walkable tall dressing is tested with a representative actor standing in its footprint, and its occupant policy keeps the actionable silhouette.
- The flattened preview matches the in-game layered render closely enough for review.

## Anti-patterns

- Cutting props out of a fully baked generated map.
- A flattened map as the only source when collision or occlusion matters.
- Text, signs, UI, NPCs, or monsters baked into the base.
- Prop sprites touching image edges.
- Transparent PNG bounds treated as collision.
- Art updated without updating collision and critical point tests.
