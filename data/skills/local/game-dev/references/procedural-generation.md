# Procedural Generation

## 1. Seeded randomness

- Never generate with `Math.random()`: it can't be seeded, so levels can't be reproduced, shared, debugged, or synced. Use a small seeded PRNG such as mulberry32, and hash string seeds to an integer first (xmur3).
- Give independent systems their own streams (terrain, loot, enemies: `mulberry32(seed)`, `mulberry32(seed ^ 0x9e3779b9)`) so tuning one doesn't reshuffle the rest.
- Networked or lockstep generation needs every machine to consume the same PRNG in the same order; order-of-consumption bugs are the usual desync ([multiplayer.md](multiplayer.md)).
- Streamed worlds derive each chunk's seed from `(worldSeed, chunkX, chunkY)` so chunks regenerate identically without seams.
- Show the seed, or let the player enter one.

## 2. Noise

`simplex-noise` v4 has no `new SimplexNoise()`; use the factories and pass your PRNG, or it falls back to `Math.random()`:

```js
import { createNoise2D } from 'simplex-noise';
const noise2D = createNoise2D(mulberry32(seed)); // returns about [-1, 1]
```

Elevation and moisture come from two independent noise fields; deriving moisture from elevation correlates the biomes.

## 3. Levels

- After generating a dungeon or cave, flood-fill from the entrance and confirm the exit, keys, and key rooms are reachable; carve connectors or regenerate if not. Also check the room count and that spawn and exit differ.
- Cellular-automata caves leave disconnected pockets: keep only the largest region or tunnel between them.
- Wave function collapse hits contradictions (a cell with no options left); restart or backtrack, or generation hangs.
- Generate on level load, in chunks, or in a worker; never regenerate per frame or block the main thread on one huge pass.
