# Genre Playbook — Tower Defense

A grid, a path, targeting, and an economy.

## 1. Smallest complete scope

1. A grid map with an authored path from spawn to base.
2. One enemy type walking the path in 5–10 escalating waves.
3. One tower type, placed on buildable cells for gold.
4. Towers that target and shoot enemies in range.
5. Gold from kills, a life lost per leak, game over at 0, and a "start next wave" button.

Default to a fixed path: no runtime pathfinding and no way to trap enemies. Build maze TD only when asked.

## 2. Map and path

- Cells carry a type (path, buildable, blocked, spawn, base). Placement snaps to cell centers and checks type, occupancy, and gold before committing.
- Fixed path: each enemy stores its waypoint index and moves toward it by `speed * dt`; advance within an epsilon and clamp the final step, or enemies overshoot and orbit the waypoint. Reaching the end is a leak.
- Maze TD: before committing a placement, run A* ([ai-pathfinding.md](../ai-pathfinding.md)) and reject the placement if no route to the base remains. Re-path only on place or sell, and cache the paths.

## 3. Towers

- Range test with squared distance; add a spatial grid once towers × enemies gets large.
- Targeting is an explicit, ideally selectable policy; default to First (furthest along the path), which stops leaks best.
- Fire cooldown runs on delta time.
- Projectiles hold a target reference and a TTL; when the target dies they retarget, fly on to its last position, or despawn. Homing or aiming at the predicted position feels better than aiming at the current one.
- Show the range ring on hover and selection.

## 4. Waves and economy

- Waves are data, a list of `{ enemyType, count, spawnInterval, delay }` groups, not code.
- Escalate with more, tougher, and faster enemies, then armored and flying types that only some towers can handle.
- Selling refunds part of the cost; a full refund allows sell-and-rebuild exploits.
- Tune gold so the player is always a little short.
