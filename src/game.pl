% ============================================================
%  game.pl  —  Game loop, menus, and human/AI turn handling
%  ISOLA — Inteligência Artificial, ISEL 2025/2026
%
%  Input convention: positions are entered as Row/Col (e.g. 1/2.)
%  The trailing period is required by Prolog's read/1.
% ============================================================

:- use_module(library(lists)).
:- ensure_loaded('ai.pl').      % also loads rules.pl and board.pl

% ============================================================
%  ENTRY POINT
% ============================================================

%% play/0
%  Top-level predicate.  Start the game from here.
play :-
    clear_screen,
    print_banner,
    main_menu.

% ============================================================
%  TERMINAL HELPERS
% ============================================================

clear_screen :- write('\033[2J\033[H'), flush_output.

separator :-
    write('============================================================'), nl.

print_banner :-
    nl,
    write(' ___  ____  _____  _      __   '), nl,
    write('|_ _|/ ___||  _  || |    / /   '), nl,
    write(' | | \\___ \\| | | || |   / /    '), nl,
    write(' | |  ___) | |_| || |__/ /     '), nl,
    write('|___||____/|_____/|_____/      '), nl, nl,
    write('    Strategy Game  —  ISEL AI Project'), nl,
    write('    Semestre Verão 2025/2026'), nl, nl.

% ============================================================
%  MENUS
% ============================================================

main_menu :-
    separator,
    write('  MAIN MENU'), nl,
    separator,
    write('  [1]  Human vs Human'), nl,
    write('  [2]  Human vs AI   '), nl,
    write('  [3]  AI   vs AI    '), nl,
    write('  [4]  Quit          '), nl,
    separator,
    write('  Choose (1-4): '), flush_output,
    read_int(1, 4, Choice),
    handle_menu(Choice).

handle_menu(1) :- setup_game(human, human).
handle_menu(2) :- setup_game(human, ai).
handle_menu(3) :- setup_game(ai, ai).
handle_menu(4) :- goodbye.

setup_game(M1, M2) :-
    nl, separator,
    write('  BOARD SIZE'), nl,
    separator,
    write('  [1]  3x3  (tiny — for testing)'), nl,
    write('  [2]  5x5  (small)             '), nl,
    write('  [3]  6x6  (standard)          '), nl,
    write('  [4]  Custom size (3-12)        '), nl,
    separator,
    write('  Choose: '), flush_output,
    read_int(1, 4, SC),
    size_from_choice(SC, Size),
    ( (M1 = ai ; M2 = ai)
    ->  select_depth(Depth)
    ;   Depth = 4
    ),
    start_game(Size, M1, M2, Depth).

size_from_choice(1, 3).
size_from_choice(2, 5).
size_from_choice(3, 6).
size_from_choice(4, Size) :-
    write('  Enter size (3-12): '), flush_output,
    read_int(3, 12, Size).

select_depth(Depth) :-
    nl, separator,
    write('  AI SEARCH DEPTH'), nl,
    separator,
    write('  [1]  Depth 2  (fast, weak)'), nl,
    write('  [2]  Depth 4  (recommended)'), nl,
    write('  [3]  Depth 6  (slow, strong)'), nl,
    separator,
    write('  Choose: '), flush_output,
    read_int(1, 3, C),
    depth_from_choice(C, Depth).

depth_from_choice(1, 2).
depth_from_choice(2, 4).
depth_from_choice(3, 6).

% ============================================================
%  GAME INITIALISATION
% ============================================================

%% start_game(+Size, +Mode1, +Mode2, +Depth)
%  Builds the initial board and kicks off the game loop.
start_game(Size, M1, M2, Depth) :-
    initial_board(Size, EmptyBoard),
    Last is Size - 1,
    P1Pos = 0/0,
    P2Pos = Last/Last,
    set_cell(EmptyBoard, 0,    0,    x, B1),
    set_cell(B1,         Last, Last, o, Board),
    clear_screen,
    game_loop(Board, 1, P1Pos, P2Pos, mode(M1, M2), Depth).

% ============================================================
%  GAME LOOP
% ============================================================

%% game_loop(+Board, +Turn, +P1Pos, +P2Pos, +Mode, +Depth)
%  Displays the board, checks for a winner, then takes a turn.
game_loop(Board, Turn, P1Pos, P2Pos, Mode, Depth) :-
    display_game(Board, Turn),
    ( game_over(Board, Turn, P1Pos, P2Pos)
    ->  Other is 3 - Turn,
        announce_winner(Other, Board)
    ;   execute_turn(Board, Turn, P1Pos, P2Pos, Mode, Depth,
                     NewBoard, NewP1, NewP2),
        Next is 3 - Turn,
        game_loop(NewBoard, Next, NewP1, NewP2, Mode, Depth)
    ).

display_game(Board, Turn) :-
    nl, separator,
    ( Turn =:= 1 -> Symbol = x ; Symbol = o ),
    format("  TURN: Player ~w (~w)~n", [Turn, Symbol]),
    separator, nl,
    display_board(Board), nl.

% ============================================================
%  TURN DISPATCH
% ============================================================

%% execute_turn(+Board, +Turn, +P1Pos, +P2Pos, +Mode, +Depth,
%%              -NewBoard, -NewP1Pos, -NewP2Pos)
execute_turn(Board, Turn, P1Pos, P2Pos, mode(M1, M2), Depth,
             NewBoard, NewP1, NewP2) :-
    ( Turn =:= 1 -> TurnMode = M1 ; TurnMode = M2 ),
    ( TurnMode = human
    ->  human_turn(Board, Turn, P1Pos, P2Pos, NewBoard, NewP1, NewP2)
    ;   ai_turn(Board, Turn, P1Pos, P2Pos, Depth, NewBoard, NewP1, NewP2)
    ).

