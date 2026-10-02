# Sprites

Self-contained 2D sprite and animation assets: players, NPCs, creatures, spells, projectiles, impacts, props, summons, and FX. When a larger game needs sprites, make the visible assets here and keep runtime assembly separate; never replace requested sprites with code-drawn placeholders.

## Parameters

Infer these from the request, and read [sprite-modes.md](sprite-modes.md) when it leaves room for several plans:

- `asset_type`: `player` | `npc` | `creature` | `character` | `spell` | `projectile` | `impact` | `prop` | `summon` | `fx`
- `action`: `single` | `idle` | `cast` | `attack` | `shoot` | `jump` | `hurt` | `combat` | `walk` | `run` | `hover` | `charge` | `projectile` | `impact` | `explode` | `death`
- `view`: `topdown` | `side` | `3/4`
- `sheet`: `auto` | `2x2` | `2x3` | `2x4` | `3x3` | `3x4` | `4x4` | `5x5` | `custom_grid` | `strip_1x3` | `strip_1x4`
- `frames`: `auto` or an explicit count
- `bundle`: `single_asset` | `unit_bundle` | `spell_bundle` | `combat_bundle` | `line_bundle` | `hero_action_bundle` | `engine_atlas`
- `effect_policy`: `all` | `largest`
- `anchor`: `center` | `bottom` | `feet`
- `scale_strategy`: `fit` | `preserve`
- `scale_profile`: `none` | `create_from_accepted_action` | `reuse_existing`
- `margin`: `tight` | `normal` | `safe`
- `art_style`: `pixel_art` | `clean_hd` | `pixel_inspired` | `retro_pixel` | `map_style` | `project-native`
- `reference`: `none` | `attached_image` | `generated_image` | `local_file`
- `layout_guide`: `none` | `geometry` | `character_anchor`
- `runtime_contract`: `none` | `godot_sprite3d`
- `world_height`: the in-engine subject height when a runtime contract is requested
- `prompt`: the user's theme or visual direction
- `role`: only when the asset is clearly an NPC role
- `name`: an optional output slug

## Plan the sheets

Decide the plan yourself; don't make the user spell out sheet size, frame count, or bundle structure that the request already implies. Pick the smallest useful output:

- controllable hero with four directions → `player` + `player_sheet`
- side-view hero with idle, run, shoot, and jump → `player` + `hero_action_bundle`: idle `2x2`, run `2x2` or `2x3` by frame count, a body-only shoot `2x2`, jump `2x2`, projectile and muzzle flash as separate assets, and an engine atlas assembled only after per-action QC
- side-view hero with a melee attack → `player` + `hero_action_bundle`: a body-only attack `2x2` or `2x3`, a separate `fx` sheet for a wide slash arc or weapon trail, a separate `impact` sheet for hit sparks
- healer NPC on the overworld → `npc` + `single_asset` or `unit_bundle`
- large boss idle loop → `creature` + `idle` + `3x3`
- wizard throwing a magic orb → `spell_bundle`: caster cast sheet, projectile loop, impact burst
- monster line → `line_bundle`: plan 1-3 forms, then only the sheets each form needs

Rules for every plan:

