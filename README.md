# ISOLA — Board Game in SWI-Prolog

**Course:** Inteligência Artificial — ISEL, Semestre Verão 2025/2026
**Professor:** Nuno Leite
**Group:** 51620 Radesh Govind · 51619 Martim Monteiro
**Deadline:** 13 April 2026

---

## 1. What is this project?

This is a complete implementation of the two-player strategy game **ISOLA** written in **SWI-Prolog**. One or both players can be controlled by an AI that uses **alpha-beta pruning** — an optimised version of the minimax algorithm — to search the game tree and choose the best move.

The project demonstrates three key ideas:
1. How logic programming (Prolog) can represent game state as pure data structures.
2. How minimax formalises adversarial reasoning.
3. How alpha-beta pruning cuts the search space in half, making the AI practical.

---

## 2. The Game: ISOLA

### 2.1 Rules

ISOLA is played on an **N×N grid** (default 6×6) by two players:

| Symbol | Player   | Starting position |
|--------|----------|-------------------|
| `x`    | Player 1 | Top-left corner   |
| `o`    | Player 2 | Bottom-right corner |

Every turn has **two mandatory steps**:

1. **MOVE** — slide your pawn one square in any of 8 directions (like a chess king). You cannot move onto a removed cell (`#`) or onto the opponent's cell.
2. **REMOVE** — permanently destroy any empty cell (`.`) on the board. Mark it `#`. You cannot destroy a cell occupied by a pawn.

**Win condition:** A player **loses** when they have no legal move at the start of their turn. The other player wins.

### 2.2 Example game (3×3)

```
Initial board          After turn 1            After turn 2
                       x moves 0/0→1/1         o moves 2/2→1/2
                       removes 2/0             removes 0/1

     0  1  2               0  1  2                  0  1  2
   +--------            +--------               +--------
0  |  x  .  .        0  |  .  .  .          0  |  .  #  .
1  |  .  .  .        1  |  .  x  .          1  |  .  x  o
2  |  .  .  o        2  |  #  .  o          2  |  #  .  .
```

