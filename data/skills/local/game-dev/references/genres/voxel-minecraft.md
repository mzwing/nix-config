# Genre Playbook — Voxel / Minecraft-like

In the browser this is a rendering-performance problem first: one mesh per block runs at single-digit FPS. Read [three.md](../engines/three.md) for draw calls and disposal, and [controls.md](../controls.md) for first-person controls.

## 1. Smallest complete scope

1. Block IDs in chunked typed arrays, rendered as one merged mesh per chunk.
2. First-person movement with AABB-vs-voxel collision, resolved one axis at a time (X, Y, Z) and sub-stepped ([collision-physics.md](../collision-physics.md)).
3. Break and place through a voxel raycast.
4. Three or four block types from one texture atlas.
5. A flat or simple-noise world ([procedural-generation.md](../procedural-generation.md)) with chunks streamed around the player.

Leave inventory, lighting and AO, water, and mobs until rendering and editing are solid.

## 2. Chunks

- Chunks of 16×16×256 or 16³, each a flat `Uint8Array` indexed `x + y*SX + z*SX*SY`, not nested objects.
- One `BufferGeometry` per chunk, rebuilt only when its blocks change; dispose the old geometry on rebuild.
- Load chunks within a radius and unload the rest, disposing geometry, materials, and textures.
- Generate and mesh in Web Workers, transferring the typed arrays, so streaming doesn't hitch.
- Meshing needs the neighbor chunks' border blocks (pass a padded copy), or faces at chunk seams go missing or double.

## 3. Meshing

- Face culling is mandatory: emit a face only when the neighbor in that direction is empty or transparent, across chunk borders too.
- Greedy meshing merges coplanar same-type faces into larger quads; it complicates per-face UVs and AO, so culled per-face meshing is fine for a small world.
- One atlas or texture array so each chunk is one draw call; use `NearestFilter`, and pad atlas tiles (or use a texture array) to stop bleeding.
- No `InstancedMesh` cubes for terrain: instancing still submits every hidden face. Instancing is fine for sparse props.

## 4. Break and place

- Pick with a grid DDA traversal (Amanatides & Woo) through the voxel data, not `Raycaster.intersectObjects` on chunk meshes.
- The axis and direction of the last DDA step give the entered face's normal. Place at `hitCell + faceNormal`, and reject the placement if that cell is occupied or overlaps the player's AABB.
- Breaking a block on a chunk border rebuilds the neighbor chunk too.
- Highlight the targeted block so the player sees what they will hit.
