# Map strategies

The axes behind each map mode, with presets. Modes, genre routing, and defaults are in [maps.md](maps.md); a mode is not a file format, so after choosing one still define the visual model, runtime objects, collision, and engine target.

## Visual model

`baked_raster`, when the scene is static, decorative, fixed-screen, or visual-first (a battle background, title scene, menu backdrop, cutscene, quick prototype), collision is absent or a few invisible shapes, or the user asks for one flat image. Deliver one generated or edited image plus optional collision and zones. Never the final runtime map for platformers, RPG exploration, tower defense, or any scene whose props, platforms, hazards, exits, or interactables must be edited, collided with, reused, or rendered independently.

`layered_raster`, when a hand-painted or generated base is best but tall objects need collision, occlusion, interaction, reuse, or later editing: RPG towns, shrines, dungeon rooms, fields, interiors, monster-taming exploration, anything where y-sorted actors walk in front of and behind props. Deliver a generated foundation-only base, separate generated props, placement metadata, collision and zone metadata, and a flattened preview ([layered-maps.md](layered-maps.md)).

`tilemap`, when the engine or editor already uses Tiled, LDtk, Phaser tilemaps, Godot TileMap, Unity Tilemap, or similar, the user asks for tiles, tilesets, tile collision, autotiling, or grid-perfect editing, or procedural generation, large maps, or editor workflows matter. Deliver generated or supplied tileset images, engine-native map data, tile and object layers, and tile or object collision. A pure terrain map can stay tileset plus map data plus collision; use [sprites.md](sprites.md) only for reusable transparent props, NPCs, animated objects, or non-tile scene objects.

`layered_tilemap`, when the game needs several tile layers (ground, decor, walls, overhead, foreground), actors pass under some of them, and collision and triggers are tile or object-layer driven. Deliver the tileset art, the layered tile data, and a render-order contract.

`parallax_layers`, when the map is a side-scroller, platformer, runner, shooter, brawler, scrolling action stage, or scrolling backdrop and background depth matters more than top-down collision. Deliver generated background, midground, and foreground plates with scroll-speed metadata. For a playable stage the plates are scenery only; the rest of the stage follows [side-scroll.md](side-scroll.md).

## Runtime object model

Use the simplest model that expresses collision and occlusion correctly:

- `none`: the map is just a background or tile layers.
- `separate_props`: props are independent sprites without y-sorting.
- `platform_objects`: platforms, walkable lanes, terrain chunks, walls, hazards, foreground blockers, and other collidable stage geometry are independent runtime objects with placement and collision data.
- `y_sorted_props`: props and actors sort by base `y`, for top-down RPG scenes.
- `interactive_scene_objects`: doors, pickups, switches, checkpoints, gates, destructibles, signs, exits, and other non-character objects with interaction or state.
- `foreground_occluders`: selected overlays always draw over actors.
- `scene_hooks`: metadata-only markers such as player spawn, actor spawn markers, encounter zones, patrol hints, arena triggers, camera bounds, exit links, and checkpoint ids. No actor art is needed.

## Collision model

- `none`: visual-only maps and simple backgrounds.
- `coarse_shapes`: a few rectangles or ellipses for fixed arenas or decorative maps.
- `precise_shapes`: explicit blockers and walk bounds for layered RPG maps.
- `tile_collision`: collision stored per tile or tile layer.
- `polygon_walkmesh`: irregular walkable regions or constrained path maps.
- `trigger_zones`: encounter, rest, exit, and dialogue areas, usually combined with another model.

Never infer collision from prop PNG bounds automatically: blockers cover prop bases, and walkable zones are explicit.

## Engine target

The visual assets always come from image generation or existing art; the target decides how they are wired.

- `raw_canvas`: PNG assets, JSON metadata, and project-specific render code.
- `Phaser`: atlas and tilemap JSON when the project already uses Phaser loaders.
- `Tiled_JSON`: Tiled-compatible tilesets, layers, objects, and custom properties.
- `LDtk`: LDtk entity and layer concepts when the project uses LDtk.
- `Godot_TileMap`: tile layers and scene metadata in Godot's structure, after the tileset art exists.
- `Unity_Tilemap`: tileset or sprite assets and placement data for Unity workflows.
- project-native: keep the schema the game already has.

## Mode contracts

- `tile_mode`: tileset art, map data, tile layers, object layers, collision, exits, and a preview.
- `scene_mode`: the default for beautiful top-down demos, tower defense scenes, survivors-like arenas, and base-plus-props workflows.
- `side_scroll_mode`: scenery-only parallax plates plus separate playable foreground objects; parallax creates depth and is never a collision source. Brawlers replace jump platforms with a walkable belt polygon, foreground and background props, enemy wave zones, and camera locks.
- `grid_mode`: validation over beauty; the map must be readable by game logic.
- `room_chunk_mode`: reusable chunks with sockets and seam validation, plus an assembled layout preview when there are several.
- `baked_scene_mode`: a fixed image with optional coarse collision and zones only.

## Presets

- Fixed battle background: `baked_raster`, `none`, `none` or `coarse_shapes`. One PNG, optional zones.
- RPG exploration scene: `layered_raster`, `y_sorted_props`, `precise_shapes` + `trigger_zones`. Base, props, placement JSON, collision JSON, preview.
- Monster grassland: `layered_raster`, `y_sorted_props` + `interactive_scene_objects` + `scene_hooks`, `precise_shapes` + `trigger_zones`. Rocks, shrubs, flowers, signs, and small logs suit prop packs.
- Tile-based dungeon: `layered_tilemap`, `interactive_scene_objects` + `scene_hooks`, `tile_collision` + `trigger_zones`, only when the engine or editor supports tilemaps.
- Side-view action or platformer stage (Mega Man-, Castlevania-, Contra-like, runners, shooters, brawlers, in any art style): `parallax_layers`, or `layered_tilemap` when the engine already uses tiles; `platform_objects` + `interactive_scene_objects` + `scene_hooks` + `foreground_occluders`; `precise_shapes` or engine-native platform collision. The deliverables and the anti-patterns are in [side-scroll.md](side-scroll.md).

## Escalation

Start with the smallest playable bundle that works:

1. non-playable background: `baked_scene_mode`
2. beautiful top-down or tower-defense demo: `scene_mode`
3. editable top-down, platform, or grid map: `tile_mode`
4. playable side-view scrolling or action stage: `side_scroll_mode`
5. rules-first tactical, factory, or board scene: `grid_mode`
6. procedural or modular room assembly: `room_chunk_mode`