- A raw sheet holds one action family, one continuous sequence, one canonical directional locomotion sheet, or one prop pack. Never pack unrelated actions (row 1 idle, row 2 run, row 3 shoot) into one raw sheet to satisfy a `4x4`, `5x5`, or custom atlas: generate and QC each action separately, then assemble the delivery atlas deterministically. The exceptions are directional locomotion, one long sequence, prop packs, tileset-like atlases, and low-stakes compact enemy combat sheets, and they still need one coherent prompt and visual QC.
- Animated bodies (players, heroes, creatures, NPCs, enemies, summons, animated props, body-attached combat actions) never use raw single-row sheets such as `1x4` or `1xN`: they drift horizontally and crop inconsistently. Use multi-row grids: 4 frames → `2x2`, 6 → `2x3`, 8 → `2x4`, 9 → `3x3`, 12 → `3x4` or `4x3`, 16 → `4x4`. When the engine wants a strip, assemble it from the processed grid frames after QC.
- Attack, shoot, and cast sheets for controllable heroes and main characters are body-only. Slash arcs, muzzle flashes, projectiles, impact bursts, dust, long trails, and other wide FX are separate `fx`, `projectile`, or `impact` sheets layered in the game, because a wide FX bounding box forces the body to shrink inside a fixed cell. "Tightly attached" isn't enough when the effect makes the action much wider or taller than idle and run. Keep FX in the body sheet only when the runtime supports wider per-action cells with per-action origins. When an integrated weapon must stay and there is no FX layer, process with `--scale-strategy preserve --align feet`.
- Elongated quadrupeds, serpentine creatures, and actors whose tail or attack nearly fills a cell get a shared-silhouette-envelope contract in every action prompt: the torso center stays fixed, every pose stays inside the same central 70-72% box, tails and long appendages tuck inward, and pounces and bites show as in-place compression and extension rather than travel across the cell. "Generous margin" alone doesn't contain these silhouettes.
- Massive grounded bosses keep feet and pelvis locked in idle. Weight shows through vertical torso compression, a core pulse, shoulder settling, and delayed secondary motion of attached ornaments, never whole-body sway.
- Ground-contact FX such as fire get one explicit ignition baseline written into the prompt and no baked ground plate. Tip height is animation; the contact line doesn't move.
- High-value grounded player and hero actions get a character anchor sheet when scale or feet placement must match (below).
- A multi-action character uses one scale profile, written from an accepted idle or run sheet and applied to every grounded body action; never pick a new `--fit-scale` per action.
- Map props are classified before a grid is chosen ([props.md](props.md)). Square `2x2`, `3x3`, and `4x4` packs hold compact props only; platforms, floors, bridges, walls, ladders, gates, doors, long hazards, wide or tall props, collision-bearing objects, and strip pieces go one by one, as `1x3` or `1x4` strips, or in custom wide cells. A pack that fails on edge touches is reclassified and regenerated, not passed by loosening QC.

## Write the prompt

Write every prompt yourself, following [sprite-prompts.md](sprite-prompts.md). The processor's `build-prompt` command is legacy, not the workflow.

Choose `art_style` first:

- `pixel_art` or `retro_pixel`: classic sprites, 16-bit RPG actors, explicit pixel-art requests
- `clean_hd`: map props and assets that must match clean hand-painted HD maps
- `pixel_inspired`: a pixel-adjacent look without retro chunkiness
- `map_style` or `project-native`: an existing map, game, or reference defines the style

Don't force pixel art on a map prop or on a project with another style.

With a reference (an attached image, an earlier generation, a local file), pass it with `--image` and look at it yourself. State its role: preserve identity and style, an animation sheet of the same subject, an evolution or variant, or a matching prop or FX. Preserve its identity markers (silhouette, palette, face and eyes, costume marks, major accessories, material language) and let only the requested action or evolution change.

Every sprite prompt keeps:

- a solid `#FF00FF` background
- the exact sheet shape
- the same identity in every frame
- the same camera distance and standing-equivalent anatomical scale across body frames: pose bounding boxes may change naturally, but the model must not zoom individual poses
- containment: nothing crosses a cell edge
- for animated body grids: the body centered in each cell inside the central 60-70% safe area, a stable feet line, and no limb, weapon, hair, cape, dust, flash, or detached FX crossing a cell edge
- for hero attacks: body height and scale matching the accepted idle and run sheets, a stable feet anchor, the weapon close enough not to widen the bounding box, and no detached slash arc or screen-space effect

## Layout guides and anchor sheets

A layout guide is a geometry-only reference for slot count, spacing, centering, and safe padding; it never sets art direction.

```bash
scripts/make_layout_guide.py --rows <rows> --cols <cols> --cell-width 384 --cell-height 384 --output <run-dir>/references/<rows>x<cols>-layout-guide.png
```

Pass it with `--image` and tell the model to use it only for the invisible slots, spacing, centering, and padding, reproducing none of its boxes, safe-area rectangles, center marks, labels, borders, or background.

- Recommended for `3x3` and `4x4` prop packs, tileset-like atlases, fixed multi-row animation grids, and non-directional 16-frame sequences (cast, summon, charge, death, transformation).
- Optional for `3x3` large idles and showcase loops after a run drifted in scale, spacing, or edge safety.
- Not the default for `4x4` four-direction walks, where the guide makes the poses too conservative; use it only after an unguided run fails layout or edge safety.

For grounded high-value character actions a character anchor sheet beats abstract boxes. After accepting a neutral or idle master frame, repeat it at the intended size and feet line in every cell:

```bash
scripts/make_anchor_layout.py --input <accepted-master-frame.png> --rows 2 --cols 3 --cell-width 512 --cell-height 512 --subject-height-ratio 0.66 --feet-ratio 0.82 --output <run-dir>/references/attack-anchor-2x3.png
```

