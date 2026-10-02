# Maps

Production-oriented 2D maps: RPG and monster-taming maps, tactical arenas, battle backgrounds, side-scroller stages, tilemaps, layered raster maps, prop packs, collision, walkable areas, and previews. Build the smallest playable map bundle that satisfies the game.

## Decide the pipeline

Choose a user-facing `map_mode` first, then the lower-level axes:

1. `map_mode`: `tile_mode` | `scene_mode` | `side_scroll_mode` | `grid_mode` | `room_chunk_mode` | `baked_scene_mode`
2. `visual_model`: `baked_raster` | `layered_raster` | `tilemap` | `layered_tilemap` | `parallax_layers`
3. `runtime_object_model`: `none` | `separate_props` | `platform_objects` | `y_sorted_props` | `interactive_scene_objects` | `foreground_occluders` | `scene_hooks`
4. `collision_model`: `none` | `coarse_shapes` | `precise_shapes` | `tile_collision` | `polygon_walkmesh` | `trigger_zones`
5. `engine_target`: `raw_canvas` | `Phaser` | `Tiled_JSON` | `LDtk` | `Godot_TileMap` | `Unity_Tilemap` | project-native

Use the parameters the user states; otherwise infer the lightest playable pipeline from the existing game, camera, collision needs, map scale, and editing needs. When the mode and an axis disagree, the mode's playable and editable contract wins: `side_scroll_mode` always needs separate collision and platform data, even next to a beautiful full-width preview. "Hybrid" is a combination of axes, not a category. Each mode, axis, and preset is described in [map-strategies.md](map-strategies.md).

A playable map, level, stage, room, prototype, or engine scene is never one baked image unless the user asked for a flat background only. A baked image may serve as a background, a reference, or a preview; the playable deliverable exposes gameplay geometry and objects as separate layers, props, tile or object data, collision, zones, or engine-native nodes. Requests mentioning a game, playable, prototype, level, stage, side-scroller, platformer, RPG exploration, tower defense, or engine integration start from the nearest playable preset.

Maps hold scenes, not actors. Characters, enemies, bosses, NPCs, players, projectiles, and animations come from [sprites.md](sprites.md); the map carries only scene hooks as metadata: player spawns, actor spawn markers, patrol and encounter zones, arena entrances, gates, exits, camera triggers.

## Modes

- `tile_mode`: editable tile and grid maps for RPGs, monster-taming games, platformers, tactical maps, factory games, and engines or editors that already use tiles. Axes: `tilemap` or `layered_tilemap`, `interactive_scene_objects` + `scene_hooks`, `tile_collision` + `trigger_zones`.
- `scene_mode`: a base map plus separate props for tower defense, survivors-like arenas, cozy demos, top-down adventure scenes, and showcase maps. Axes: `layered_raster`, `separate_props` or `y_sorted_props` + `interactive_scene_objects` + `scene_hooks`, `precise_shapes` + `trigger_zones`.
- `side_scroll_mode`: parallax stages for action platformers, runners, Metroidvania rooms, side-view shooters, and brawlers. Axes: `parallax_layers`, `platform_objects` + `interactive_scene_objects` + `foreground_occluders` + `scene_hooks`, `precise_shapes`. See [side-scroll.md](side-scroll.md).
- `grid_mode`: rule-heavy grids for tactical RPGs, factory and automation games, board and card battlers, build grids, and terrain-cost maps. Axes: `layered_tilemap` or `tilemap`, `interactive_scene_objects` + `scene_hooks`, `tile_collision` or grid metadata.
- `room_chunk_mode`: modular rooms for roguelikes, Metroidvania networks, dungeons, and procedural assembly. Axes: `layered_tilemap`, `parallax_layers`, or `layered_raster`, with object layers, exit and connection metadata, and collision.
- `baked_scene_mode`: fixed battle backgrounds, title and menu screens, boss-room concept art, visual novel and point-and-click backgrounds, and other explicitly flat scenes. Axes: `baked_raster`, `none` or `coarse_shapes`.

## Genre routing

