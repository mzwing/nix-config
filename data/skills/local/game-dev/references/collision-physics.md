# Collision & Physics

## 1. Engine or hand-rolled

- Arcade games (platformers, top-down, breakout, shooters) use hand-rolled AABB collision: deterministic, no dependency, and you own the feel.
- Rigid bodies, stacking, joints, ragdolls, or vehicles use the engine's physics, else a library: Matter.js, Planck.js, or Rapier2D in 2D; Rapier (rapier.js, WASM) or cannon-es in 3D.

## 2. Shapes

- AABB tests only work on unrotated boxes. Rotated boxes and convex polygons need SAT, and SAT only works on convex shapes, so split concave ones.
- Compare squared distances, not `sqrt`.

## 3. Broadphase

Past about 100 dynamic colliders, cull pairs before exact tests. A uniform spatial hash (cells 2–3× the typical object size) suits many similar-sized objects, a quadtree suits clustered or mixed sizes, and sort-and-sweep suits coherent motion. Physics engines do this already.

## 4. Tunneling

- A fast object can pass a thin wall between steps without ever overlapping it. Fixes, best first: swept AABB (move to the time of first contact), a raycast for bullets, substeps. In engines enable CCD on fast bodies (Rapier `setCcdEnabled(true)`).
- Thickening walls past the maximum per-step travel is a fragile fallback.

## 5. Resolution

- Platformers move and resolve X, then move and resolve Y; resolving both at once catches on tile seams and clips corners.
- Push out along the axis of least penetration (with SAT, along the MTV) and zero the velocity on that axis, or gravity accumulates and the body shudders into the floor.
- Keep a small skin epsilon; resting jitter usually means a variable timestep or corrections fighting each other.
- Step physics engines on the fixed timestep from [SKILL.md](../SKILL.md#loop-and-timing), never with the frame's variable delta. Rapier is deterministic given fixed steps and identical inputs.

## 6. Character controllers

- 3D player movement uses a kinematic character controller with a capsule, autostep, snap-to-ground, and a slope limit, never a raw dynamic body; a box snags on edges.
- Use the engine's (Godot `CharacterBody3D`, Unity `CharacterController`), else Rapier's `KinematicCharacterController`: create it with `world.createCharacterController(offset)`, call `computeColliderMovement(collider, desiredTranslation)` each fixed step, and apply `computedMovement()`. Gravity and jumping are yours to apply.
- Ground checks use the controller's grounded flag or a short downward ray; coyote time is in [input.md](input.md).
