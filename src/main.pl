% ============================================================
%  ISOLA — Inteligência Artificial, ISEL 2025/2026
%  ai.pl  —  Game engine, UI, and AI (minimax / alpha-beta)
%
%  Companion file: board.pl  (board creation, display, update)
%
%  HOW TO RUN:
%    $ swipl -g play src/main.pl
%   $ swipl -g "load_files(['src/main.pl', 'tests.pl']), run_tests, halt"
% ============================================================

:- use_module(library(lists)).
:- consult('board.pl').

% ============================================================
%  SECTION 1 — TERMINAL HELPERS
%  We keep all I/O helpers together so the rest of the code
%  stays free of write/format noise.
% ============================================================

% clear_screen/0  — ANSI escape to wipe the terminal
clear_screen :- write('\033[2J\033[H'), flush_output.

% separator/0  — a horizontal rule
separator :-
    write('============================================================'), nl.

% print_banner/0  — ASCII art title shown at startup
print_banner :-
    nl,
    write(' ___  ____  _____  _      __   '), nl,
    write('|_ _|/ ___||  _  || |    / /   '), nl,
    write(' | | \\___ \\| | | || |   / /    '), nl,
    write(' | |  ___) | |_| || |__/ /     '), nl,
    write('|___||____/|_____/|_____/      '), nl,
    nl,
    write('    Strategy Game — AI Project'), nl,
    write('    ISEL  |  Semestre Verão 2025/2026'), nl,
    nl.

% prompt_line/1  — prints a labelled prompt and reads a term
%   Note: the user must end input with a period (Prolog standard).
prompt_line(Label, Value) :-
    format("  ~w > ", [Label]),
    flush_output,
    read(Value).

% read_int_in_range/3  — keep asking until the user gives an
%   integer between Lo and Hi (inclusive).
read_int_in_range(Lo, Hi, N) :-
    read(Raw),
    ( integer(Raw), Raw >= Lo, Raw =< Hi
    -> N = Raw
    ;  format("  !! Please enter a number between ~w and ~w: ", [Lo, Hi]),
       flush_output,
       read_int_in_range(Lo, Hi, N)
    ).

% ============================================================
%  SECTION 2 — MENUS
% ============================================================

% play/0  — top-level entry point
play :-
    clear_screen,
    print_banner,
    main_menu.

% --- Main menu ---
print_main_menu :-
    separator,
    write('  MAIN MENU'), nl,
    separator,
    write('  [1]  Human vs Human'), nl,
    write('  [2]  Human vs AI   '), nl,
    write('  [3]  AI   vs AI    '), nl,
    write('  [4]  Quit          '), nl,
    separator,
    write('  Choose an option: '),
    flush_output.

main_menu :-
    print_main_menu,
    read_int_in_range(1, 4, Option),
    handle_main_menu(Option).

% Each clause handles one menu option — very idiomatic Prolog
handle_main_menu(1) :- select_size_and_start(human, human).
handle_main_menu(2) :- select_size_and_start(human, ai).
handle_main_menu(3) :- select_size_and_start(ai, ai).
handle_main_menu(4) :- goodbye.

% --- Board-size sub-menu ---
print_size_menu :-
    nl,
    separator,
    write('  SELECT BOARD SIZE'), nl,
    separator,
    write('  [1]  3 x 3  (tiny — good for testing)'), nl,
    write('  [2]  5 x 5  (small)                  '), nl,
    write('  [3]  6 x 6  (standard — recommended) '), nl,
    write('  [4]  7 x 7  (large)                  '), nl,
    write('  [5]  Custom size                      '), nl,
    separator,
    write('  Choose: '),
    flush_output.

% size_choice/2  — maps menu index → board dimension
size_choice(1, 3).
size_choice(2, 5).
size_choice(3, 6).
size_choice(4, 7).
size_choice(5, Custom) :-
    write('  Enter board size (3-12): '), flush_output,
    read_int_in_range(3, 12, Custom).

select_size(Size) :-
    print_size_menu,
    read_int_in_range(1, 5, Choice),
    size_choice(Choice, Size).

% --- AI depth sub-menu (shown only when AI is playing) ---
select_depth(Depth) :-
    nl,
    separator,
    write('  SELECT AI SEARCH DEPTH'), nl,
    separator,
    write('  [1]  Depth 2 — fast   (weak)        '), nl,
    write('  [2]  Depth 4 — medium (recommended) '), nl,
    write('  [3]  Depth 6 — slow   (strong)      '), nl,
    separator,
    write('  Choose: '), flush_output,
    read_int_in_range(1, 3, C),
    depth_choice(C, Depth).

