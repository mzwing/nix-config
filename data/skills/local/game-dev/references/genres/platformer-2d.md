# Genre Playbook — 2D Platformer

Jump feel and tile collision make or break a platformer. In Phaser, trust the Arcade Physics tilemap collider before hand-rolling ([phaser.md](../engines/phaser.md)); hand-rolled collision follows [collision-physics.md](../collision-physics.md).

## 1. Smallest complete scope

1. A jump with every forgiveness feature below.
2. Tile collision with no wall-sticking, floor snags, or tunneling.
3. One-way (drop-through) platforms.
4. Hazards that respawn the player at the last checkpoint, and a goal.
5. A camera that follows with a deadzone.

Skip enemy AI, wall-jump, dash, and moving platforms until jump and collision feel right. Jump feel is where the polish budget goes.

## 2. Jump feel

Do all of these; even a placeholder box then feels tight.

- Coyote time ~0.1s and jump buffering ~0.12s ([input.md](../input.md)). Allow a jump only while grounded or the coyote timer runs, and consume both timers on jump, or you get double jumps.
- Variable height: on release while still rising, multiply upward velocity by ~0.5. Setting it to 0 looks abrupt.
- Fall gravity 1.5–2.5× rise gravity, lower gravity near the apex, and a terminal fall speed. A symmetric parabola feels floaty.
- High ground acceleration and friction so direction changes are snappy; less acceleration and a little drag in the air.

## 3. Tile collision

- Ignore faces shared by two adjacent solid tiles, or merge runs of tiles into one collider; otherwise the player snags on a flat floor.
- Grounded means a downward Y resolution stopped you this frame, or a 1px probe below hits solid. Zero `velocityY` on landing and on ceiling hits.
- Sub-step movement when the player can travel more than about half a tile per frame.
- Spawn and respawn points must sit in empty space, or the player starts stuck in a tile.

## 4. One-way platforms

- Resolve only when `velocityY >= 0` and the player's previous bottom was at or above the platform's top; otherwise ignore the platform.
- Down (+ jump) disables the current one-way platform for a few frames to drop through.
- Phaser Arcade: top-only tiles with `tile.setCollision(false, false, true, false)`, or a collider `processCallback` that returns false while the player is below.

## 5. Camera

Deadzone, look-ahead, bounds, and pixel rounding are in [game-feel.md](../game-feel.md). Smooth vertical follow separately, or snap it on landing, so jumps don't bounce the camera.