| User asks for | Mode | Notes |
|---|---|---|
| Pokemon-like, monster-taming RPG, top-down RPG town or route | `tile_mode` | optional props, encounter zones, exits, NPC spawn markers, collision |
| tower defense, Kingdom Rush-like | `scene_mode` | path metadata, build slots, props, blockers, spawn and exit hooks, optional engine scene |
| survivors-like arena | `scene_mode` or `tile_mode` by map scale | sparse obstacles, spawn rings or zones, camera bounds, separate collision |
| Mega Man-like, side-view action, platformer, runner | `side_scroll_mode` | parallax layers plus platform, object, and collision metadata |
| Metroidvania | `side_scroll_mode` or `room_chunk_mode` | room exits and camera bounds; a tilemap when the engine expects grid collision |
| beat-em-up, brawler | `side_scroll_mode` | a walkable belt polygon instead of jump platforms, depth layers, props, enemy wave zones, camera bounds |
| tactical RPG, grid strategy | `grid_mode` | terrain, move cost, defense and effects, unit slots, collision |
| factory, automation | `grid_mode` | buildable cells, resource nodes, machine slots, belts and item lanes |
| card or board battler, UI-heavy game | `grid_mode` | board slots, UI zones, interaction regions, background art |
| roguelike room, procedural dungeon, modular rooms | `room_chunk_mode` | chunk sockets, exits, collision, spawn markers, seam validation |
| visual novel, title screen, point-and-click, boss arena concept, fixed battle background | `baked_scene_mode` | only when no runtime editing or collision is needed |

## Parameters

Users may state these in plain words:

- `map_mode`, `visual_model`: as above
- `map_kind`: overworld | town | dungeon | shrine | arena | battle_bg | side_scroller | side_view_action | platformer | metroidvania | brawler | tower_defense | survivors_like | tactical | factory | card_board | room_chunk
- `size`: pixel dimensions, tile dimensions, or camera-relative size
- `stage_canvas`, `stage_segment_count`: side-scroll only ([side-scroll.md](side-scroll.md))
- `perspective`: top-down | 3/4 top-down | side-view | isometric-like
- `art_style`: clean_hd | pixel_inspired | retro_pixel | hand_painted | project-native
- `visual_asset_source`: generated | existing_assets | procedural_placeholder
- `collision_precision`: none | coarse | precise | tile | walkmesh
- `tile_generation`: none | terrain_tile_bundle | autotile_set | engine_native_tileset
- `platform_strategy`: platform_rects_with_shared_tiles | platform_strip | tilemap | custom_terrain_chunks
- `prop_generation`: none | one_by_one | prop_pack_2x2 | prop_pack_3x3 | prop_pack_4x4 | platform_strip_1x3 | platform_strip_1x4 | custom_wide_pack
- `output_format`: PNG only | layered preview | manifest JSON | engine-native map data

Defaults when unspecified:

- Art comes from the image model; `existing_assets` only when the project already has suitable art, `procedural_placeholder` only when asked.
- `baked_raster` + `coarse_shapes` only for battle backgrounds, title and menu scenes, cutscenes, decorative backdrops, non-playable previews, or an explicit request for one flat image.
- `layered_raster` + `y_sorted_props` + `precise_shapes` for top-down RPG exploration with tall props, occlusion, interactables, or reusable props, on a foundation-only base.
- `tilemap` or `layered_tilemap` only when the engine or editor already uses tiles or the user asks for editable tiles, never flattening gameplay objects into one background.
- Square prop packs only for 4 or more compact small or medium static props in one style; everything else one by one, as strips, tile or object layers, or custom wide packs ([props.md](props.md)).
- `art_style` is `clean_hd`: a clean hand-painted top-down 2D RPG map, HD game-asset style, sharp readable terrain shapes, low texture noise, no chunky pixels. `pixel_inspired` only for a pixel-adjacent look without retro chunkiness; `retro_pixel` only when the user asks for 16-bit, retro JRPG, or classic pixel art.

## Art comes from the image model

- Base maps, reference mockups, prop sheets and sprites, tileset art, parallax layers, and battle backgrounds all come from `imagegen.py`, and you write every prompt. Scripts may assemble, slice, key, crop, validate, compose previews, emit JSON, and wire generated assets into engine files such as Godot `.tscn` scenes; they never write creative prompts or draw final art.
- Procedural or scripted placeholder art only when the user asks for placeholders, test fixtures, debug maps, or scaffolding without final art. With a tile engine target, generate or reuse the tileset art first, then script only tile layers, collision, zones, and scene wiring.
- Every generated visual asset keeps its prompt beside it as `<asset>.prompt.txt` (which `imagegen.py` writes) or in a manifest field.
- A rerunnable script that creates the whole art pack is not the solution unless the user asked for procedural placeholders.

## Layer separation

The first generated base, background, or foundation image of any playable or editable layered map holds only stable, non-interactive foundation art, in every perspective and style:

- top-down and 3/4 maps: ground material, paths, roads, water, cliffs, low terrain markings, floor patterns, terrain boundaries
- tactical and tower-defense maps: ground, lanes, roads, build pads, lane markings, terrain zones, non-interactive floor detail
- side-view stages: sky, far and mid scenery, distant buildings and terrain silhouettes, atmosphere, non-colliding depth
- tilemaps: tileset art and editable tile layers, not a flattened full-scene background

