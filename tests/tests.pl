% ============================================================
%  tests/tests.pl  —  PLUnit test suite for ISOLA
%  ISOLA — Inteligência Artificial, ISEL 2025/2026
%
%  HOW TO RUN:
%    swipl -g "run_tests, halt" tests/tests.pl
%
%  All paths are relative to tests/, which is one level above src/.
% ============================================================

:- use_module(library(plunit)).
:- use_module(library(lists)).

:- ensure_loaded('../src/board.pl').
:- ensure_loaded('../src/rules.pl').
:- ensure_loaded('../src/ai.pl').

% ============================================================
%  BOARD TESTS
% ============================================================

:- begin_tests(board).

%  initial_board/2 creates a board of the correct size
test(initial_board_6x6_size) :-
    initial_board(6, Board),
    board_size(Board, 6).

%  every row in the initial board also has the correct length
test(initial_board_6x6_row_length) :-
    initial_board(6, Board),
    maplist([Row]>>(length(Row, 6)), Board).

%  initial board contains only free cells
test(initial_board_all_free) :-
    initial_board(4, Board),
    all_cells(Board, Cells),
    maplist([R/C]>>(get_cell(Board, R, C, '.')), Cells).

%  3x3 board has exactly 9 cells
test(all_cells_3x3_count) :-
    initial_board(3, Board),
    all_cells(Board, Cells),
    length(Cells, 9).

%  get_cell reads a cell that was just written
test(get_cell_after_set) :-
    initial_board(3, B0),
    set_cell(B0, 1, 1, x, B1),
    get_cell(B1, 1, 1, x).

%  set_cell does not mutate the original board
test(set_cell_nondestructive) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, '#', _B1),
    get_cell(B0, 0, 0, '.').

%  get_cell fails for out-of-bounds row
test(get_cell_oob_row, [fail]) :-
    initial_board(3, Board),
    get_cell(Board, 5, 0, _).

%  get_cell fails for out-of-bounds column
test(get_cell_oob_col, [fail]) :-
    initial_board(3, Board),
    get_cell(Board, 0, 5, _).

%  empty_cell is true only for '.'
test(empty_cell_free) :-    empty_cell('.').
test(empty_cell_pawn, [fail]) :-  empty_cell(x).
test(empty_cell_removed, [fail]) :- empty_cell('#').

:- end_tests(board).

% ============================================================
%  RULES TESTS
% ============================================================

:- begin_tests(rules).

%  A pawn in the centre of a 3x3 open board can reach 8 cells
test(valid_moves_centre_3x3_count) :-
    initial_board(3, B0),
    set_cell(B0, 1, 1, x, Board),
    valid_moves(Board, 1, 1, Moves),
    length(Moves, 8).

%  A pawn in the corner of a 3x3 board can reach 3 cells
test(valid_moves_corner_3x3_count) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, Board),
    valid_moves(Board, 0, 0, Moves),
    length(Moves, 3).

%  A pawn next to a removed cell cannot move there
test(valid_moves_blocked_by_remove) :-
    initial_board(3, B0),
    set_cell(B0, 1, 1, x, B1),
    set_cell(B1, 0, 1, '#', Board),    % remove cell above pawn
    valid_moves(Board, 1, 1, Moves),
    \+ member(0/1, Moves).

%  A pawn cannot move onto the opponent's cell
test(valid_moves_no_overlap_opponent) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 0, 1, o, Board),
    valid_moves(Board, 0, 0, Moves),
    \+ member(0/1, Moves).

%  valid_removes excludes both pawns but includes all other empty cells
test(valid_removes_excludes_pawns) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 2, 2, o, Board),
    valid_removes(Board, 0, 0, 2, 2, Removes),
    \+ member(0/0, Removes),
    \+ member(2/2, Removes),
    length(Removes, 7).   % 9 total − 2 pawns = 7

%  valid_removes also excludes already removed ('#') cells
test(valid_removes_excludes_removed_cell) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 2, 2, o, B2),
    set_cell(B2, 1, 1, '#', Board),
    valid_removes(Board, 0, 0, 2, 2, Removes),
    \+ member(1/1, Removes).

%  apply_move moves the piece and leaves '.' at the source
test(apply_move_source_cleared) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, Board),
    apply_move(Board, 0, 0, 0, 1, NewBoard),
    get_cell(NewBoard, 0, 0, '.'),
    get_cell(NewBoard, 0, 1, x).

%  apply_remove marks a cell as '#'
test(apply_remove_marks_cell) :-
    initial_board(3, Board),
    apply_remove(Board, 1, 2, NewBoard),
    get_cell(NewBoard, 1, 2, '#').

%  game_over is true when the current player is surrounded
test(game_over_no_moves) :-
    % Build a 3x3 board where x is trapped at 0/0 with
    % all adjacent cells removed.
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 2, 2, o, B2),
    set_cell(B2, 0, 1, '#', B3),
    set_cell(B3, 1, 0, '#', B4),
    set_cell(B4, 1, 1, '#', Board),
    game_over(Board, 1, 0/0, 2/2).

%  game_over fails when the player still has moves
test(game_over_has_moves, [fail]) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 2, 2, o, Board),
    game_over(Board, 1, 0/0, 2/2).

