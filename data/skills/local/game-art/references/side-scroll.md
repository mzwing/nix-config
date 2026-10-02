# Side-scroll stages

Playable side-view stages: action platformers, runners, shooters, brawlers, Metroidvania side rooms, and Mega Man-, Castlevania-, or Contra-like levels, in pixel art, clean HD, or a project's own style. The pipeline is `parallax_layers` + `platform_objects` + `interactive_scene_objects` + `scene_hooks` + `precise_shapes`, unless the engine already requires a tilemap. A stage is long because its runtime object layout is long, not because one panoramic picture is.

## Decide before generating

- `stage_canvas`: one canvas shared by every segment, primary parallax plate, stage reference, stage preview, and normalization target. Use the project's camera or viewport aspect, or `1536x864` (16:9) when unknown. The image model returns its own sizes, so normalize each plate to the canvas by deterministic resizing, cropping, or padding; that may fix sizes, never invent missing art.
- `stage_segment_count`: 2 camera-width segments by default for a normal playable level; 1 only for explicit one-screen rooms, boss arenas, fixed battle rooms, title-like scenes, or background-only requests; 3 or more only when the user asks for a longer stage or the game already has that scope.
- `stage_length`: the camera width times the segment count, or the engine's existing world width.
- `platform_strategy`: `platform_rects_with_shared_tiles` by default. Platform rectangles or engine-native platform objects are the gameplay source of truth, skinned with a shared generated library of strips, tiles, or terrain chunks. A generated background or a generic prop pack never defines platform shape.

Never ask the image model for one ultra-wide level. Name segments predictably (`segment-01`, `segment-02`), keep each aligned to the same top-left camera frame, and record whether parallax plates are per segment or loopable; don't mix sizes or aspect ratios across segments.

## Parallax plates

Generate the scenery as named, separate runtime images, each a scenery-only depth plate that runtime objects stack over:

- `sky`: sky, moon or sun, far atmosphere; scroll factor near 0.0-0.1
- `far_bg`: mountains, skyline, far castle or factory silhouettes; slow scroll
- `mid_bg`: readable landmarks and large distant structures; medium scroll
- `near_bg`: near non-colliding scenery behind gameplay objects; faster scroll, still no collision
- `foreground_overlay`, optional: fog, chains, pipes, silhouettes, smoke, or framing that draws over actors without defining collision

Files: `assets/map/<name>-sky.png`, `-far-bg.png`, `-mid-bg.png`, `-near-bg.png`, and `-foreground-overlay.png`. Don't collapse them into one `<name>-background.png` unless the user explicitly wants a flat, non-parallax background; even then, continue with the stage reference, separate objects, collision, camera bounds, and preview.

Every primary plate prompt states the same canvas size and aspect, camera framing, horizon height, and top-left aligned composition. Plates may contain sky, clouds, mountains, distant buildings and castle walls, silhouettes, smoke, weather, and non-colliding far depth, and they keep the playable foreground lane open or neutral. They never contain walkable floors, platform tops, terrain chunks, ladders, spike traps, pickups, crates, doors, gates, checkpoints, near fences or walls, foreground barricades, enemies, players, UI, labels, or anything to be edited, collided with, reused, or layered on its own. Reject a plate with collidable-looking foreground geometry and regenerate it cleaner. Repeatable strips and foreground sprites may have other source sizes when their metadata declares display size, anchor, scale, repeat axis, and loop policy; they never replace the primary plates.

## Stage reference

A stage reference is mandatory before any final scene object or metadata. If a run has a background but no `assets/map/<name>-stage-reference.png`, pause the platform and prop work and generate it next; background plus props doesn't prove the layout is coherent.

