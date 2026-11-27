# Genre Playbook — Grid Puzzle (Match-3 & Tetris)

The board is a 2D array of ints or enums, and all logic (matches, gravity, rotation, collision) runs on it; sprites only tween to their cells. State kept in sprite positions or the DOM is the root of "the animation and the logic disagree" bugs. Lock input while the board resolves, and drive fall speed and animation by delta time.

# Part A — Match-3

## A1. Smallest complete scope

1. An 8×8 grid of colors (`grid[row][col] = colorId`).
2. Swap two adjacent gems; the swap is legal only if it makes a match.
3. Clear runs of 3 or more in a row or column.
4. Gravity and refill from the top.
5. Cascades scored with a chain multiplier, plus a score and moves HUD.

Special gems, objectives, and levels come later.

## A2. Board logic

- Match detection: count same-color runs horizontally and vertically from each cell, and collect every cell in a run of 3+ into a set so an L or T shape counts once. Group-clear variants (blobs, Puyo Puyo) use flood fill over 4-connected same-color cells instead.
- Swap validation: swap in the array, detect, and swap back (animating the reversal) when nothing matched.
- The initial board has no matches and at least one valid move: re-roll accidental matches on generation, and shuffle when the board deadlocks.
- Resolve loop: clear, compact each column downward, refill, detect again, and repeat with a rising multiplier until nothing matches. Stopping after one pass misses chain reactions.
- Compute the settled state first, then tween gems to their new cells.

# Part B — Tetris

## B1. Smallest complete scope

1. A 10×20 visible playfield plus hidden rows above for spawning.
2. The 7 tetrominoes, 4 rotation states each.
3. Timed gravity, soft and hard drop, left/right, CW/CCW rotation.
4. Line clears and scoring by lines cleared at once.
5. Game over when a new piece can't spawn.

Players expect the guideline features too: 7-bag randomizer, SRS rotation with wall kicks, lock delay, ghost piece, hold, and next queue.

## B2. Rules that are easy to get wrong

- Test every move and rotation against the board before committing it: all 4 cells in bounds and on empty cells, otherwise reject.
- 7-bag: shuffle all 7 pieces, deal them, reshuffle when empty. Pure random gives droughts and floods.
- Lock delay ~0.5s after landing; moving or rotating resets it, capped at ~15 resets. No lock delay feels harsh; unlimited resets let the player stall forever.
- Line clear: remove full rows from the model, shift everything above down, clear the freed top rows, and test multi-line clears.
- DAS (delay before a held direction repeats) and ARR (repeat rate) define movement feel for skilled play; make them tunable.

## B3. SRS rotation and wall kicks

Rotation states: `0` = spawn, `R` = one CW from spawn, `L` = one CCW from spawn, `2` = 180°. To rotate, compute the cells in the target state, then try the 5 offsets for that `from->to` transition in order and apply the first that fits; if none fits, the rotation fails.

**Coordinate convention:** the tables use x right-positive and y **up**-positive. With row indices increasing downward (the usual grid), test `(dx, -dy)`: a `+2` becomes `row − 2`. Getting this sign wrong is the #1 SRS bug.

**J, L, S, T, Z kick data** (all share one table):
```
0->R:  (0,0) (-1,0) (-1,+1) (0,-2) (-1,-2)
R->0:  (0,0) (+1,0) (+1,-1) (0,+2) (+1,+2)
R->2:  (0,0) (+1,0) (+1,-1) (0,+2) (+1,+2)
2->R:  (0,0) (-1,0) (-1,+1) (0,-2) (-1,-2)
2->L:  (0,0) (+1,0) (+1,+1) (0,-2) (+1,-2)
L->2:  (0,0) (-1,0) (-1,-1) (0,+2) (-1,+2)
L->0:  (0,0) (-1,0) (-1,-1) (0,+2) (-1,+2)
0->L:  (0,0) (+1,0) (+1,+1) (0,-2) (+1,-2)
```

**I piece kick data** (its own table):
```
0->R:  (0,0) (-2,0) (+1,0) (-2,-1) (+1,+2)
R->0:  (0,0) (+2,0) (-1,0) (+2,+1) (-1,-2)
R->2:  (0,0) (-1,0) (+2,0) (-1,+2) (+2,-1)
2->R:  (0,0) (+1,0) (-2,0) (+1,-2) (-2,+1)
2->L:  (0,0) (+2,0) (-1,0) (+2,+1) (-1,-2)
L->2:  (0,0) (-2,0) (+1,0) (-2,-1) (+1,+2)
L->0:  (0,0) (+1,0) (-2,0) (+1,-2) (-2,+1)
0->L:  (0,0) (-1,0) (+2,0) (-1,+2) (+2,-1)
```

**The O piece does not kick.**

These tables, verbatim from the Hard Drop wiki's SRS page, are what make T-spins and squeezing the I piece into tight wells possible.