depth_choice(1, 2).
depth_choice(2, 4).
depth_choice(3, 6).

% select_size_and_start/2  — chains size & depth selection then kicks off
select_size_and_start(M1, M2) :-
    select_size(Size),
    ( (M1 = ai ; M2 = ai) -> select_depth(Depth) ; Depth = 4 ),
    start_game(Size, M1, M2, Depth).

% ============================================================
%  SECTION 3 — GAME STATE
%
%  We represent all mutable information as a single compound
%  term so it is easy to pass around without global variables:
%
%    state(Board, Pos1, Pos2, Turn, Mode, Depth)
%
%    Board  — list-of-lists (from board.pl)
%    Pos1   — Row/Col of player 1  (symbol: x)
%    Pos2   — Row/Col of player 2  (symbol: o)
%    Turn   — 1 or 2 (whose move it is)
%    Mode   — mode(M1, M2) where each M is `human` or `ai`
%    Depth  — alpha-beta search depth limit
% ============================================================

% start_game/4  — build the initial state and enter the loop
start_game(Size, M1, M2, Depth) :-
    initial_board(Size, Board),
    Last is Size - 1,
    Pos1 = 0/0,           % Player 1 starts top-left
    Pos2 = Last/Last,     % Player 2 starts bottom-right
    update_board(Board,  Pos1, x, B1),
    update_board(B1,     Pos2, o, B2),
    State = state(B2, Pos1, Pos2, 1, mode(M1, M2), Depth),
    clear_screen,
    game_loop(State).

% ============================================================
%  SECTION 4 — DISPLAY
% ============================================================

display_state(state(Board, _Pos1, _Pos2, Turn, _Mode, _Depth)) :-
    nl, separator,
    format("  TURN: Player ~w~n", [Turn]),
    separator,
    nl,
    display_board(Board),   % from board.pl
    nl.

% ============================================================
%  SECTION 5 — GAME LOOP
% ============================================================

game_loop(State) :-
    display_state(State),
    ( game_over(State, Winner)
    ->  announce_winner(Winner, State)
    ;   take_turn(State, NewState),
        game_loop(NewState)
    ).

% ============================================================
%  SECTION 6 — WIN / LOSS DETECTION
%
%  A player loses when they have NO valid moves.
%  We detect this before the player's turn begins.
% ============================================================

% game_over/2  — succeeds when the current player has no moves
game_over(State, Winner) :-
    State = state(Board, Pos1, Pos2, Turn, _Mode, _Depth),
    ( Turn =:= 1 -> CurrentPos = Pos1 ; CurrentPos = Pos2 ),
    \+ valid_move(Board, CurrentPos, _),
    Other is 3 - Turn,     % 3-1=2, 3-2=1
    Winner = Other.

% valid_move/3  — Board × FromPos → ToPos
%   A move is valid if the destination is adjacent, on the board,
%   and currently holds '.' (empty).
valid_move(Board, Row/Col, NRow/NCol) :-
    length(Board, Size),
    Max is Size - 1,
    member(DR, [-1, 0, 1]),
    member(DC, [-1, 0, 1]),
    \+ (DR =:= 0, DC =:= 0),          % not the same cell
    NRow is Row + DR,
    NCol is Col + DC,
    NRow >= 0, NRow =< Max,
    NCol >= 0, NCol =< Max,
    nth0(NRow, Board, TargetRow),
    nth0(NCol, TargetRow, Cell),
    Cell = '.'.                        % must be empty

% valid_remove/4  — Board × Pos1 × Pos2 → RemovePos
%   Any '.' cell that is not occupied by either pawn.
valid_remove(Board, Pos1, Pos2, RRow/RCol) :-
    length(Board, Size),
    Max is Size - 1,
    between(0, Max, RRow),
    between(0, Max, RCol),
    \+ (RRow/RCol = Pos1),
    \+ (RRow/RCol = Pos2),
    nth0(RRow, Board, TargetRow),
    nth0(RCol, TargetRow, Cell),
    Cell = '.'.

% ============================================================
%  SECTION 7 — TURN EXECUTION
% ============================================================

% take_turn/2  — dispatch to human or AI handler
take_turn(State, NewState) :-
    State = state(_Board, _Pos1, _Pos2, Turn, mode(M1, M2), _Depth),
    ( Turn =:= 1 -> Mode = M1 ; Mode = M2 ),
    execute_turn(Mode, Turn, State, NewState).