1. Pass the background with `--image`, look at it, and ask for an in-world stage reference that preserves its exact camera, framing, dimensions, horizon, depth, entrances, and exit direction ([maps.md](maps.md#reference-mockups)).
2. Place the intended layout as natural game-world objects or subtle blockout geometry: platforms or walkable lanes, terrain chunks, foreground occluders, hazards, pickups, doors, checkpoints, gates, exits.
3. At most 9 distinct visible object candidates unless the user asks for a larger pass; repeats count once and recur in metadata. Prioritize objects the game renders or collides with separately over small decorative props that will never become assets.
4. No spawn or actor markers, arena trigger zones, camera bounds, arrows, labels, circles, outlines, numbered callouts, text, legends, or UI; those become scene-hook metadata.
5. Use the reference to decide object identities, sizes, coordinates, render order, collision shapes, and camera bounds, then continue through [maps.md](maps.md#after-the-mockup).

Multi-segment stages may have one reference per segment, all reusing the same object library and camera frame; when time or cost allows only one, it becomes the style and layout reference for the shared library and each segment gets its own placement metadata. The stage reference is never the runtime map, never a collision source, and never a sheet to cut platforms from.

## Shared object library

Before decorative props, generate or select one structural library for the whole stage ([props.md](props.md)):

- `platform_strip_1x3`: left cap, seamless middle, right cap
- `platform_strip_1x4`: the same plus a slope, corner, broken, or end piece
- `platform_tile_set`: tiles for top edge, underside, wall face, corner, and optional slope when the target is tile-based
- `custom_terrain_chunk`: one-by-one or custom wide assets for important unique terrain

Reuse it across all segments; no fresh unrelated prop pack per segment unless the user asks for biome changes. Platform objects in metadata reference the library by id and declare display width and height, anchor, repeat policy, collision rectangle, and render layer. Floors, ledges, bridges, ladders, walls, slopes, long spike rows, and terrain chunks never go into square prop packs.

## Runtime geometry

The art skins the metadata; it never defines it. Store:

- `platforms`: rectangles, tile spans, slopes, one-way ledges, moving-platform handles, or engine-native platform nodes
- `terrain_chunks`: optional large reusable solids where rectangles aren't enough
- `hazards`: spikes, lasers, lava strips, pits, saws, traps, other collision-critical objects
- `interactives`: doors, gates, terminals, switches, checkpoints, pickups, exits, destructibles
- `scene_hooks`: player spawn, actor spawn markers, camera bounds, lock zones, arena triggers, exit links, checkpoint ids

Brawlers replace jump platforms with a walkable belt polygon, plus depth props, enemy wave zones, and camera locks. Simple collision rectangles skinned with repeated cap and middle sprites, as in classic tile and strip workflows, beat any generated foreground layout.

## Deliverables

- the parallax plates and their prompt files, all matching the recorded `stage_canvas`
- recorded `stage_canvas`, `stage_segment_count`, `stage_length`, and per-segment or loopable plate metadata with consistent sizes and anchors
- `assets/map/<name>-stage-reference.png`
- the shared library and separate generated platform, terrain-chunk, foreground-occluder, hazard, door, pickup, checkpoint, gate, and exit sprites
- `data/<name>-objects.json` or engine-native object layers, grouped by segment when there are several
- `data/<name>-scene-hooks.json` or engine-native metadata for spawns, actor spawn markers, triggers, camera bounds, and exit links
- `data/<name>-collision.json` with explicit platform and solid geometry independent of the background pixels
- `assets/map/<name>-stage-preview.png` composed from the background plus objects, per segment and, when practical, as a stitched overview, for QA only
- code or scene changes that load the plates, render the object layers, and use the collision and object data as gameplay data

Not acceptable as a playable stage: one generated stage image plus collision rectangles (a background with hitboxes), or one camera-width scenery image as a whole scrolling level unless the user asked for a one-screen room. Runtime `background` fields point to scenery-only plates, never to `stage-reference` or `stage-preview`.

## Validation

- the primary plates, stage references, and previews match `stage_canvas` exactly
- `stage_segment_count`, `stage_length`, segment ids, and the per-segment or loopable choice are recorded; normal playable levels have at least 2 segments
- the plates have explicit render order, scroll factors, dimensions, and loop policy, and none is a collision source
- platforms and terrain use explicit metadata plus the shared library, never a square prop pack
- the stage reference's object plan matches the final object and collision metadata