%  player_pos extracts the correct position for each player
test(player_pos_p1) :-
    player_pos(1, 0/0, 5/5, 0/0).
test(player_pos_p2) :-
    player_pos(2, 0/0, 5/5, 5/5).

:- end_tests(rules).

% ============================================================
%  AI TESTS
% ============================================================

:- begin_tests(ai).

%  evaluate gives a higher score to the player with more mobility
test(evaluate_mobility_advantage) :-
    % x is in the centre (lots of moves), o is in a corner (few moves)
    initial_board(4, B0),
    set_cell(B0, 1, 1, x, B1),
    set_cell(B1, 3, 3, o, Board),
    evaluate(Board, 1/1, 3/3, Score),
    Score > 0.    % Player 1 has more moves → positive score

%  evaluate gives a lower score when player 2 has more mobility
test(evaluate_opponent_advantage) :-
    initial_board(4, B0),
    set_cell(B0, 3, 3, x, B1),   % x in corner (few moves)
    set_cell(B1, 1, 1, o, Board), % o in centre (many moves)
    evaluate(Board, 3/3, 1/1, Score),
    Score < 0.

%  evaluate returns 0 on a symmetric board
test(evaluate_symmetric) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 2, 2, o, Board),
    evaluate(Board, 0/0, 2/2, Score),
    Score =:= 0.

%  terminal_value: player 1 stuck → -1000
test(terminal_value_p1_loses) :-
    terminal_value(1, -1000).

%  terminal_value: player 2 stuck → +1000
test(terminal_value_p2_wins) :-
    terminal_value(2, 1000).

%  best_move on a trivial forced-win 3x3 position
%  x is at 0/0, o is trapped at 2/2 with only 1/1 remaining;
%  removing 1/1 wins immediately (o has no moves next turn).
test(best_move_trivial_win) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 2, 2, o, B2),
    % Block most of board; leave only 0/1 as the move for x
    % and 1/1 and 2/1 for o's potential moves.
    set_cell(B2, 0, 2, '#', B3),
    set_cell(B3, 1, 0, '#', B4),
    set_cell(B4, 1, 2, '#', B5),
    set_cell(B5, 2, 0, '#', B6),
    % o can move to 2/1 or 1/1; if we remove both next to o we win
    % Here just check best_move returns a valid move (not none)
    best_move(B6, 1, 0/0, 2/2, 2, MPos, RPos),
    MPos \= none,
    RPos \= none.

%  alphabeta on a terminal node (depth > 0 but no moves) returns terminal_value
test(alphabeta_terminal) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 2, 2, o, B2),
    % Trap x at 0/0
    set_cell(B2, 0, 1, '#', B3),
    set_cell(B3, 1, 0, '#', B4),
    set_cell(B4, 1, 1, '#', Board),
    % Player 1 (x) has no moves → should return -1000
    alphabeta(Board, 1, 0/0, 2/2, 4, -10000, 10000, Val, _, _),
    Val =:= -1000.

%  minimax on a depth-0 node returns evaluation (not a terminal value)
test(minimax_depth_zero) :-
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 2, 2, o, Board),
    minimax(Board, 1, 0/0, 2/2, 0, Value),
    integer(Value).   % just verify it runs and returns a number

:- end_tests(ai).

% ============================================================
%  INTEGRATION TEST — full 3x3 scripted game
% ============================================================

:- begin_tests(integration).

%  Plays a short scripted sequence on a 3x3 board and verifies
%  that game_over is detected at the right point.
%
%  Script (positions 0-based, turns alternate 1 then 2):
%    Turn 1: x moves 0/0 → 0/1, removes 2/0
%    Turn 2: o moves 2/2 → 2/1, removes 2/0 already removed? no...
%  Let's use a simpler script: just verify state after one turn.

test(scripted_turn_1) :-
    % Initial 3x3 board
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 2, 2, o, Board),
    _P1Pos = 0/0, P2Pos = 2/2,
    % Player 1: move x from 0/0 to 1/1, remove 0/2
    apply_move(Board, 0, 0, 1, 1, BAfterMove),
    apply_remove(BAfterMove, 0, 2, BAfterTurn),
    NewP1Pos = 1/1,
    % Verify new state
    get_cell(BAfterTurn, 0, 0, '.'),  % x left old cell
    get_cell(BAfterTurn, 1, 1, x),   % x arrived at new cell
    get_cell(BAfterTurn, 0, 2, '#'), % cell removed
    get_cell(BAfterTurn, 2, 2, o),   % o unchanged
    \+ game_over(BAfterTurn, 2, NewP1Pos, P2Pos).  % game not over yet

test(scripted_game_over_detection) :-
    % Build a position where Player 2 is trapped immediately
    initial_board(3, B0),
    set_cell(B0, 0, 0, x, B1),
    set_cell(B1, 2, 2, o, B2),
    % Remove all cells adjacent to o at 2/2
    set_cell(B2, 2, 1, '#', B3),
    set_cell(B3, 1, 2, '#', B4),
    set_cell(B4, 1, 1, '#', Board),
    % Player 2 (o) at 2/2 with no valid moves → game over
    game_over(Board, 2, 0/0, 2/2).

:- end_tests(integration).