Pass the master frame as Image 1 (identity, style, anatomy, camera, materials) and the anchor sheet as Image 2 (slot positions, camera distance, standing-equivalent scale, body root, feet line, padding), and ask for new poses only, with no guides, borders, labels, or separators. Not for jumps, falls, knockback, flying, projectiles, impacts, creatures whose attack reshapes their silhouette, or FX that change scale on purpose.

## Generate

Use `scripts/imagegen.py generate` for a sheet from text alone and `edit` when a reference, guide, or anchor sheet is involved. Keep raw images in the run directory and never overwrite an accepted one.

## Process

`scripts/generate2dsprite.py process` is a deterministic processor: magenta cleanup, cell split, component filtering, scaling, alignment, QC metadata, transparent sheet, frames, and GIF. Its flags are primitives you choose per sheet, not a fixed workflow. `--target` is `player`, `npc`, `creature`, or `asset` (map spells, props, and FX to `asset`); `--mode` is a known grid mode, or any label together with `--rows` and `--cols`; `single` processes one sprite. `scripts/generate2dsprite.py list-options` prints the known values.

- `--shared-scale` for any multi-frame asset where frame-to-frame consistency matters.
- `--align feet` or `bottom` for grounded actors, `center` for floating effects, projectiles, and detached FX.
- `--component-mode largest` for body-only hero grids and raw sheets with stray sparkles or edge debris; `all` for projectile, impact, aura, slash, and intentionally detached FX sheets.
- `--scale-strategy preserve --align feet` for grounded hero and player sheets whose raw scale is right but which bbox-fit would shrink (a long sword, spear, staff, gun, or cape, an extended pose, an integrated melee effect). It applies one uniform raw-cell scale and safety margin to every frame, then moves each subject to the shared anchor; it never fits each frame separately. The default `fit` suits compact bodies, creatures, projectiles, impacts, and FX that should be normalized. Preserve is not a blind default for floating FX or projectiles.
- Process each action of a bundle as its own sheet before assembling any atlas.

A multi-action character writes one scale profile from the accepted reference action:

```bash
scripts/generate2dsprite.py process --input <accepted-run-raw.png> --target player --mode run --rows 2 --cols 3 --output-dir <run-dir> --cell-size 128 --fit-scale 0.80 --align feet --scale-strategy preserve --component-mode largest --strict-qc --write-scale-profile <bundle>/character-scale-profile.json --profile-name <character-name> --max-profile-scale-drift 0.08
```

Later actions pass `--scale-profile <bundle>/character-scale-profile.json`. Its values override each command's scale, anchor, trim, and component settings, so no action gets its own magnification. Keep the same raw grid geometry, generation size, master image, and anchor sheet across actions: the anchor sheet controls the model, the profile controls postprocessing, and neither repairs an anatomy-scale change the model made.

Godot `Sprite3D` targets request a world-height contract instead of tuning each action in the game:

```bash
scripts/generate2dsprite.py process --input <raw-sheet.png> --target player --mode idle --rows 2 --cols 3 --output-dir <action-dir> --cell-size 256 --fit-scale 0.84 --align feet --scale-strategy preserve --component-mode largest --strict-qc --max-body-scale-cv 0.08 --max-anchor-y-std 0.05 --duration 125 --godot-world-height 0.70
```

This writes `godot-sprite3d.json` beside the frames. The reference action derives `recommended_pixel_size` from the measured mean subject height and stores it in the scale profile; later actions processed with that profile reuse the exact pixel size, so crouching, recoil, hurt, and creature silhouette changes stay real pose changes instead of being normalized back. The contract also converts the shared output origin to `Sprite3D.offset`, lists the frames, and records timing. Use the same `world_height` and profile for every compatible action, then bundle them once all pass QC:

```bash
scripts/generate2dsprite.py build-godot-bundle --action idle=<bundle>/idle/godot-sprite3d.json --action move=<bundle>/move/godot-sprite3d.json --action attack=<bundle>/attack/godot-sprite3d.json --action hurt=<bundle>/hurt/godot-sprite3d.json --default-action idle --one-shot attack --one-shot hurt --output <bundle>/godot-sprite3d-bundle.json
```

The bundle validates world height and `pixel_size` across actions, stores relative contract paths, and marks loops and one-shots (attack, hurt, death). A drift failure is a generation or wrong-profile error; never compensate with per-action runtime scale.

### Keying edge cases

