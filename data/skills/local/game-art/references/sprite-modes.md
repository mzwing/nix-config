# Sprite modes

Use this when the request leaves room for several valid asset plans.

## Asset types

- `player`: controllable overworld hero
- `npc`: role-readable town or field character
- `creature`: monster, beast, spirit, boss, summon
- `character`: side-view or non-overworld humanoid unit that is neither the player nor an NPC
- `spell`: castable magic or skill sequence
- `projectile`: loopable traveling object such as an orb, arrow, fireball, bullet, or beam segment
- `impact`: hit burst, explosion, contact FX
- `prop`: item, weapon, shrine object, pickup, deployable
- `summon`: conjured unit or creature entrance
- `fx`: generic visual effect sheet

## Actions

- `single`: one static sprite
- `idle`: looped breathing, stance, or aura cycle
- `cast`: spell or skill wind-up and release
- `attack`: attack-only body animation; for controllable heroes and main characters, wide slash arcs and hit FX are separate `fx` and `impact` sheets
- `shoot`: ranged attack body action; the projectile and muzzle flash are usually separate assets
- `jump`: airborne takeoff, rise, fall, and landing
- `hurt`: damage reaction
- `combat`: combined attack and hurt sheet
- `walk`: travel loop
- `run`: faster travel loop
- `hover`: airborne idle or travel loop
- `charge`: power-up or dash preparation
- `projectile`: loopable travel motion
- `impact`: contact burst
- `explode`: stronger impact or destruction burst
- `death`: defeat, vanish, or collapse sequence

## Bundle presets

- `single_asset`: one sprite or one sheet
- `unit_bundle`: `idle` + `combat` by default, optionally `walk`
- `spell_bundle`: `cast` + `projectile` + `impact`
- `combat_bundle`: `idle` + `attack` + `hurt`
- `line_bundle`: 1-3 forms, each with only the sheets it needs
- `hero_action_bundle`: one sheet per action, often `idle` + `run` + `attack` or `shoot` + `jump`. Projectiles, muzzle flashes, slash arcs, weapon trails, impacts, and dust stay separate unless the runtime supports wider per-action cells with explicit origins. Body actions keep the idle and run body scale. The engine atlas is assembled only after each action passes QC.
- `engine_atlas`: a delivery format when it combines unrelated actions, built from processed action sheets, never from one mixed-action raw image

## Sheet presets

- `1x4`: projectiles and simple looping FX, never bodies
- `2x2`: standard idle, attack, hurt, impact, compact side-view walk
- `2x3`: cast and death sequences, slightly richer combat actions
- `3x3`: large creature idle, boss aura loops, high-value showcase idles
- `4x4`: top-down four-direction player walk; a non-directional 16-frame sequence when the user wants richer casting, summoning, charging, transformation, or death
- `5x5`, `custom_grid`: raw generation only for one coherent long action, prop packs, tileset-like atlases, or another single action family; as a delivery atlas for mixed actions only after each action passed QC

## Mapping hints

- "make a 4-direction main hero" → `player` + `player_sheet`
- "make a side-view hero with idle, run, shoot, and jump" → `player` + `hero_action_bundle`, one sheet per action, projectile and impact separate
- "make a side-view hero melee attack" → `player` + `hero_action_bundle`, a body-only attack grid plus separate slash and impact FX when the attack needs a wide arc
- "make a healer npc" → `npc` + `single_asset`, `role=healer`
- "make a healer npc walk sheet" → `npc` + `walk`
- "make a boss idle" → `creature` + `idle`, `3x3`
- "make a wizard throwing a magic orb" → `spell_bundle`
- "make a fireball projectile" → `projectile` + `projectile`, `2x2` or `1x4`
- "make a hit explosion" → `impact` + `impact`, `2x2`
- "make a summon entrance" → `summon` + `cast` or `impact`
- "make a full fire samurai creature line" → `line_bundle`: plan 1-3 forms, then choose sheets per form

## Processor modes

`generate2dsprite.py process` knows these legacy grid modes, among others: `player_sheet` (4-direction overworld walk, rows down, left, right, up), `player_walk` and `npc_walk` (2x2 down-facing walk), `combat` (2x2 attack plus hurt), and `evolution` (a legacy 2x2 concept sheet). Any other grid works with `--rows` and `--cols`.
