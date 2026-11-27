# Phaser 3 / 4

Phaser is the default for 2D browser games. This file assumes the general loop, mobile, and performance rules in [SKILL.md](../../SKILL.md).

Phaser 3 (3.90+) is the mature line. Phaser 4 (2025) rewrote the WebGL renderer and stays nearly API-compatible: the scene lifecycle, Arcade and Matter physics, Scale Manager, loader, and game object APIs below carry over. Prefer 3.90.x for plugin compatibility and Phaser 4 for its faster renderer when a younger ecosystem is acceptable; either way, write against the v3 API, which runs on both.

## 1. Scenes

```js
class GameScene extends Phaser.Scene {
  constructor() { super('game'); }
  init(data) {}          // runs on every start: reset per-run state here
  preload() {}           // queue loads only; assets are ready in create
  create(data) {}
  update(time, delta) {} // delta in ms
}
```

- **Scenes boot once and start many times.** State set in the constructor or at module level survives a restart (instant game over, carried-over score); reset it in `init()`.
- Shutdown destroys the scene's display list, tweens, timers, and input, but not external references, DOM listeners, subscriptions on cross-scene emitters, or pooled arrays. Clear those in `this.events.once('shutdown', cleanup)`; a destroyed object still subscribed to an emitter is a classic crash.
- Default stack: Boot (loading-screen assets) → Preload (progress bar) → Menu → Game, with a UI scene launched in parallel over Game and Pause or GameOver as overlay scenes.
- Share state through `this.registry` and one shared `Phaser.Events.EventEmitter` module rather than `this.scene.get('ui')`, and `off()` listeners on shutdown. Pass one-shot data with `this.scene.start('game', { level: 3 })`; it arrives in `init(data)` and `create(data)`.

| Method | Target | Caller |
|---|---|---|
| `start('k')` | stops, then starts k | **stops** |
| `launch('k')` | starts k in parallel | keeps running |
| `switch('k')` | starts or wakes k | sleeps |
| `run('k')` | resumes if paused, wakes if sleeping, restarts if running, else starts | keeps running |
| `pause` / `resume` | no update, still renders | — |
| `sleep` / `wake` | no update, no render | — |

`start` where you meant `launch` stops the caller, which kills a HUD scene.

## 2. Physics: Arcade vs Matter

Pick Arcade unless the physics is the game (stacking, contraptions, ragdolls, joints); then Matter. Don't run both.

- Arcade bodies are axis-aligned boxes and circles only: no rotation, slopes, or polygons. Static groups for walls and platforms are cheaper.
- `collider` separates bodies; `overlap` only detects (pickups, hitboxes, triggers). A fourth `processCallback` argument can veto a pair.
- Turn on `arcade: { debug: true }` while building, since drawn bodies explain most "collision doesn't work" reports, and off in the shipped build.
- Fit bodies to non-rectangular art with `body.setSize(w, h).setOffset(x, y)` or `setCircle(r)`.
- Arcade steps discretely: fast small objects tunnel through thin walls, so use thicker colliders or cap velocity.
- Matter: collision categories and filters decide what hits what, `this.matter.world.on('collisionstart', …)` delivers pairs, and body sleeping keeps idle stacks cheap.

## 3. Scale Manager

- Default: `scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH, width: 800, height: 600 }`, a fixed design resolution letterboxed into the parent.
- `RESIZE` changes the game size with the parent; relayout on `this.scale.on('resize', …)` or the HUD misaligns.
- Orientation-locked games show a "rotate your device" overlay (`this.scale.isPortrait`) instead of fighting the layout.
- Pixel art: `pixelArt: true` and `roundPixels: true`.

## 4. Rendering and assets

- Sprites batch while consecutive draws share a texture; interleaving textures from different atlases breaks the batch.
- Each `Text` object owns a canvas texture that re-uploads on change; use bitmap fonts for text that changes often.
- Redrawing a `Graphics` every frame is expensive; bake it with `generateTexture`.
- Animations live on the global Animation Manager: define each once, not on every scene start.
- Load per-level assets in that level's preload, and free big ones with `this.textures.remove(key)` when leaving.

## 5. Tilemaps

Build levels in Tiled and load the exported JSON.

```js
const map = this.make.tilemap({ key: 'map' });
const tileset = map.addTilesetImage('tilesetNameInTiled', 'tiles'); // tileset name as in Tiled, then texture key
const ground = map.createLayer('Ground', tileset, 0, 0);
ground.setCollisionByProperty({ collides: true });
this.physics.add.collider(player, ground);
const spawns = map.getObjectLayer('Objects').objects;
```

- `createLayer` (3.50+) replaces `createStaticLayer` and `createDynamicLayer` from older tutorials; every layer accepts `putTileAt` and `removeTileAt`.
- Visualize collision with `layer.renderDebug(graphics)`, and place spawns and triggers in object layers instead of hardcoded coordinates.

## 6. Pooling with Groups

```js
this.bullets = this.physics.add.group({ classType: Bullet, maxSize: 64, runChildUpdate: true });
const b = this.bullets.get(x, y);     // recycled inactive member, or a new one until maxSize
if (!b) return;                       // pool exhausted
b.enableBody(true, x, y, true, true); // reactivate and show
b.disableBody(true, true);            // on expiry: deactivate and hide, never destroy
```

Iterate only active members (`group.getMatching('active', true)`).

## 7. Input, cameras, tweens

- Read keys in `update` via `.isDown` (`createCursorKeys()`, `addKeys('W,A,S,D')`) and one-shot presses via `Phaser.Input.Keyboard.JustDown(key)`; don't move on `keydown` events.
- Follow with `cameras.main.startFollow(player, true, 0.08, 0.08)`, `setBounds`, and `setDeadzone`; `camera.ignore(objects)` keeps objects off a minimap camera.
- Destroy looping tweens, timers, and particle emitters on shutdown, or they mutate dead objects.