% --- Human turn ---
execute_turn(human, Turn, State, NewState) :-
    State = state(Board, Pos1, Pos2, Turn, Mode, Depth),
    format("~n  --- PLAYER ~w's TURN (human) ---~n", [Turn]),

    % Step 1: Move the pawn
    ( Turn =:= 1 -> CurrentPos = Pos1 ; CurrentPos = Pos2 ),
    human_move(Board, CurrentPos, NewPos),

    % Apply the move on the board
    ( Turn =:= 1
    ->  update_board(Board,  Pos1,   '.', B_cleared),
        update_board(B_cleared, NewPos, x,   B_moved),
        NewPos1 = NewPos, NewPos2 = Pos2
    ;   update_board(Board,  Pos2,   '.', B_cleared),
        update_board(B_cleared, NewPos, o,   B_moved),
        NewPos1 = Pos1, NewPos2 = NewPos
    ),

    % Display board after moving, before removing
    nl, separator,
    write('  Board after move:'), nl, separator, nl,
    display_board(B_moved), nl,

    % Step 2: Remove a cell
    human_remove(B_moved, NewPos1, NewPos2, RemPos),
    update_board(B_moved, RemPos, '#', B_final),

    % Flip the turn: 1→2, 2→1
    NextTurn is 3 - Turn,
    NewState = state(B_final, NewPos1, NewPos2, NextTurn, Mode, Depth).

% --- AI turn ---
execute_turn(ai, Turn, State, NewState) :-
    format("~n  --- PLAYER ~w's TURN (AI) ---~n", [Turn]),
    write('  Thinking...'), nl,
    % TODO: replace stub with alpha_beta call
    ai_move(State, NewState).

% ============================================================
%  SECTION 8 — HUMAN INPUT HANDLING
% ============================================================

% human_move/3  — ask and validate until input is legal
human_move(Board, CurrentPos, NewPos) :-
    format("  Your pawn is at ~w~n", [CurrentPos]),
    write('  Move to (Row/Col, e.g. 1/2): '), flush_output,
    read(NewPos),
    ( valid_move(Board, CurrentPos, NewPos)
    ->  true
    ;   write('  !! Invalid move. Try again.'), nl,
        human_move(Board, CurrentPos, NewPos)
    ).

% human_remove/4  — ask and validate a removal cell
human_remove(Board, Pos1, Pos2, RemPos) :-
    write('  Remove a cell (Row/Col, e.g. 3/4): '), flush_output,
    read(RemPos),
    ( valid_remove(Board, Pos1, Pos2, RemPos)
    ->  true
    ;   write('  !! Invalid removal. Try again.'), nl,
        human_remove(Board, Pos1, Pos2, RemPos)
    ).

% ============================================================
%  SECTION 9 — AI: MINIMAX / ALPHA-BETA
%
%  Structure:
%    ai_move/2         — entry point, picks best move
%    alpha_beta/7      — recursive alpha-beta search
%    evaluate/2        — static board evaluation heuristic
%    all_moves/2       — generates all (Move, Remove) pairs
% ============================================================

% --- Entry point ---
ai_move(State, NewState) :-
    State = state(_Board, _Pos1, _Pos2, Turn, Mode, Depth),
    alpha_beta(State, Depth, -10000, 10000, BestMove, _Score),
    apply_move(State, BestMove, NewState0),
    NextTurn is 3 - Turn,
    NewState = state(B, P1, P2, NextTurn, Mode, Depth),
    NewState0 = state(B, P1, P2, _, _, _),
    format("  AI played: ~w~n", [BestMove]).

% --- Alpha-Beta Search ---
%   alpha_beta(+State, +Depth, +Alpha, +Beta, -BestMove, -Score)
%
%   At depth 0 (or terminal), return the static evaluation.
%   Otherwise generate all moves, recurse, and prune.

alpha_beta(State, 0, _Alpha, _Beta, none, Score) :-
    !,
    evaluate(State, Score).

alpha_beta(State, _Depth, _Alpha, _Beta, none, Score) :-
    game_over(State, _Winner),
    !,
    evaluate(State, Score).

alpha_beta(State, Depth, Alpha, Beta, BestMove, BestScore) :-
    State = state(_Board, _Pos1, _Pos2, Turn, _Mode, _AiDepth),
    all_moves(State, Moves),
    NextDepth is Depth - 1,
    ( Turn =:= 1      % Maximising player
    -> best_max(Moves, State, NextDepth, Alpha, Beta, nil, BestMove, BestScore)
    ;  best_min(Moves, State, NextDepth, Alpha, Beta, nil, BestMove, BestScore)
    ).

