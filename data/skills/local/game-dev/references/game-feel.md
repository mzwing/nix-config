# Game Feel & Juice

On every hit, pickup, death, landing, and win, fire the whole stack: sound, particles, a short hitstop, a white flash, trauma screenshake, an easeOutBack pop or squash and stretch, and a floating number. The gameplay math stays simple; the feel comes from these layers.

## 1. Screenshake

- Offset the camera or a camera container, never the world objects.
- Use trauma squared, not linear: keep `trauma` in [0, 1], add to it on events (small hit +0.3, explosion +0.8), decay it with `trauma -= decay * dt`, and shake by `trauma * trauma` (or cubed). Small hits stay subtle and big ones read as explosive.
- Drive the position offset and a slight rotation from noise sampled over time, not a fresh random value per frame.
- Directional hits kick the camera opposite the impact instead of shaking it in every direction.
- Cap the offset so the player, targets, and HUD stay readable, and expose a screen-shake slider.

## 2. Hitstop

- On a big hit, freeze the gameplay update (or just the two entities involved) for about 30–120ms, 2–6 frames for normal hits and longer for finishers. Keep rendering so the flash and particles stay visible.
- Pair it with a 1–2 frame white flash; knockback starts after the freeze.
- Hitstop is cosmetic; hitstun (the hit character can't act) is gameplay state. Keep them separate.

## 3. Tweens and smoothing

- Tween with the engine (Phaser `this.tweens.add`), GSAP, or `@tweenjs/tween.js` rather than hand-rolling.
- Kill tweens when their target is destroyed or the scene shuts down (Phaser on `SHUTDOWN`, GSAP `.kill()`); a leaked tween writing to a dead object crashes.
- Continuous followers (camera, cursor, UI) use `x += (target - x) * (1 - Math.exp(-k * dt))`. The naive `x += (target - x) * 0.1` is frame-rate dependent and runs faster at 144Hz than at 60Hz.

## 4. Squash and stretch

- Preserve volume: scale y by `s` and x by about `1 / s`.
- Stretch on takeoff, squash on landing, and spring back with easeOutBack.

## 5. Camera

- Follow with the exp smoothing above, never a hard snap. Add eased lookahead toward movement or aim, and a deadzone box so small moves don't jitter the view.
- A quick zoom or positional punch on impact complements screenshake.
- Clamp to level bounds; in pixel-art games round the final camera position to whole pixels to stop shimmer.

## 6. Sound

- Layer each SFX: a low thump, a mid body, and a high transient.
- Randomize pitch by ±5–15% (`playbackRate`, Howler `rate`) and volume slightly on repeated sounds so rapid fire and footsteps don't sound robotic.
- Duck music briefly under big events. Playback and mixing are in [audio.md](audio.md).

## 7. Limits

- If shake, flashes, or particles hide the player, enemies, or projectiles, dial back.
- Offer toggles for screen shake, flashing, and reduced motion (honor `prefers-reduced-motion`); never strobe the full screen.
- Cap live particles; one explosion never spawns thousands.
- In multiplayer, juice runs on the client only and never touches the authoritative simulation.
