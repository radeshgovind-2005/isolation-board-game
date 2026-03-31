% ============================================================
%  rules.pl  —  Game rules and move generation for ISOLA
%  ISOLA — Inteligência Artificial, ISEL 2025/2026
%
%  All positions are Row/Col compounds (0-based integers).
%  Player 1 uses symbol 'x', Player 2 uses symbol 'o'.
% ============================================================

:- use_module(library(lists)).
:- ensure_loaded('board.pl').

%% player_pos(+Player, +P1Pos, +P2Pos, -Pos)
%  Extracts the current player's position.
player_pos(1, P1Pos, _P2Pos, P1Pos).
player_pos(2, _P1Pos, P2Pos, P2Pos).

%% player_symbol(+Player, -Symbol)
player_symbol(1, x).
player_symbol(2, o).

%% valid_move(+Board, +FromRow, +FromCol, ?ToRow, ?ToCol)
%  A move is valid iff the destination is:
%    - exactly one step away in any of 8 directions (king move)
%    - within board bounds
%    - an empty cell ('.')
%
%  Works as both a GENERATOR (ToRow/ToCol unbound: enumerates
%  all reachable cells) and a CHECKER (ToRow/ToCol bound).
valid_move(Board, FromR, FromC, ToR, ToC) :-
    board_size(Board, Size),
    Max is Size - 1,
    member(DR, [-1, 0, 1]),
    member(DC, [-1, 0, 1]),
    \+ (DR =:= 0, DC =:= 0),
    ToR is FromR + DR,
    ToC is FromC + DC,
    ToR >= 0, ToR =< Max,
    ToC >= 0, ToC =< Max,
    get_cell(Board, ToR, ToC, '.').

%% valid_moves(+Board, +Row, +Col, -Moves)
%  Moves is a list of TR/TC positions reachable from Row/Col.
valid_moves(Board, Row, Col, Moves) :-
    findall(TR/TC, valid_move(Board, Row, Col, TR, TC), Moves).

%% valid_removes(+Board, +P1R, +P1C, +P2R, +P2C, -Removes)
%  Removes is the list of R/C positions that may be removed:
%  any empty cell that is not occupied by either pawn.
valid_removes(Board, P1R, P1C, P2R, P2C, Removes) :-
    board_size(Board, Size),
    Max is Size - 1,
    findall(R/C,
        (   between(0, Max, R),
            between(0, Max, C),
            \+ (R =:= P1R, C =:= P1C),
            \+ (R =:= P2R, C =:= P2C),
            get_cell(Board, R, C, '.')
        ),
        Removes).

%% apply_move(+Board, +FromR, +FromC, +ToR, +ToC, -NewBoard)
%  Moves the piece from From to To, leaving '.' at the source.
apply_move(Board, FromR, FromC, ToR, ToC, NewBoard) :-
    get_cell(Board, FromR, FromC, Piece),
    set_cell(Board, FromR, FromC, '.', B1),
    set_cell(B1, ToR, ToC, Piece, NewBoard).

%% apply_remove(+Board, +Row, +Col, -NewBoard)
%  Permanently marks cell Row/Col as removed ('#').
apply_remove(Board, Row, Col, NewBoard) :-
    set_cell(Board, Row, Col, '#', NewBoard).

%% game_over(+Board, +Player, +P1Pos, +P2Pos)
%  True when Player has no valid moves (Player loses).
game_over(Board, Player, P1Pos, P2Pos) :-
    player_pos(Player, P1Pos, P2Pos, CR/CC),
    \+ valid_move(Board, CR, CC, _, _).
