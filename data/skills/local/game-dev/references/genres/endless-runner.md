# Genre Playbook — Endless Runner

The genre rests on procedural spawning, object pooling, and a difficulty ramp. Mobile input is in [input.md](../input.md).

## 1. Smallest complete scope

1. Auto-run at a speed that rises over time.
2. Jump and slide, or lane switching.
3. Endless spawning of one obstacle type and coins, all pooled.
4. Collision means death; score is distance plus coins.
5. Instant restart and a persisted high score ([save.md](../save.md)).

Power-ups, biomes, and characters come later. Tuning the speed curve is the game.

## 2. World

- Keep the player near a fixed position and move the world toward them; spawning and distance scoring stay simple.
- Build the track from prefab segments: spawn one ahead when the last enters view, and recycle segments, obstacles, and coins once they pass behind the camera. Anything never recycled grows until the game crashes.
- Scroll ground and parallax layers by texture offset (Phaser `tileSprite` `tilePositionX`, a UV offset in 3D), or ping-pong two ground pieces, so no seam shows.

## 3. Controls

- The jump uses the platformer forgiveness timers ([platformer-2d.md](platformer-2d.md#2-jump-feel)).
- Slide and jump are timer-driven and reset on death and restart, so neither gets stuck when keys are released oddly.
- Lane switches tween between lane positions; lock input during the tween or queue one move. Support swipe and arrows or A/D.

## 4. Fairness and difficulty

- Speed rises with distance up to a hard cap; past it the player can't react and collision tunnels.
- Spawn distance scales with speed, so every obstacle leaves the same reaction time.
- The spawner always leaves a reachable gap or lane for the current speed; never emit an unavoidable combination.
- Restart resets speed, score, player state, and every pool. Leftover pooled obstacles reappearing is the classic restart bug.