Unless the user asked for a single baked image, it never contains tall props, buildings, trees, rocks, crates, signs, doors, gates, pickups, chests, checkpoints, hazards, traps, turrets, towers, ladders, foreground occluders, destructibles, actors, enemies, NPCs, bosses, players, UI, labels, or anything else that needs collision, interaction, replacement, reuse, y-sorting, animation, engine editing, or its own render order. A generated base that contains them is regenerated as foundation-only or demoted to a concept or reference artifact. Proposed objects appear first in the reference mockup, then as separate runtime assets and data.

## Reference mockups

A reference mockup places the proposed objects in-world on the real base, so their placement is coherent while the runtime still gets separate objects: `<name>-dressed-reference.png` for top-down maps, `<name>-stage-reference.png` for side-view stages.

Generate it from the actual base:

1. Save the base or background first.
2. Pass that exact file with `--image` to `imagegen.py edit`, and look at it yourself.
3. Say in the prompt that Image 1 is the visual reference, and name the concrete features to preserve from what you saw: camera framing, dimensions, horizon, terrain boundaries, road and water shapes, entrances and exit directions, major silhouettes, empty pads, landmark positions.
4. Ask for an in-world mockup, not an annotated diagram: no circles, arrows, outlines, labels, numbers, callouts, text, captions, legends, highlighted boxes or zones, measurement lines, or explanatory overlays.
5. Render only visible scene objects (props, platforms, terrain chunks, hazards, gates, pickups, checkpoints, doors, exits, foreground occluders) as natural game-world objects or subtle in-world blockout geometry. Spawns, triggers, camera bounds, and patrol hints are written later as scene-hook metadata.
6. Keep it sparse: at most 9 distinct visible runtime object candidates unless the user asks for a dense concept sheet. Repeats of one platform, lamp, crate, hazard, pickup, or gate count once and recur later in placement metadata.

A filename, a path in the prompt, or "based on the map" is not a handoff. Mockups are planning artifacts: never ship one as the runtime map, infer collision from its pixels, or cut final platforms or props out of it.

## After the mockup

A reference mockup is a checkpoint, never the deliverable. Stopping after it is an incomplete run for any playable map, layered map with props, side-view stage, engine scene, or request for separate or editable props, unless the user asked for a reference-only concept image. Continue:

1. Look at the original base or background and the mockup together.
2. List every visible runtime object from the mockup, cross-checked against the base: id, type, approximate position and size, render layer, collision role, and asset strategy. With more than 9 distinct candidates, generate the 9 most gameplay-relevant first and express repeats and low-value decoration in placement metadata or a later pass.
3. Classify each object and choose exactly one strategy ([props.md](props.md)): a separate transparent asset, extraction from a generated pack, or a tile or object layer when the pipeline is tile-based.
4. Generate the final platforms, terrain chunks, props, hazards, pickups, doors, gates, checkpoints, exits, and foreground occluders even though the mockup already shows them. Pass the base and the mockup as references, list the exact objects, and keep the base's style, lighting, perspective, and scale cues; never generate generic props from memory or filenames.
5. Write placement metadata (`data/<name>-props.json`, `data/<name>-objects.json`, engine-native object layers, or tile and object data).
6. Write collision, zones, scene hooks, camera bounds, and exits as structured metadata.
7. Compose a QA preview from the original base plus the final runtime objects.

## Workflow

1. Inspect the target game: camera size, map dimensions, coordinate system, render order, asset loading, collision support, zone data, existing map formats. Keep its style and data contracts.
2. Choose `map_mode`, then the axes. A playable request gets explicit runtime objects; never downgrade it to `baked_raster`. A playable side-view stage locks to `parallax_layers` + `platform_objects` + `interactive_scene_objects` + `scene_hooks` + `precise_shapes` unless the engine already requires a tilemap. Prefer readable gameplay shapes to decorative texture density.
3. Produce the assets:
   - baked raster: one generated background, or an edit of a supplied image, plus optional collision and zones
   - layered raster: a foundation-only base, then the dressed reference, then final props and placements ([layered-maps.md](layered-maps.md))
   - tilemaps: generated or reused tileset art first ([tilesets.md](tilesets.md)), then the engine's layer, object, collision, and scene formats; never script-draw the final tileset or flatten object layers into one image
   - `grid_mode`: generated or reused grid or tileset art, then cell metadata (walkable and buildable flags, move cost, terrain effects, resource nodes, object layers)
   - `room_chunk_mode`: chunk dimensions, exits, connection sockets, collision contract, and spawn and trigger metadata before final art; chunks are reusable and validated at their seams
   - side-view stages: [side-scroll.md](side-scroll.md)
