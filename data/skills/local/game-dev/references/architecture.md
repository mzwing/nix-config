# ECS & Game State Architecture

## 1. ECS or plain objects

- Small games, jams, prototypes, and games with a few entity types use a plain object list or the engine's own objects; ECS there is boilerplate.
- Reach for ECS when there are thousands of similar entities (bullet hell, RTS, .io games, simulations) or capabilities combine freely (many mix-and-match behaviors and status effects).
- An engine's own model wins: Bevy is ECS-native, Godot is a node tree with scripts, Unity has GameObjects (and DOTS for ECS), libGDX has scene2d and the Ashley ECS. The library choice below is for three.js, Phaser, and plain canvas.

## 2. Libraries

- Default to miniplex in JS and TS (plain objects, good TypeScript and React bindings). Add and remove components with `world.addComponent` and `world.removeComponent`; setting a property directly skips query re-indexing.
- Switch to bitECS for tens of thousands of entities or SoA performance. Its API changed in 0.4: tutorials using `defineComponent`, `defineQuery`, and `Types` don't match current releases (`createWorld`, `query(world, [...])`), so read the installed version's docs before writing it.

## 3. State

- Keep one serializable source of truth (a world object or ECS world), not data scattered across the DOM, closures, and globals; save, undo, and netcode depend on it.
- Gameplay data stays separate from meshes and sprites; a sync step pushes data to the view each frame.
- Run systems in an explicit order every tick: input → AI → movement → collision → damage → cleanup → render sync.
- Queue spawns and despawns and apply them between systems; changing structure mid-iteration skips or repeats updates.
