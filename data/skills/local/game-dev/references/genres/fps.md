# Genre Playbook — First-Person Shooter (FPS)

Mouse look, pointer lock, pitch clamp, and yaw-only movement are in [controls.md](../controls.md); the three.js rig is in [three.md](../engines/three.md#first-person-controls). This file adds the weapon, the shooting model, and FPS-specific bugs.

## 1. Smallest complete scope

1. Mouse look and WASD movement with pointer lock.
2. One hitscan weapon with a crosshair, muzzle flash, and hit feedback.
3. 3–8 targets or simple enemies with a hit reaction and a death.
4. A HUD with hit indicator, ammo, and score.
5. A bounded arena with cover and a capsule character controller ([collision-physics.md](../collision-physics.md)), so you can't walk through geometry.

Leave pathfinding AI, inventories, reload animations, and netcode out of a first build.

## 2. Look and movement

- Request `requestPointerLock({ unadjustedMovement: true })` for raw aim, and fall back to a plain lock when the promise rejects with `NotSupportedError`.
- Attach the look handler only while locked, so a paused game doesn't rotate.
- Vertical FOV 75–90°, adjustable. Aiming down sights lowers FOV and scales sensitivity down by the same ratio.
- Head-bob follows distance travelled, not time, so it stops when idle.
- iOS and most mobile browsers have no pointer lock: provide touch look and a fire button instead of requiring it.

## 3. Viewmodel

- Never a flat photo of a gun on a screen-aligned quad: build it from a few primitives or load a glTF model.
- Parent it to the camera at about `(0.3, -0.3, -0.6)`; the camera looks down −Z, so the gun sits at negative Z.
- Draw it in a second pass (overlay scene and camera, `renderer.autoClear = false`, `renderer.clearDepth()` between passes) or on its own layer, so it never clips into walls.

## 4. Shooting

- Hitscan from the screen center: `raycaster.setFromCamera({ x: 0, y: 0 }, camera)`, nearest hit. Raycasting from the mouse position misses the crosshair.
- Projectiles only for slow or arcing weapons, pooled and sweep-tested against tunneling ([collision-physics.md](../collision-physics.md)).
- Gate fire with a cooldown timer (`now - lastShot >= fireInterval`), with hold-to-fire as a flag set on mouse down and up. Firing per frame empties the magazine instantly at 144Hz.
- Recoil kicks pitch and yaw and recovers over time; spread is a random cone that grows while firing and shrinks when idle.
- Confirm every hit in the same frame with a hitmarker and a hit sound; the rest of the feedback stack is in [game-feel.md](../game-feel.md).
