# Babylon.js

Babylon.js bundles physics, an inspector, GUI, node materials, camera behaviors, SceneOptimizer, and a WebGPU backend. This file assumes the general rules in [SKILL.md](../../SKILL.md).

## 1. Loop and coordinates

- Put per-frame logic in `scene.onBeforeRenderObservable.add(fn)` rather than the `engine.runRenderLoop` closure; `engine.getDeltaTime()` is in milliseconds.
- `engine.setHardwareScalingLevel(n)` renders at 1/n resolution: n > 1 lowers resolution (a big mobile win), n < 1 supersamples.
- **Babylon is left-handed by default** (+Y up, +Z forward, +yaw turns right), the mirror of three.js; `scene.useRightHandedSystem = true` switches it. Steering signs follow [controls.md](../controls.md#coordinate-systems).

## 2. WebGPU

```js
async function createEngine(canvas) {
  if (await WebGPUEngine.IsSupportedAsync) {
    const engine = new WebGPUEngine(canvas, { antialias: true });
    await engine.initAsync();
    return engine;
  }
  return new Engine(canvas, true, { powerPreference: "high-performance" });
}
```

- `IsSupportedAsync` is a promise-valued property, not a method, and `initAsync()` must finish before you create the `Scene`.
- Snapshot rendering (`engine.snapshotRendering = true`, WebGPU only) replays a recorded command stream for scenes whose draw list doesn't change; refresh it when the scene structure changes.

## 3. Cameras

- `UniversalCamera` with `applyGravity`, `checkCollisions`, and an `ellipsoid` collides against meshes that set `checkCollisions = true`, with no physics engine.
- Camera behaviors (`useFramingBehavior`, `useAutoRotationBehavior`, bouncing at radius limits) give menu and product views polish for free.
- Keep `camera.maxZ` as small and `minZ` as large as practical, for depth precision and culling.

## 4. Physics: Havok

Use Havok through the Physics V2 API (`PhysicsAggregate`, `PhysicsBody`, `PhysicsShape`). Cannon, Ammo, and Oimo remain on the V1 plugin; reach for Ammo only for its soft bodies.

```js
import { HavokPlugin, PhysicsAggregate, PhysicsShapeType, Vector3 } from "@babylonjs/core";
import HavokPhysics from "@babylonjs/havok";

const havok = await HavokPhysics({ locateFile: (file) => `/assets/${file}` });
scene.enablePhysics(new Vector3(0, -9.81, 0), new HavokPlugin(true, havok));
new PhysicsAggregate(sphere, PhysicsShapeType.SPHERE, { mass: 1 }, scene); // mass 0 = static
```

- `await HavokPhysics()` is mandatory, and bundlers (Vite, webpack) must serve `HavokPhysics.wasm`: point `locateFile` at it or copy it, or physics is silently absent.
- The first `HavokPlugin` argument (`true`) steps the world by the engine's frame delta.
- `PhysicsAggregate` builds the shape and body for you; build `PhysicsBody` and `PhysicsShape` yourself for compound shapes or one shape shared by many bodies.
- Collision events need `body.setCollisionCallbackEnabled(true)` before `body.getCollisionObservable().add(…)`.
- Prefer primitives or convex hulls; mesh colliders are expensive.
- On glTF imports, put physics on the child mesh, not the `__root__` node, or transforms apply twice.
- Debug with `new BABYLON.Debug.PhysicsViewer(scene).showBody(aggregate.body)`.

## 5. Assets

- `import "@babylonjs/loaders"` once, or glTF loading fails; then use `ImportMeshAsync`, `AppendSceneAsync`, or `LoadAssetContainerAsync`.
- An `AssetContainer` loads without adding to the scene: `addAllToScene()` and `removeAllFromScene()` switch levels, `dispose()` frees GPU memory on unload, and `instantiateModelsToScene()` clones a model with its skeleton and animations to spawn many from one load.

## 6. GUI

`AdvancedDynamicTexture.CreateFullscreenUI("ui")` from `@babylonjs/gui` draws a HUD inside the canvas that scales with it; `control.linkWithMesh(mesh)` pins labels and health bars to 3D objects.

## 7. Performance

Freezing static content is the highest-leverage Babylon optimization and the one most often skipped.

- `mesh.freezeWorldMatrix()` and `mesh.doNotSyncBoundingInfo = true` for meshes that never move; `material.freeze()` for fixed materials; `scene.freezeActiveMeshes()` when the visible set doesn't change. Each has an `unfreeze` counterpart.
- `scene.blockMaterialDirtyMechanism = true` while bulk-creating materials.
- `scene.performancePriority = ScenePerformancePriority.Intermediate` applies a bundle of these; `Aggressive` also disables picking and other features, so check nothing you need breaks.
- Thin instances (`thinInstanceAdd`, `thinInstanceSetBuffer`) for thousands of identical static objects in one draw call; regular instances (`createInstance()`) when each needs picking or parenting. `Mesh.MergeMeshes` for static geometry sharing a material.
- `scene.skipPointerMovePicking = true` and `mesh.isPickable = false` on non-interactive meshes; picking on every pointer move is a silent CPU cost.
- `scene.autoClear = false` when the scene covers the whole viewport.
- `mesh.addLODLevel(distance, lowMesh)`, plus `addLODLevel(farDistance, null)` to cull entirely.
- Few real-time lights and small shadow maps; for static lights, render the shadow map once with `refreshRate = RenderTargetTexture.REFRESHRATE_RENDER_ONCE`.
- No per-frame allocations: `TmpVectors.Vector3[0]` scratch vectors and the `…ToRef()` variants (`addToRef`, `scaleToRef`).
- Ship `SceneOptimizer.OptimizeAsync(scene, SceneOptimizerOptions.HighDegradationAllowed(60))` so one build degrades quality until it holds 60 fps on weak devices.
- Profile with the inspector, `import "@babylonjs/inspector"; scene.debugLayer.show()`: its statistics show draw calls, active meshes, and CPU vs GPU time.
