---
name: game-dev
description: Build games and real-time interactive scenes in any engine (three.js, Phaser, Babylon.js, Godot, Bevy, Unity, libGDX, plain canvas). Covers the game loop, controls and camera, collision, game feel, input, audio, saves, procedural generation, AI, architecture, multiplayer, and genre playbooks. Use when making, fixing, or reviewing a game or playable prototype.
---

# Game dev

Build a playable, correct game, not a screenshot of one. Work in the project's engine and language. This file holds what is true in every engine; each reference says where it turns browser- or engine-specific.

## Engine

Use the engine the project already has, and read its current docs instead of relying on memory. For a new browser game: Phaser for 2D ([engines/phaser.md](references/engines/phaser.md)), three.js for 3D ([engines/three.md](references/engines/three.md)), Babylon.js when you want physics, GUI, and an inspector built in ([engines/babylon.md](references/engines/babylon.md)). Plain canvas is enough for snake, tetris, flappy, or a simple platformer. Use the engine's own physics, tilemaps, animation, input actions, and audio buses before hand-rolling them.

## Before writing gameplay

- Movement, steering, flight, or camera code: read [references/controls.md](references/controls.md) first. Three rules hold everywhere:
  1. Player-visible left and right are law: with the camera behind the player moving forward, A or ← turns left on screen and D or → turns right.
  2. Vehicle steering is a yaw rate, not FPS strafe. In a right-handed Y-up engine (three.js, Godot, Bevy), `A → steer = −1` followed by `yaw += steer * rate` ships with A turning right.
  3. Prove the signs with a control self-test before calling it done; a screenshot can't show a sign error.
- If a playbook in `references/genres/` matches, read it: it gives the smallest complete scope and the genre's classic bugs.

## Loop and timing

- Drive the game from the engine's frame callback (`requestAnimationFrame` or `setAnimationLoop`, Phaser `update`, Godot `_process` and `_physics_process`, Bevy systems). Never time gameplay with `setInterval`, `setTimeout`, or wall-clock reads.
- Scale all movement and animation by delta time in seconds, computed once per frame and reused. Check the unit: Phaser passes milliseconds.
- Cap delta at about 0.1s so a hitch or a background tab doesn't teleport everything.
- Step physics and gameplay on a fixed timestep: accumulate delta, step at 1/60s, render at display rate, and interpolate between the last two states. This prevents tunneling and keeps the simulation deterministic.
- Keep simulation separate from presentation: screenshake, tweens, and particles never change outcomes.

## World and camera

- Know the engine's handedness, up axis, and forward axis before writing orientation math; the table is in [controls.md](references/controls.md#coordinate-systems).
- Compute `forward` and `right` once per frame and share them between movement and camera; camera code never mutates them.
- Debug controls in order: keys register, then movement signs are right, then the camera agrees.
- In 3D, characters stand upright on the ground, not lying down or sunk in.

## Performance

- Pool things that spawn often (bullets, enemies, particles, floating text); no allocations in per-frame code.
- Keep draw calls down: share materials, instance repeated objects, pack sprites into atlases.
- Free GPU resources when leaving a level if the engine doesn't (three.js and Babylon.js don't).
- Add a broadphase before precise collision tests once there are many colliders.

## Assets

- Interactive 3D things (characters, weapons, props, projectiles) are geometry or glTF models; a flat picture standing in for a 3D object looks wrong and can't animate.
- Abstract games (tetris, snake, pong, breakout) are drawn procedurally; decorative sprites make them worse.
- Menus, HUD, and overlays follow the design-ui skill.

## Platform

- Browser: audio starts only after a user gesture, so open with a "click to play" screen that also unlocks pointer lock and fullscreen ([audio.md](references/audio.md)).
- Saves carry a version number and migrations from the first release ([save.md](references/save.md)).
- Mobile: separate the render buffer size from the display size and respect the pixel ratio; touch targets of at least 44px; handle orientation.

## Done means

- It loads without errors and shows gameplay, not a blank screen.
- The control self-test passed.
- In 3D, objects stand upright and the camera agrees with movement.
- It holds its frame rate on the weakest target device, with touch controls where the platform needs them.
- A release build runs, not just the dev server.

## References

| Need | Read |
|---|---|
| Movement, steering, flight, camera signs, control self-test | [controls.md](references/controls.md) |
| Collision, tunneling, physics engines, character controllers | [collision-physics.md](references/collision-physics.md) |
| Screenshake, hitstop, easing, particles, camera feel | [game-feel.md](references/game-feel.md) |
| Action mapping, keyboard, pointer, touch, gamepad, buffering | [input.md](references/input.md) |
| Sound, mixing, latency, spatial audio | [audio.md](references/audio.md) |
| Storage, save versioning, autosave | [save.md](references/save.md) |
| Seeded randomness, noise, dungeons, mazes, WFC | [procedural-generation.md](references/procedural-generation.md) |
| Pathfinding, steering, state machines, behavior trees | [ai-pathfinding.md](references/ai-pathfinding.md) |
| Entities and game state, ECS or plain objects | [architecture.md](references/architecture.md) |
| Co-op and realtime multiplayer | [multiplayer.md](references/multiplayer.md) |
| Board and card, endless runner, FPS, platformer, match-3 and tetris, racing, twin-stick, tower defense, voxel | `references/genres/` |
| three.js and React Three Fiber, Phaser, Babylon.js | `references/engines/` |
