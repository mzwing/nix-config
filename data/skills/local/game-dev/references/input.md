# Input

Device plumbing. What `steer`, `roll`, and the other movement actions mean to the player, and the A/D self-test, are in [controls.md](controls.md).

Engines with an action system (Godot's InputMap, Unity's Input System) already provide the action layer, so use it. The keyboard, pointer, and gamepad sections are browser-specific; for the event APIs themselves follow the modern-web-guidance skill.

## 1. Actions

- Gameplay reads only abstract actions (`moveX`, `moveY`, `aimX`, `jump`, `attack`, `pause`), never raw keys. Resolve every device into them once per frame at the top of the loop.
- Bindings are data, action → list of inputs (`jump: ['Space', 'KeyW', { pad: 0 }]`), so WASD, arrows, and a stick all drive `moveX`. Persist rebinds with the save ([save.md](save.md)) and warn on conflicts.
- Keep `justPressed` and `justReleased` edges by comparing this frame's actions with last frame's; one-shot actions (jump, shoot, confirm) read edges, or they repeat-fire.
- Detect the active device and show matching button prompts.

## 2. Keyboard

- Track held keys in a set and move in the loop with dt; never move in the key handler, whose repeat rate isn't the frame rate.
- Key on `event.code` so WASD stays in place on AZERTY and QWERTZ; `event.key` follows the layout.
- Clear held keys on `blur` and `visibilitychange`, or a key held while tabbing out sticks down.
- `preventDefault()` only game keys (Space, arrows) so the page doesn't scroll; leave F5, devtools, and tab-out alone.

## 3. Pointer and touch

- On the canvas set `touch-action: none`, treat `pointercancel` as a release (or joysticks and buttons stay held), and track touches by `pointerId` so moving the joystick doesn't cancel a jump button.
- Convert client coordinates through `getBoundingClientRect()` and `devicePixelRatio`; client pixels aren't canvas pixels.
- Mobile layout: a virtual joystick on the left (nipplejs), buttons or an aim zone on the right, both feeding the same actions.

## 4. Gamepad

- Call `navigator.getGamepads()` every frame and never cache a `Gamepad`; it is a snapshot. A pad often appears only after the player presses a button, so prompt for one and handle connect and disconnect mid-game.
- With `mapping === 'standard'`: buttons 0–3 are A/Cross, B/Circle, X/Square, Y/Triangle; 4–5 bumpers; 6–7 triggers (analog, read `.value`); 8 Back; 9 Start; 10–11 stick presses; 12–15 D-pad up, down, left, right. Axes 0–1 are the left stick and 2–3 the right, with −1 up on Y. Any other mapping needs a rebinding screen.
- Sticks never rest at 0, so apply a radial deadzone with re-normalization (about 0.15, typically 0.1–0.25); per-axis deadzones distort diagonals. Deadzone trigger values too.

```js
function radialDeadzone(x, y, dz = 0.15) {
  const m = Math.hypot(x, y);
  if (m < dz) return { x: 0, y: 0 };
  const scale = ((m - dz) / (1 - dz)) / m;
  return { x: x * scale, y: y * scale };
}
```

## 5. Buffering

- Buffer discrete actions for about 120ms (100–150ms, 6–8 frames) so a jump pressed just before landing still fires on landing. Stamp each with its time or frame and expire it after the window.
- Platformers also get coyote time: jump still works a few frames after walking off a ledge.
- Sample input on the fixed timestep so buffered inputs, combos, and netcode replay the same way.
