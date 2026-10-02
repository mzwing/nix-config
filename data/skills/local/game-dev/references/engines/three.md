# three.js

three.js in the browser, with or without React Three Fiber. The engine-neutral loop, controls, and performance rules are in [SKILL.md](../../SKILL.md) and [controls.md](../controls.md); this file adds what is specific to three.js.

For API depth, fetch the official LLM reference at https://threejs.org/docs/llms-full.txt rather than relying on memory: it covers modern imports, WebGLRenderer vs WebGPURenderer, TSL and node materials, loaders, and post-processing. Install `three` with the project's package manager and import from `"three"` and `"three/addons/…"`; no CDN script tags or r128-era globals.

## Loop and timing

- Drive the loop with `renderer.setAnimationLoop(fn)`, which wraps `requestAnimationFrame` and works with WebXR.
- Use `Timer`, not `Clock` (core in current three.js, `three/addons/misc/Timer.js` in older releases). Call `timer.update()` once per frame, then read `getDelta()` as often as needed; a second `Clock.getDelta()` in the same frame returns about 0, a classic freeze. `timer.connect(document)` avoids the huge delta after a hidden tab.
- When nothing animates, render on demand: `setAnimationLoop(null)`, or `frameloop="demand"` in React Three Fiber.

```js
const timer = new THREE.Timer();
timer.connect(document);
const FIXED = 1 / 60;
let accumulator = 0;

renderer.setAnimationLoop(() => {
  timer.update();
  const delta = Math.min(timer.getDelta(), 0.1);
  accumulator += delta;
  while (accumulator >= FIXED) {
    fixedUpdate(FIXED);
    accumulator -= FIXED;
  }
  updateVisuals(delta);
  renderer.render(scene, camera);
});
```

- Cap the pixel ratio: `renderer.setPixelRatio(Math.min(devicePixelRatio, 2))`.
- Prefer `WebGLRenderer`; use `WebGPURenderer` when you need TSL or compute, and `await renderer.init()` before the first render.

## Orientation

- Right-handed, +Y up: +X right, +Y up, +Z toward the viewer. Leave `Object3D.DEFAULT_UP` alone; helpers and grids assume +Y.
- Meshes and glTF models face +Z, cameras look down −Z: the classic "camera looks backwards" gotcha.
- `ConeGeometry` and `CylinderGeometry` point along +Y; rotate them first (`geo.rotateX(Math.PI / 2)` turns +Y into +Z).
- To face a direction, `mesh.lookAt(mesh.position.clone().add(forward))`. Building a basis by hand, a mesh puts `forward` in its +Z column, `makeBasis(normalize(cross(up, forward)), up, forward)`, while a camera puts `-forward` there, `makeBasis(normalize(cross(forward, up)), up, -forward)`. The camera form on a mesh makes it face backwards.
- `lookAt` works in world space; for a nested target read `getWorldPosition` first.
- Check each imported model's forward axis, and debug orientation with `AxesHelper` and `ArrowHelper`.

## First-person controls

The reference is the official `misc_controls_pointerlock` example.

- `PointerLockControls` (an addon) captures the pointer and turns the camera; WASD movement is yours. Move with `controls.moveForward(d)` and `controls.moveRight(d)`, which stay on the XZ plane, using velocity, acceleration, and damping scaled by delta.
- `controls.lock(true)` asks for raw, unaccelerated mouse input. Call it from a click on a "click to play" overlay, and show the overlay again on the `unlock` event.
- Clamp pitch with `minPolarAngle` and `maxPolarAngle`; `pointerSpeed` sets sensitivity.
- Anything parented to the camera, such as a weapon viewmodel, only renders if the camera itself is in the scene: `scene.add(camera)`.
- Skip `FirstPersonControls`; it behaves like fly controls.
- Real collisions, slopes, and stairs need a character controller such as Rapier's `KinematicCharacterController` ([collision-physics.md](../collision-physics.md)).
- Other rigs: `OrbitControls` for inspection; a third-person follow camera as in [controls.md](../controls.md#camera-must-agree).

## Performance

Draw calls are the first limit (`renderer.info.render.calls`): aim under 100 per frame; 500 or more stutters, and mobile is stricter.

- Share material instances across meshes.
- `InstancedMesh` for many identical objects (update with `setMatrixAt` and `instanceMatrix.needsUpdate`); `BatchedMesh` for varied geometries sharing one material, with per-object visibility and culling; merge static scenery with `BufferGeometryUtils.mergeGeometries`, at the cost of per-object culling.
- Frustum culling is automatic; recompute bounds after editing geometry, and keep `camera.far` as small as practical.
- three.js never frees GPU memory by itself: when removing objects or changing levels, call `dispose()` on geometries, materials, and textures, and watch `renderer.info.memory`.
- No `new Vector3()` or `new Matrix4()` per frame; reuse temporaries.
- `LOD` for distant objects; Draco or Meshopt geometry and KTX2 textures; few real-time lights, small shadow maps, baked lighting where possible.
- Watch frame time with Stats.js while developing, and profile on the target device.

## Physics

Rapier (`@dimforge/rapier3d-compat`) is the default: fast WASM, deterministic with fixed steps, with a good character controller. cannon-es is a lighter alternative. Step the world on the fixed timestep, never once per frame with variable delta.

## React Three Fiber

When the project already uses React, write the scene as components inside `<Canvas>`.

- `useFrame((state, delta) => …)` is the loop; delta is in seconds, so cap it.
- drei supplies the bug-prone parts: `<PointerLockControls />` (mouse look only), `useKeyboardControls`, `<OrbitControls />`, `useGLTF`, `<Instances />`, `<Stats />`.
- @react-three/rapier provides `<Physics>`, `<RigidBody>`, and a character controller.
- R3F disposes what it creates, but not textures or loaders you made by hand.
- `dpr={[1, 2]}` caps the pixel ratio.

## Assets

- glTF/GLB with Draco or Meshopt geometry and KTX2 textures, texture atlases, and a small total download.
- Set `crossOrigin = "anonymous"` on images used as textures or drawn to a canvas, or the canvas gets tainted.

## Common bugs

- `Clock.getDelta()` read twice a frame → things freeze or jitter.
- Model faces backwards → mesh +Z vs camera −Z confusion; fix the geometry rotation or use `lookAt`.
- Pointer lock never engages → no user gesture or overlay.
- Memory climbs after level reloads → geometries, materials, or textures not disposed.
- Frame drops → too many draw calls, per-frame allocations, uncompressed textures.
- Blurry or misaligned on high-DPI screens → pixel ratio or canvas resize not handled.
- Viewmodel invisible → camera not added to the scene.

## Sources

- three.js docs: https://threejs.org/docs/ (`Timer`, `PointerLockControls`, `Object3D.lookAt`, `InstancedMesh`, `BatchedMesh`); pointer lock example: https://threejs.org/examples/misc_controls_pointerlock.html
- Discover three.js, the animation loop: https://discoverthreejs.com/book/first-steps/animation-loop/
- React Three Fiber: https://r3f.docs.pmnd.rs; drei: https://github.com/pmndrs/drei; react-three-rapier: https://github.com/pmndrs/react-three-rapier
- Gaffer On Games, Fix Your Timestep: https://gafferongames.com/post/fix_your_timestep/