Positions are **0-indexed Row/Col**. The user types `1/1.` (note the trailing period — required by Prolog's `read/1`).

---

## 3. Prolog — The Language

### 3.1 What is Prolog?

Prolog is a **logic programming** language. Instead of telling the computer *how* to compute something step by step, you describe *what is true* using facts and rules, then ask questions.

```prolog
% Fact: socrates is a person.
person(socrates).

% Rule: X is mortal if X is a person.
mortal(X) :- person(X).

% Query:
?- mortal(socrates).
true.
```

Python or Java programmers write `for` loops and `if` statements. Prolog programmers write **relations** and let the engine figure out how to satisfy them via **unification** and **backtracking**.

### 3.2 The key ideas

| Concept | What it means |
|---------|---------------|
| **Unification (`=`)** | Match two terms by binding variables. `X = 3` binds X to 3. `f(X,2) = f(1,Y)` binds X=1, Y=2. |
| **Arithmetic (`is`)** | `X is 3 + 4` evaluates the right side and unifies X with 8. Unlike `=`, the right side is *computed*. |
| **Comparison (`==`, `\=`)** | `X == Y` checks structural equality (no evaluation). `X \= Y` succeeds if they *cannot* unify. |
| **Backtracking** | If a goal fails, Prolog undoes the last choice and tries the next alternative. This makes it easy to search combinatorial spaces. |
| **Cut (`!`)** | Commits to the current choice — no more backtracking past this point. Dangerous if overused because it breaks the declarative reading of code. |
| **`:-`** | Read as "if". `head :- body` means "head is true if body is true". |

### 3.3 Lists in Prolog

A list is either empty `[]` or a head-tail pair `[H|T]`:

```prolog
?- [H|T] = [1,2,3].
H = 1,
T = [2, 3].
```

A board row is a list of atoms. The whole board is a list of rows:

```prolog
Board = [[x, '.', '.'],
         ['.', '.', '.'],
         ['.', '.', o]]
```

### 3.4 Recursion instead of loops

There are no `for` loops. Instead:

```prolog
% Sum a list of numbers.
sum_list([], 0).
sum_list([H|T], Total) :-
    sum_list(T, Rest),
    Total is H + Rest.
```

Base case: empty list sums to 0. Recursive case: sum the tail, add the head.

### 3.5 Minimal working example relevant to this project

```prolog
% Is cell Row/Col empty on Board?
empty_at(Board, Row, Col) :-
    nth0(Row, Board, RowList),   % get the Row-th row (0-based)
    nth0(Col, RowList, Cell),    % get the Col-th cell
    Cell = '.'.                   % it must be the atom '.'

% Test it:
?- Board = [['.',x,'.'],['.','.','.']],
   empty_at(Board, 0, 2).
true.

?- empty_at(Board, 0, 1).   % cell is x, not .
false.
```

---

## 4. Minimax — The Algorithm

### 4.1 What problem does it solve?

In a two-player zero-sum game, one player's gain is the other's loss. Each player plays **optimally** — they always choose the move that maximises their own outcome. Minimax computes which move that is.

### 4.2 The game tree

Every board position branches into child positions (one per legal move). The game tree has:
- **MAX nodes**: the maximising player's turn (Player 1, `x`).
- **MIN nodes**: the minimising player's turn (Player 2, `o`).

```
                  MAX
                /  |  \
             MIN  MIN  MIN
            / \   |   / \
           3  12  8   2   4     ← leaf values (heuristic score)
```

### 4.3 The MINIMAX formula

```
MINIMAX(s) =
    UTILITY(s)                        if s is terminal
    max over a of MINIMAX(RESULT(s,a)) if PLAYER(s) = MAX
    min over a of MINIMAX(RESULT(s,a)) if PLAYER(s) = MIN
```

In English: at a MAX node, pick the child with the highest value. At a MIN node, pick the child with the lowest value. At a terminal node (game over), return the actual outcome.

### 4.4 Worked example (AIMA Figure 5.2 values)

```
                  MAX
              [3]
             /   \
           MIN   MIN
          [3]    [2]
         / \    / \
       [3] [12][8] [2,4,6,14,5,2]
```

Leaves: `3, 12, 8, 2, 4, 6, 14, 5, 2`

Working bottom-up:
- Leftmost MIN node: `min(3, 12) = 3`
- Middle MIN node: `min(8, 2) = 2` (or `min(8,2,4,6,14,5,2) = 2`)
- ROOT MAX node: `max(3, 2) = 3`

MAX player should choose the left branch (value 3).

### 4.5 Why it is correct

By structural induction on the depth of the tree:
- **Base:** at depth 0 (terminal), UTILITY is correct by definition.
- **Step:** Assume MINIMAX is correct for all children. A MAX node selects the child with the maximum correct value, so it is correct. Similarly for MIN nodes.

### 4.6 Complexity

| Metric | Value |
|--------|-------|
| Time | O(b^m) where b = branching factor, m = tree depth |
| Space | O(bm) (depth-first search) |

For ISOLA on a 6×6 board: b ≈ 264 (8 moves × 33 removes), m = 4 → 264^4 ≈ **4.9 billion nodes**. Unacceptable without pruning.

---

## 5. Alpha-Beta Pruning

### 5.1 The key insight

If we are searching a MAX node and we already know we can achieve value **v**, we can stop exploring a MIN node whose value would be **≤ v** — it will never be chosen by MAX.

More formally, two values are tracked at each point in the search:
- **α (alpha)** — the best value MAX is **guaranteed** to achieve from the current path ("at least this").
- **β (beta)** — the best value MIN is **guaranteed** to achieve from the current path ("at most this").

**Prune when:** at a MAX node, `v ≥ β` (MIN would never allow this). At a MIN node, `v ≤ α` (MAX would never choose this path).

### 5.2 Step-by-step trace on the same tree

```
Step 1: Visit left MIN child.
  Step 1a: leaf = 3. α = -∞, β = +∞.  Update MIN's best to 3.
  Step 1b: leaf = 12. 12 > 3, MIN's best stays 3.
  MIN returns 3 to ROOT. ROOT's α = max(-∞, 3) = 3.

Step 2: Visit right MIN child. β = +∞, α = 3.
  Step 2a: leaf = 2. Update MIN's best to 2.
           Is 2 ≤ α=3? YES → PRUNE. Stop searching this subtree.
  MIN would return at most 2, which MAX (with α=3) would not choose.

Result: ROOT chooses left branch, value = 3.
Nodes NOT visited: [4, 6, 14, 5, 2] — 5 nodes pruned!
```

### 5.3 Complexity improvement

| Ordering | Nodes searched |
|----------|----------------|
| No pruning | O(b^m) |
| Alpha-beta, random order | O(b^(3m/4)) |
| Alpha-beta, **perfect ordering** | O(b^(m/2)) |

Perfect ordering halves the effective search depth. With b=264, m=4:
- Without: 4.9 billion nodes
- With perfect order: 264^2 ≈ **70,000 nodes**

### 5.4 Move ordering in this implementation

`order_pairs/6` in `src/ai.pl` sorts moves by a heuristic score before searching:
- **Moves toward the centre** first (central positions give more mobility).
- **Removes adjacent to the opponent** first (cuts their future moves most).

This is a form of the **killer move heuristic** — moves that caused cutoffs early in the search are tried first in similar positions.

---

## 6. ISOLA-Specific Design Decisions

### 6.1 Why a list-of-lists for the board

Prolog works naturally with list recursion. A `Board` is a list of rows; each row is a list of cell atoms (`'.'`, `x`, `o`, `#`). Accessing a cell is `nth0(Row, Board, RowList), nth0(Col, RowList, Cell)`. Updating uses `nth0/4` (the 4-argument "split" variant) to non-destructively replace a single element.

### 6.2 Positions tracked separately

Pawn positions (`P1Pos = Row/Col`, `P2Pos = Row/Col`) are stored **separately from the board**. This means:
- Finding a pawn's position is O(1) — no board scan required.
- The remove step can quickly exclude the pawn cells from valid removes.

### 6.3 The evaluation function

```
score = (P1_mobility − P2_mobility) × 10 + (P1_centrality − P2_centrality)
```

**Mobility** (number of legal moves available) is the dominant term. In ISOLA, a player with fewer moves is closer to losing — this heuristic directly approximates the game outcome.

**Centrality** is a small tiebreaker. Central positions generally provide more mobility options in the future.

### 6.4 Why depth 4 is the practical limit

On a full 6×6 board, the branching factor b ≈ 264. Even with alpha-beta, at depth 4 we may visit O(264^2) ≈ 70,000 nodes per move with perfect ordering, or more with poor ordering. At depth 6, this becomes 264^3 ≈ 18 million — feasible in C, but slow in interpreted Prolog (minutes per move).

Depth 4 provides a strong AI that responds within a few seconds in mid-game. In early game (wide-open board), it may take 20–30 seconds.

### 6.5 Two-step turns and branching factor

Each full ply is (move, remove). This means the branching factor is:

```
b = |valid_moves| × |valid_removes|
  ≈ 8 × (N² − 2 − already_removed)
```

For a fresh 6×6 board: 8 × 34 = 272. The removes dominate. One optimisation not implemented here: **limiting removes** to a strategic subset (e.g., only removes adjacent to the opponent or to the moving pawn). This would reduce b by ~10× with minimal quality loss.

### 6.6 Transposition tables

Many different move sequences lead to the same board position. A **transposition table** (hash map from board state to previously-computed minimax values) could avoid recomputing these. In this implementation, we did not include one because:
- Implementing a fast hash for Prolog lists adds significant complexity.
- At depth 4, the search is already acceptable without it.
- A production implementation would use Zobrist hashing for incremental board updates.

---

## 7. Project Structure

```
isolation-board-game/
├── src/
│   ├── board.pl   — Board creation, cell access, display
│   ├── rules.pl   — Move legality, apply_move, game_over
│   ├── ai.pl      — Minimax, alpha-beta, evaluation, move ordering
│   ├── game.pl    — Game loop, menus, human/AI turn handlers
│   └── main.pl    — Entry point, loads all modules
├── tests/
│   └── tests.pl   — PLUnit test suite (33 tests)
└── docs/
    └── assignment.pdf
```

### Exported predicates

#### `board.pl`
| Predicate | Description |
|-----------|-------------|
| `initial_board(+Size, -Board)` | Creates a Size×Size board filled with `'.'` |
| `board_size(+Board, -Size)` | Returns the board dimension |
| `get_cell(+Board, +R, +C, -Cell)` | Reads cell R/C; fails if out of bounds |
| `set_cell(+Board, +R, +C, +Val, -New)` | Returns board with R/C set to Val |
| `empty_cell(+Cell)` | True if cell is `'.'` |
| `all_cells(+Board, -Cells)` | List of all R/C positions |
| `display_board(+Board)` | Pretty-prints the board |

#### `rules.pl`
| Predicate | Description |
|-----------|-------------|
| `valid_move(+Board, +FR, +FC, ?TR, ?TC)` | Generator and checker for one-step moves |
| `valid_moves(+Board, +R, +C, -Moves)` | All reachable positions as `TR/TC` list |
| `valid_removes(+Board, +P1R, +P1C, +P2R, +P2C, -Removes)` | All removable cells |
| `apply_move(+Board, +FR, +FC, +TR, +TC, -New)` | Moves pawn, leaves `'.'` at source |
| `apply_remove(+Board, +R, +C, -New)` | Marks cell as `'#'` |
| `game_over(+Board, +Player, +P1Pos, +P2Pos)` | True if Player has no moves |
| `player_pos(+Player, +P1Pos, +P2Pos, -Pos)` | Extracts current player's position |

#### `ai.pl`
| Predicate | Description |
|-----------|-------------|
| `best_move(+Board, +Player, +P1Pos, +P2Pos, +Depth, -MovePos, -RemPos)` | AI entry point |
| `alphabeta(+Board, +Player, +P1Pos, +P2Pos, +Depth, +Alpha, +Beta, -Val, -BM, -BR)` | Alpha-beta search |
| `minimax(+Board, +Player, +P1Pos, +P2Pos, +Depth, -Value)` | Pure minimax (for testing) |
| `evaluate(+Board, +P1Pos, +P2Pos, -Value)` | Mobility + centrality heuristic |
| `all_move_pairs(+Board, +Player, +P1Pos, +P2Pos, -Pairs)` | Full (move, remove) pair list |
| `order_pairs(+Pairs, +Board, +Player, +P1Pos, +P2Pos, -Ordered)` | Heuristic move ordering |

#### `game.pl`
| Predicate | Description |
|-----------|-------------|
| `play/0` | Top-level entry — shows menu and starts game |
| `game_loop(+Board, +Turn, +P1Pos, +P2Pos, +Mode, +Depth)` | Main game loop |
| `human_turn(...)` | Reads and validates human move+remove |
| `ai_turn(...)` | Calls `best_move` and applies result |
| `read_move(+Board, +FR, +FC, -TR, -TC)` | Prompts for pawn destination |
| `read_remove(+Board, +P1R, +P1C, +P2R, +P2C, -RR, -RC)` | Prompts for cell to remove |

---

## 8. How to Run

### Install SWI-Prolog

```bash
# macOS
brew install swi-prolog

# Ubuntu/Debian
sudo apt install swi-prolog

# Windows
# Download from https://www.swi-prolog.org/download/stable
```

### Run the game

```bash
# From the project root directory
swipl src/main.pl
```

The game starts automatically. You will see the main menu:

```
============================================================
  MAIN MENU
============================================================
  [1]  Human vs Human
  [2]  Human vs AI
  [3]  AI   vs AI
  [4]  Quit
```

**Input format:** All positions are entered as `Row/Col.` (with a trailing period).
Example: to move to row 2, column 3, type `2/3.` and press Enter.

### Run the tests

```bash
swipl -g "run_tests, halt" tests/tests.pl
```

Expected output: `All 33 tests passed`.

### Run a quick AI vs AI demo

```prolog
swipl src/main.pl
```

Then select `[3] AI vs AI`, choose a 3×3 board, and watch the AI play itself to completion.

---

## 9. Limitations and Known Issues

| Issue | Details |
|-------|---------|
| **Performance on open boards** | At depth 4, the first few moves of a 6×6 game can take 20–60 seconds because the branching factor is near its maximum (~264). The game accelerates as cells are removed. |
| **Input format** | All input must be valid Prolog terms terminated by a period (e.g., `2/3.`). Typing plain `2 3` or forgetting the period causes a parse error and the prompt repeats. |
| **No undo** | Moves cannot be taken back. Exit with Ctrl-C and restart. |
| **No transposition table** | Identical board positions reached via different move sequences are re-evaluated, which is wasteful. |
| **No iterative deepening** | The search always uses the fixed depth provided. Iterative deepening would allow a time-based cutoff. |
| **AI vs AI display** | In AI vs AI mode, both AIs print "Thinking..." without a visual progress indicator. For large boards at depth 6 this may appear to hang. |
| **No persistent state** | There is no save/load functionality. |

---

## 10. Learning Objectives Met

| Assignment objective | Where it is implemented |
|---------------------|------------------------|
| Represent game state in Prolog | `src/board.pl` — list-of-lists board, `Row/Col` positions |
| Implement game rules | `src/rules.pl` — `valid_move/5`, `valid_removes/6`, `game_over/4` |
| Implement minimax | `src/ai.pl` — `minimax/6` (pure minimax for small boards) |
| Implement alpha-beta pruning | `src/ai.pl` — `alphabeta/10` with depth limit |
| Implement evaluation heuristic | `src/ai.pl` — `evaluate/4` (mobility + centrality) |
| Human vs Human and Human vs AI modes | `src/game.pl` — `human_turn/7`, `ai_turn/8` |
| Generic NxN board | `src/board.pl` — `initial_board/2` with size parameter |
| Validate and test | `tests/tests.pl` — 33 PLUnit tests covering all modules |
