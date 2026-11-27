# Genre Playbook — Board & Card Games (Chess, Checkers, Tic-Tac-Toe, Card games)

Correctness is the game: an illegal move or a flaky turn transition breaks trust instantly. Rendering is trivial; the model and its rules are everything.

## 1. Smallest complete scope

1. A board and state model separate from the view.
2. An explicit turn state machine.
3. Legal-move generation; only legal moves are highlighted and accepted.
4. Win, loss, and draw detection.
5. One AI opponent.

For chess, use `chess.js` for move generation, validation, and terminal detection and `chessground` (or another board library) for the UI unless hand-written rules are asked for; en passant, castling through check, pins, promotion, and repetition draws are a large bug surface. Hand-roll rules only for simple games (tic-tac-toe, connect-4, checkers).

## 2. Turn state machine

- One source of truth for `currentPlayer`, with gated steps: select → show legal moves → choose → validate → apply → switch player → check terminal state.
- Ignore all input while animating and during the AI's turn; a click during resolution corrupts state or grants a double move.
- Keep the model pure and deterministic, with a reversible move stack (captured piece, castling and en passant flags) for undo and repetition detection.

## 3. Rules

- Chess legality: make the move on a copy and reject it if your own king is attacked. This handles pins; don't special-case them.
- Checkmate is check with no legal moves; stalemate is no check and no legal moves, and it is a draw, not a win.
- Line games (tic-tac-toe, connect-4) check every line after each move and detect the full-board draw.
- Shuffle with Fisher–Yates; `sort(() => Math.random() - 0.5)` is biased.
- Hidden hands are only truly hidden with a server ([multiplayer.md](../multiplayer.md)).

## 4. AI

- Perfect-information games: minimax with alpha-beta, trying captures first for better pruning. Depth is difficulty: tic-tac-toe searches to the end, connect-4 and checkers a few plies.
- Chess evaluation: material (P=1, N=B=3, R=5, Q=9) plus piece-square tables. Score terminal wins and losses as `±(MATE - ply)` so the AI takes the fastest mate instead of postponing it; draws score 0.
- Search in a Web Worker or with time-boxed iterative deepening; a UI that hangs while the AI thinks looks broken.
- Hidden-information card games need rules-based heuristics or MCTS with determinization, not plain minimax.
- Test the search on known positions (mate in 1, forced draws); min/max sign errors are the classic bug.
