# Controls

What left, right, up, and forward mean to the player, and how to prove it. Inverted A/D is the most common ship-blocker in vehicle and flight games. Device plumbing lives in [input.md](input.md).

## Hard rules

1. **Player-visible left and right are law.** With a chase or behind camera and the craft moving forward, A / ← turns the nose (or bank) left on screen, and D / → turns it right.
2. **Never reuse FPS strafe as vehicle steering.** FPS "D → +right" moves position on the ground plane; vehicle A/D is a yaw (or roll) rate. Mixing the two is the main cause of inverted A/D.
3. **Run the control self-test before calling it done.** Screenshots can't show a sign error. If A turns right, flip the steer or roll sign once and retest; don't invent a new coordinate story.

## Coordinate systems

Know the engine's convention before writing orientation math:

| Engine | Handedness | Up | Forward | +yaw turns |
|---|---|---|---|---|
| three.js, Godot, Bevy, libGDX | right | +Y | −Z | left |
| Unity, Babylon.js (default) | left | +Y | +Z | right |
| Unreal | left | +Z | +X | right |
| 2D canvas, Phaser | screen, y down | | | right (clockwise) |

glTF models face +Z (the format's front) while cameras in right-handed engines look down −Z, so a model oriented with camera math faces backwards. The formulas below use the right-handed row; in a left-handed engine use `forward = (sin(yaw), 0, cos(yaw))` and give A a negative yaw rate.

## Yaw-only heading (right-handed, +Y up)

Ground vehicles, walkers, and most arcade craft:

```
// yaw = 0 faces −Z; +yaw turns the nose toward −X (left)
forward = (-sin(yaw), 0, -cos(yaw))
right   = ( cos(yaw), 0, -sin(yaw))   // = normalize(cross(forward, worldUp))
```

With the chase camera behind the craft (near `position - forward * dist`):

| Player sees | World | Input |
|---|---|---|
| Nose left | +yaw | A / ← |
| Nose right | −yaw | D / → |

If your basis differs, keep one consistent pair, but the player-visible column is mandatory.

## Genre maps

### FPS and on-foot (strafe, not steer)

```
W = +forward, S = −forward, D = +right, A = −right   // position, not yaw
mouse: yaw -= movementX * sensitivity; pitch -= movementY * sensitivity; clamp pitch
```

Yaw the body and pitch the camera; movement uses yaw only, so looking up never makes you fly.

### Ground and water vehicles (kart, bike, boat, tank, rover)

```js
let steer = 0; // -1..+1, player-visible: + is left
if (held("KeyA") || held("ArrowLeft")) steer += 1;
if (held("KeyD") || held("ArrowRight")) steer -= 1;

const reverse = speed >= 0 ? 1 : -1; // wheel-left still feels left in reverse
yaw += steer * turnRate * speedFactor * reverse * dt;

position.x += -Math.sin(yaw) * speed * dt;
position.z += -Math.cos(yaw) * speed * dt;
```

The canonical bug:

```js
// WRONG: ships inverted A/D
if (held("KeyA")) steer -= 1;
if (held("KeyD")) steer += 1;
yaw += steer * turnRate * dt; // A → −yaw → nose right on a chase cam
```

If you already wrote `KeyA → steer--`, either swap the mapping or negate once where you integrate, then run the self-test. Never flip twice (keys, integration, and mesh bank).

### Fixed-wing flight

| Input | Action | Player expects |
|---|---|---|
| A / ← | roll left (aileron) | left wing down, bank left |
| D / → | roll right | right wing down |
| W / ↑ | pitch (pick a scheme and label it in the HUD) | nose down or pull-up, consistently |
| S / ↓ | opposite pitch | |
| Q / E | yaw / rudder (optional) | Q left, E right |

Apply roll about the craft's local forward axis with the sign that banks left on A. If the mesh banks the wrong way, flip one sign on the roll, not the whole basis. A positive bank should produce a turn in the bank's direction.

### Helicopters, drones, 6DOF

Show the scheme on a start overlay. Throttle or altitude on held keys must not stick "always up" after one press; A strafes or yaws left and D right in the craft's horizontal frame.

### 2D side-scrollers

D / → moves right on screen and A / ← left. Gravity flips only if the genre is explicitly upside down.

## Camera must agree

- Chase cam: `desired = craftPos + up * height - forward * followDist`, approached with exponential smoothing scaled by dt (`t = 1 - exp(-k * dt)`), then look at the craft.
- Compute `forward` once and share it with the camera. Never rebuild it in camera code with the opposite yaw sign, and never let camera code mutate a shared temporary vector.
- Debug order: keys register → signs correct → camera agrees.

## Input plumbing

Track held keys by physical key code, clear them when the window loses focus, and move in the game loop with dt, never in the key handler. Map keyboard, touch, and gamepad into actions (`throttle`, `steer`, `pitch`, `roll`); details in [input.md](input.md).

## Mouse look

- Browser: Pointer Lock requested from a user gesture behind a "click to play" overlay, reading `movementX/Y`; see [engines/three.md](engines/three.md#first-person-controls).
- Engines: capture the mouse (Godot `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`, Unity `Cursor.lockState = CursorLockMode.Locked`).
- Clamp pitch just under ±90°.

## Control self-test (before "done")

### Player-visible checklist

While moving forward with the chase camera behind:

| Hold | Must see within about 0.5s |
|---|---|
| A | nose or bank moves left on screen |
| D | nose or bank moves right on screen |
| W (ground) | speed increases along the facing |
| S (ground) | brakes or reverses, as designed |

If A fails, flip the steer or roll sign once and retest both A and D.

### Test hook

Expose a small probe so a test can check signs without reaching into closures: in the browser `window.__controlsTest` behind a dev or `?qa=1` flag, elsewhere a debug command or test API.

```ts
type ControlsProbe = {
  getYaw: () => number;
  getSpeed: () => number;
  setSteer?: (v: number) => void; // -1..1, same sign as production
  setKeys?: (codes: string[]) => void;
};
```

Better still, keep the steering integration in a pure function and unit-test it: steer +1 for 0.5s at speed > 0 must change yaw in the engine's "left" direction.

### Automated smoke

1. Start play so the simulation runs.
2. Throttle until `getSpeed()` passes a threshold.
3. Record `y0 = getYaw()`.
4. Hold A (or `setSteer(+1)`) for 500ms.
5. Assert the wrapped angle change has the left sign for your basis (right-handed: yaw increased).
6. Repeat for D with the opposite sign.
7. Fail the build if either assertion fails.

```js
const wrap = (a) => Math.atan2(Math.sin(a), Math.cos(a));
expect(wrap(yawAfterA - yawBefore)).toBeGreaterThan(0.05);
expect(wrap(yawAfterD - yawBefore)).toBeLessThan(-0.05);
```

For planes, assert roll or the on-screen bank the same way: A banks left.

### What not to do

- Don't only test that "D increases some internal variable".
- Don't use FPS "D → +X when facing −Z" as the vehicle pass condition.
- Don't flip mesh bank, camera, and steering at once when fixing: change one sign and retest.

## Finish checklist

- [ ] Read this before writing movement, steering, or flight code.
- [ ] Genre map chosen, and the start screen or HUD labels match it.
- [ ] Chase-cam A/D test passed.
- [ ] Probe or unit test exists and ran once.
- [ ] Mesh bank agrees with roll and steer input.
- [ ] Keys are held-state and dt-scaled; no sticky thrust from a single tap unless intended and labeled.
