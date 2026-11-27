# Genre Playbook — Arcade Racing / Kart

Forgiving handling, a drift with a payoff, and laps that can't be cheated. Steering signs, the reverse flip, the chase camera, and the control self-test are in [controls.md](../controls.md); run that self-test before calling it done.

## 1. Smallest complete scope

1. Arcade handling: accelerate, brake and reverse, steer.
2. A drift with a boost payoff.
3. One looping track with walls and ground collision.
4. Ordered checkpoints and lap counting.
5. A chase camera and a HUD: speed, lap X/N, current and best lap time.

One car, one track, three laps. Opponents, items, and more tracks come later.

## 2. Handling

Use pseudo-physics (heading, forward speed, decaying lateral velocity), not a rigid-body vehicle sim.

- `speed += throttle * accel * dt`, clamped to `maxSpeed` with a lower cap in reverse; `speed *= 1 - drag * dt`, with more drag off throttle and much more off-track, so cutting corners costs speed.
- `speedFactor` in the steering integration is `clamp(speed / turnSpeed, 0, 1)`, tapered near top speed: a parked kart barely turns and a fast one isn't twitchy.
- Each frame, split velocity into forward and sideways parts and remove most of the sideways part. How much survives is the grip: none feels on rails, too much feels like ice.
- Raycast down to the track for height and surface normal instead of simulating suspension, and align the car's up to the normal.

## 3. Drift

- Drifting lets more sideways velocity survive while the drift button is held and the player steers; in kart style a small hop starts it.
- Holding the drift builds a charge; release grants a staged mini-turbo, with spark colors per stage.
- Steering modulates the slide angle; on release, lerp the lateral velocity back to grip rather than zeroing it.
- Skid decals, sparks, screech, and an FOV kick on boost sell it ([game-feel.md](../game-feel.md)).

## 4. Checkpoints and laps

- Ordered trigger gates with a `nextCheckpoint` index; only the expected next gate counts, so driving backwards or re-crossing the finish line does nothing.
- A lap counts when the finish is crossed after every checkpoint; then `nextCheckpoint` resets to 0.
- Test gate crossing as a segment from last position to current position against the gate plane, or fast cars tunnel through thin gates.
- When the car flips, leaves the track, or stalls, respawn it at the last passed checkpoint facing forward; the same order drives wrong-way detection.
- Freeze the lap timer at the finish.

## 5. Camera

Smooth both the chase camera's position and its look-at point, and never hard-parent it to the car: that feels stiff and causes motion sickness. Widen the FOV slightly with speed and on boost.
