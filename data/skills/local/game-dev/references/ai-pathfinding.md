# Game AI & Pathfinding

Default stack: A* on a grid (a navmesh in open 3D) decides where to go, steering decides how to move there, and a state machine or behavior tree decides what to do. A* alone looks robotic; steering alone gets stuck on walls.

## 1. A*

- Match the heuristic to movement: Manhattan for 4-directional grids, octile for 8-directional (diagonals cost √2), Chebyshev when diagonals cost 1. Manhattan on an 8-directional grid overestimates and returns wrong paths; Euclidean on a 4-directional grid underestimates and searches slowly.
- Keep the open set in a binary heap; a linear scan stutters on big maps.
- Forbid diagonal moves that squeeze between two wall corners, or agents clip through walls.
- Handle "no path" explicitly instead of freezing or crashing.
- Smooth the raw path (string-pulling or line-of-sight simplification) so agents don't zig-zag through cell centers.
- Re-path on a throttle when the target moves, never every frame, and invalidate cached paths when walls change.
- Many agents chasing one goal (tower defense, RTS) share one BFS or Dijkstra flow field from the goal instead of running A* each.
- PathFinding.js covers grid A*, JPS, and BFS.

## 2. Steering

- Arrive slows inside a radius; plain seek overshoots and orbits the target.
- Sum weighted forces, clamp to max force and max speed, and integrate with dt.

## 3. Decisions

- Simple enemies use a finite state machine with `enter`, `update(dt)`, and `exit` per state and table-driven transitions. Past about 6–8 states the transitions sprawl; switch to a behavior tree.
- Behavior-tree actions that take time (walking a path) return `Running` and resume next tick; a blocking action stalls the tree.
- Don't build a behavior-tree framework for a three-state slime.

## 4. Navmesh

Open 3D worlds use a navmesh: recast-navigation-js bakes one from level geometry and adds crowd avoidance; three-pathfinding is a simpler three.js follower. Smooth paths through the polygon portals with the funnel algorithm.

## 5. Cost

- Run AI decisions on the fixed timestep at a lower rate (10–20Hz) and let steering move agents smoothly in between.
- Stagger updates so distant or off-screen agents think less often.
- Time-slice large searches across frames or move them to a worker; use typed arrays for big grids and reuse search buffers.