- Soft painted edges that keep a magenta fringe: run `scripts/chroma_key.py --input <raw> --output <keyed>` first (add `--edge-contract 1` for a stubborn fringe), then process the keyed image.
- Magenta or pink in the subject itself: generate on another flat key such as `#00FF00`, key it with `scripts/chroma_key.py --key-color '#00ff00'`, then process with `--threshold 0 --edge-threshold 0 --edge-clean-depth 0` so the processor's magenta key leaves the pink alone.

## QC

Check every processed sheet:

- frames touching cell edges
- frames resized differently than intended
- detached effects turned into noise
- whether the sheet still reads as one coherent animation
- hero and player body actions within about 10-15% of the accepted idle and run body height; in a fixed-cell runtime, reject a body shrunk by a weapon trail or FX arc even when `edge_touch_frames` is empty
- preserve-scale runs: feet aligned and no `paste_clamped_frames`
- grounded high-value body sheets: `qc_summary.body_scale_cv` at or below about 0.08 and `qc_summary.anchor_y_std` at or below about 0.05
- rooted boss idles: feet and pelvis fixed, motion only from compression, glow, shoulders, and attached elements
- ground-contact FX: a stable ignition line while flame tips, embers, and height change
- multi-action bundles: `qc_summary.profile_body_scale_drift` within the profile limit, normally 0.08

When a check fails, rerun with different processor settings or regenerate the raw sheet.

Grounded high-value humanoid body actions run strict QC after generation-side scale control:

```bash
scripts/generate2dsprite.py process --input <raw-sheet.png> --target player --mode attack --output-dir <out-dir> --rows 2 --cols 3 --align feet --scale-strategy preserve --component-mode largest --strict-qc --max-body-scale-cv 0.08 --max-anchor-y-std 0.05
```

- These gates are for grounded humanoid body actions only, not jumps, knockback, projectiles, impacts, floating actors, creatures whose attack reshapes their posture, or FX that change scale on purpose. A failed gate means regenerate; never hide generation drift with per-frame scale normalization.
- Strict QC separates raw source-cell contact from processed output contact. Regenerate when a body part is visibly clipped. When you have looked and the raw subject is complete, with only an antialiased or harmless contour touching the source cell, `--allow-source-edge-touch` passes it; it never permits output-edge contact, clamped pastes, or empty frames.
- Elongated creature attacks with any `paste_clamped_frames` or `output_edge_touch_frames` are regenerated with the shared-silhouette-envelope contract. Use the source-edge override only after both counts are zero and the snout, paws, weapon, wings, and tail are visibly intact.
- Ground-contact FX may use `--component-mode largest` when detached embers would corrupt the contact anchor, and a looser action-specific `--max-anchor-y-std` only after you have confirmed a fixed baseline, no output-edge contact, no clamping, and correct in-engine placement. Don't loosen the grounded-character defaults globally.
- Cross-action profile drift: keep legitimate crouch, recoil, and compressed poses, look at borderline hurt and knockback sheets yourself, and reject unexplained drift in idle, run, walk, and grounded attacks.

## Deliverables

A single sheet's output directory holds `raw-sheet.png`, `raw-sheet-clean.png`, `sheet-transparent.png`, the frame PNGs, `animation.gif`, `prompt-used.txt` (when `--prompt` or `--prompt-file` is given), and `pipeline-meta.json`, plus `godot-sprite3d.json` when `--godot-world-height` is set. A `single` sprite produces `raw.png` and `clean.png` instead.

- `player_sheet`: the transparent 4x4 sheet, 16 frames, four direction strips, and four direction GIFs
- `spell_bundle`, `unit_bundle`: one folder per asset
- `hero_action_bundle`: a raw and processed sheet per action, per-action frames and GIFs, separate projectile, muzzle, slash, and impact assets when needed, one shared `character-scale-profile.json` for grounded body actions, and an assembled `engine-atlas-transparent.png` only after per-action QC
- Godot multi-action unit: per-action contracts plus a validated `godot-sprite3d-bundle.json`

## Defaults

- `idle`: `2x2` for small and medium actors, `3x3` for large creatures and bosses
- `cast`, `death`: `2x3`
- `projectile`: `2x2` for short loops; `1x4` only when the engine wants a strip
- `impact`, `explode`: `2x2`
- `walk`: `4x4` for a top-down four-direction actor, `2x2` for a side view
- `4x4`, `5x5`, custom grids: raw generation only for one long action, directional locomotion, prop packs, and tileset-like atlases; as delivery atlases for mixed actions only after each action passed QC
