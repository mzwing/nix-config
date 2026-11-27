# Genre Playbook — Top-Down / Twin-Stick Shooter

Move with one input, aim with another. Virtual joysticks, deadzones, and the action layer are in [input.md](../input.md).

## 1. Smallest complete scope

1. Independent move and aim vectors.
2. One weapon with pooled bullets and a fire-rate cooldown.
3. One enemy type that spawns in waves and chases the player, with a hit reaction and a death.
4. Collision: player vs walls, bullets vs enemies, enemies vs player, arena bounds.
5. A health and score/wave HUD, game over, and restart.

Pickups and upgrades come after this loop is fun.

## 2. Controls and aiming

- Never couple facing to movement; that is tank control, not twin-stick.
- The aim angle is `atan2` from player to cursor in world space: convert the pointer through the camera's scroll and zoom first, or aim drifts as the camera moves.
- Gamepad: left stick moves, right stick aims and fires once past the deadzone. Mobile: two virtual sticks, auto-firing while the aim stick is held.
- Normalize the move vector before scaling by speed, or diagonals are ~1.41× faster.
- Rotate the sprite to the aim angle, not the move angle. Phaser sprites face +X at 0 rad, so draw art facing right or offset the angle; in 3D use the forward axis from [controls.md](../controls.md#coordinate-systems).
- Camera look-ahead leans partway toward the cursor, so the player sees where they shoot.

## 3. Bullets and enemies

- Pool bullets and enemies; bullets despawn on wall hit, enemy hit, TTL, or leaving the screen.
- Circle-vs-circle overlap for bullets vs enemies, and a spatial hash once counts are high ([collision-physics.md](../collision-physics.md)).
- Enemy AI is seek plus separation ([ai-pathfinding.md](../ai-pathfinding.md)); without separation, enemies stack into one sprite.
- Spawn waves off-screen at the arena edge, never on the player, with rate and count rising over time; cap concurrent entities on mobile.
- Player and enemy bullets differ clearly in color and size so the player can dodge.
- Hit flash, knockback, hitstop, and shake come from [game-feel.md](../game-feel.md).