% ============================================================
%  HUMAN TURN
% ============================================================

%% human_turn(+Board, +Turn, +P1Pos, +P2Pos,
%%            -NewBoard, -NewP1Pos, -NewP2Pos)
human_turn(Board, Turn, P1Pos, P2Pos, NewBoard, NewP1, NewP2) :-
    format("~n  --- PLAYER ~w's TURN (human) ---~n", [Turn]),
    player_pos(Turn, P1Pos, P2Pos, CR/CC),
    % Step 1: Move the pawn
    read_move(Board, CR, CC, TR, TC),
    apply_move(Board, CR, CC, TR, TC, BoardAfterMove),
    update_positions(Turn, P1Pos, P2Pos, TR/TC, NewP1Tmp, NewP2Tmp),
    % Show board after move before removal
    nl, separator,
    write('  Board after move (before removal):'), nl,
    separator, nl,
    display_board(BoardAfterMove), nl,
    % Step 2: Remove a cell
    NewP1Tmp = NP1R/NP1C,
    NewP2Tmp = NP2R/NP2C,
    read_remove(BoardAfterMove, NP1R, NP1C, NP2R, NP2C, RR, RC),
    apply_remove(BoardAfterMove, RR, RC, NewBoard),
    NewP1 = NewP1Tmp,
    NewP2 = NewP2Tmp.

%% update_positions(+Player, +P1Pos, +P2Pos, +NewPos, -NewP1, -NewP2)
update_positions(1, _P1Pos, P2Pos, NewPos, NewPos, P2Pos).
update_positions(2, P1Pos, _P2Pos, NewPos, P1Pos, NewPos).

% ============================================================
%  AI TURN
% ============================================================

%% ai_turn(+Board, +Turn, +P1Pos, +P2Pos, +Depth,
%%         -NewBoard, -NewP1Pos, -NewP2Pos)
ai_turn(Board, Turn, P1Pos, P2Pos, Depth, NewBoard, NewP1, NewP2) :-
    format("~n  --- PLAYER ~w's TURN (AI) ---~n", [Turn]),
    write('  Thinking...'), nl, flush_output,
    best_move(Board, Turn, P1Pos, P2Pos, Depth, MR/MC, RR/RC),
    format("  AI moves pawn to ~w/~w~n",  [MR, MC]),
    format("  AI removes cell  ~w/~w~n",  [RR, RC]),
    player_pos(Turn, P1Pos, P2Pos, CR/CC),
    apply_move(Board, CR, CC, MR, MC, B1),
    apply_remove(B1, RR, RC, NewBoard),
    update_positions(Turn, P1Pos, P2Pos, MR/MC, NewP1, NewP2).

% ============================================================
%  HUMAN INPUT
% ============================================================

%% read_move(+Board, +FromR, +FromC, -ToR, -ToC)
%  Prompts for a pawn destination.  Re-prompts on invalid input.
%  The user types:  Row/Col.   (e.g.  2/3.)
read_move(Board, FromR, FromC, ToR, ToC) :-
    format("  Your pawn is at ~w/~w~n", [FromR, FromC]),
    valid_moves(Board, FromR, FromC, Available),
    format("  Valid destinations: ~w~n", [Available]),
    write('  Move to (Row/Col e.g. 1/2): '), flush_output,
    catch(read(R/C), _, (write('  !! Parse error.'), nl,
                         read_move(Board, FromR, FromC, ToR, ToC))),
    ( integer(R), integer(C), valid_move(Board, FromR, FromC, R, C)
    ->  ToR = R, ToC = C
    ;   write('  !! Invalid move. Try again.'), nl,
        read_move(Board, FromR, FromC, ToR, ToC)
    ).

%% read_remove(+Board, +P1R, +P1C, +P2R, +P2C, -RemR, -RemC)
%  Prompts for a cell to remove.  Re-prompts on invalid input.
read_remove(Board, P1R, P1C, P2R, P2C, RemR, RemC) :-
    write('  Remove a cell (Row/Col e.g. 3/4): '), flush_output,
    catch(read(R/C), _, (write('  !! Parse error.'), nl,
                         read_remove(Board, P1R, P1C, P2R, P2C, RemR, RemC))),
    ( integer(R), integer(C),
      valid_remove_single(Board, P1R, P1C, P2R, P2C, R, C)
    ->  RemR = R, RemC = C
    ;   write('  !! Invalid removal. Must be an empty cell not occupied by a pawn.'), nl,
        read_remove(Board, P1R, P1C, P2R, P2C, RemR, RemC)
    ).

%% valid_remove_single(+Board, +P1R, +P1C, +P2R, +P2C, +R, +C)
%  Single-cell version of the removal validity check.
valid_remove_single(Board, P1R, P1C, P2R, P2C, R, C) :-
    \+ (R =:= P1R, C =:= P1C),
    \+ (R =:= P2R, C =:= P2C),
    get_cell(Board, R, C, '.').

%% read_int(+Lo, +Hi, -N)
%  Reads an integer in the range [Lo, Hi]; re-prompts on bad input.
read_int(Lo, Hi, N) :-
    catch(read(Raw), _, Raw = invalid),
    ( integer(Raw), Raw >= Lo, Raw =< Hi
    ->  N = Raw
    ;   format("  !! Please enter a number between ~w and ~w: ", [Lo, Hi]),
        flush_output,
        read_int(Lo, Hi, N)
    ).

% ============================================================
%  END GAME
% ============================================================

announce_winner(Winner, Board) :-
    nl, display_board(Board), nl,
    separator,
    format("  *** PLAYER ~w WINS!  Congratulations! ***~n", [Winner]),
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
    nl, separator,
    write('  Thanks for playing ISOLA.  Goodbye!'), nl,
    separator, nl,
    halt.