% best_max/8  — iterate moves, keep the one with highest score
best_max([], _State, _D, _A, _B, Best-Score, Best, Score) :- !.
best_max([Move|Rest], State, Depth, Alpha, Beta, _Acc, BestMove, BestScore) :-
    apply_move(State, Move, NewState),
    alpha_beta(NewState, Depth, Alpha, Beta, _, Score),
    Score > Alpha,
    !,
    NewAlpha is max(Score, Alpha),
    ( NewAlpha >= Beta
    ->  BestMove = Move, BestScore = Score   % Beta cutoff
    ;   best_max(Rest, State, Depth, NewAlpha, Beta, Move-Score, BestMove, BestScore)
    ).
best_max([_|Rest], State, Depth, Alpha, Beta, Acc, BestMove, BestScore) :-
    best_max(Rest, State, Depth, Alpha, Beta, Acc, BestMove, BestScore).

% best_min/8  — iterate moves, keep the one with lowest score
best_min([], _State, _D, _A, _B, Best-Score, Best, Score) :- !.
best_min([Move|Rest], State, Depth, Alpha, Beta, _Acc, BestMove, BestScore) :-
    apply_move(State, Move, NewState),
    alpha_beta(NewState, Depth, Alpha, Beta, _, Score),
    Score < Beta,
    !,
    NewBeta is min(Score, Beta),
    ( Alpha >= NewBeta
    ->  BestMove = Move, BestScore = Score   % Alpha cutoff
    ;   best_min(Rest, State, Depth, Alpha, NewBeta, Move-Score, BestMove, BestScore)
    ).
best_min([_|Rest], State, Depth, Alpha, Beta, Acc, BestMove, BestScore) :-
    best_min(Rest, State, Depth, Alpha, Beta, Acc, BestMove, BestScore).

% --- Move generation ---
%   A move is a pair: move(ToPos, RemovePos)
all_moves(State, Moves) :-
    State = state(Board, Pos1, Pos2, Turn, _Mode, _Depth),
    ( Turn =:= 1 -> CurrentPos = Pos1 ; CurrentPos = Pos2 ),
    findall(
        move(NewPos, RemPos),
        (   valid_move(Board, CurrentPos, NewPos),
            % Temporarily apply the pawn move to get intermediate board
            ( Turn =:= 1
            ->  update_board(Board, Pos1, '.', Bc),
                update_board(Bc, NewPos, x, Bm),
                NP1 = NewPos, NP2 = Pos2
            ;   update_board(Board, Pos2, '.', Bc),
                update_board(Bc, NewPos, o, Bm),
                NP1 = Pos1, NP2 = NewPos
            ),
            valid_remove(Bm, NP1, NP2, RemPos)
        ),
        Moves
    ).

% --- Apply a move to get the new state ---
apply_move(State, move(NewPos, RemPos), NewState) :-
    State = state(Board, Pos1, Pos2, Turn, Mode, Depth),
    ( Turn =:= 1
    ->  update_board(Board, Pos1, '.', Bc),
        update_board(Bc, NewPos, x, Bm),
        NP1 = NewPos, NP2 = Pos2
    ;   update_board(Board, Pos2, '.', Bc),
        update_board(Bc, NewPos, o, Bm),
        NP1 = Pos1, NP2 = NewPos
    ),
    update_board(Bm, RemPos, '#', Bfinal),
    NextTurn is 3 - Turn,
    NewState = state(Bfinal, NP1, NP2, NextTurn, Mode, Depth).

% ============================================================
%  SECTION 10 — EVALUATION HEURISTIC
%
%  A simple mobility heuristic:
%    Score = (moves available to player 1)
%          - (moves available to player 2)
%
%  From player 1's perspective, positive = good for player 1.
%  The alpha-beta treats player 1 as MAX, player 2 as MIN.
% ============================================================

evaluate(state(Board, Pos1, Pos2, _Turn, _Mode, _Depth), Score) :-
    findall(_, valid_move(Board, Pos1, _), M1), length(M1, S1),
    findall(_, valid_move(Board, Pos2, _), M2), length(M2, S2),
    Score is S1 - S2.

% ============================================================
%  SECTION 11 — END-GAME
% ============================================================

announce_winner(Winner, state(Board, _, _, _, _, _)) :-
    nl, display_board(Board), nl,
    separator,
    format("  *** PLAYER ~w WINS! Congratulations! ***~n", [Winner]),
    separator, nl,
    play_again.

play_again :-
    write('  Play again? (yes/no): '), flush_output,
    read(Answer),
    ( Answer = yes -> play
    ; Answer = no  -> goodbye
    ;   write('  Please answer yes or no.'), nl,
        play_again
    ).

goodbye :-
    nl,
    separator,
    write('  Thanks for playing ISOLA. Goodbye!'), nl,
    separator, nl,
    halt.

% ============================================================
%  END OF ai.pl
% ============================================================