4. Build the metadata:
   - prop placement, player spawns, actor spawn markers, interactables, blockers, walk bounds, encounter zones, exits, camera bounds, and triggers as structured data
   - visible dressing on walkable cells or actor lanes gets an occlusion class (`low`, `tall`, `foreground`), an actor-safe area, and an occupant policy (`none`, `rear_shift`, `fade`, `rear_shift_and_fade`, `hide`); render priority alone doesn't keep actors readable
   - `grid_mode`: grid dimensions, cell size, tile ids, terrain types, walkable and buildable flags, movement cost, collision, resource nodes, object and entity slots
   - `room_chunk_mode`: chunk id, size, entrances and exits, connection sockets, collision, spawn markers, camera bounds, seam validation hints
   - collision stays independent of pixels unless the engine uses tile collision
5. Validate and preview (below).

## Deliverables

Baked raster, only for non-playable backgrounds and explicitly flat images: `assets/map/<name>.png`, its prompt file, optional `data/<name>-collision.json` or `data/<name>-zones.json`, and the code that loads it. As soon as actors move through the scene, collide with geometry, jump on platforms, collect items, trigger doors, or the level must be edited later, upgrade to a layered, parallax, tilemap, or engine-native deliverable.

Layered raster and `scene_mode`: a foundation-only `assets/map/<name>-base.png` and its prompt, the in-world `assets/map/<name>-dressed-reference.png`, `assets/props/<prop>/prop.png` folders from one-by-one props or extracted packs, `data/<name>-props.json`, collision, zones, exits, camera bounds, and scene hooks as needed, `assets/map/<name>-layered-preview.png`, and code that loads the base, props, y-sorted renderables, collision, and zones.

Tilemap or layered tilemap: generated or supplied `assets/tilesets/<name>.png`, optional slicing or atlas metadata, engine-native tile layers (Tiled JSON, LDtk, Godot TileMap, Unity tile placement, or project-native JSON), object layers for spawns, exits, interactables, blockers, and zones, and a flattened preview from the tileset and layer data.

`grid_mode`: generated or supplied grid art, optional `generate2dmap.terrain_tile_bundle.v1` manifests ([tilesets.md](tilesets.md)), grid dimensions, cell size, and map data in a project-native or editor format, cell metadata (walkable, buildable, move cost, terrain effects, resources, collision, placement rules), object layers for units, buildings, machines, board slots, exits, spawns, and triggers, a QA preview with optional debug overlays, and, for decorated walkable cells, occlusion metadata plus an actor-in-place preview at the real camera.

`room_chunk_mode`: reusable chunk art or tile and object layers, chunk metadata (`chunk_id`, size, entrances and exits, sockets, spawn markers, blockers, hazards, camera bounds), collision and seam validation, and a chunk preview, plus an assembled layout preview when there are several chunks.

Side-view stages: [side-scroll.md](side-scroll.md). Prop packs: [props.md](props.md).

## Validation

Always validate what the chosen pipeline requires:

- map files exist at the expected dimensions; generated visible assets have prompt files or manifest fields
- transparent props have alpha; prop pack manifests parse and accepted props don't touch cell edges
- placement JSON parses and every referenced file exists; collision and zone JSON parse
- critical spawn, path, entrance, blocker, and zone points behave as expected
- playable and editable layered maps use a foundation-only base with no baked runtime objects
- playable stages have explicit objects or metadata for every gameplay-relevant platform or walkable lane, blocker, hazard, door, pickup, checkpoint, gate, exit, player spawn, actor spawn marker, encounter or arena trigger, and camera bound
- walkable tall props declare `occlusionClass`, `actorSafeArea`, and `occupantPolicy`, and the runtime applies that policy when an actor occupies or selects the cell
- any playable map with tall props on walkable space gets an actor-in-place preview at the real gameplay camera: the actor's head, torso, weapon or action silhouette, selection state, and path cues stay readable; slight foot overlap is fine
- `grid_mode` includes grid dimensions, cell size, cell metadata, object layers, and checks of critical walkable and buildable cells
- terrain tile bundles use portable paths, cover every declared atlas row exactly once, have the expected variant count, and pass contrast and variant-difference QC
- animated terrain overlays pass standalone FX QC and an in-engine preview: visible above the tile, not depth-clipped, behind actors, readable at gameplay zoom, safe while an actor occupies the cell
- `room_chunk_mode` includes chunk dimensions, exits and sockets, seam validation, collision, and at least one preview
- reference mockups preserve the base's dimensions, hold at most 9 distinct object candidates unless more were requested, match the final object and collision metadata, and are followed by final objects, metadata, and a QA preview
- the flattened preview looks coherent at the game's camera size
