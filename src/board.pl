% ============================================================
%  board.pl  —  Board representation, creation, and display
%  ISOLA — Inteligência Artificial, ISEL 2025/2026
%
%  Board is a list of rows; each row is a list of atoms:
%    '.'  = free cell
%    'x'  = player 1 pawn
%    'o'  = player 2 pawn
%    '#'  = permanently removed cell
%
%  Positions are represented as the compound Row/Col (0-based).
% ============================================================

:- use_module(library(lists)).

%% initial_board(+Size, -Board)
%  Creates a Size×Size board filled with '.' (no pieces yet).
initial_board(Size, Board) :-
    length(Board, Size),
    maplist(make_row(Size), Board).

make_row(Size, Row) :-
    length(Row, Size),
    maplist(=('.'), Row).

%% board_size(+Board, -Size)
board_size(Board, Size) :- length(Board, Size).

%% get_cell(+Board, +Row, +Col, -Cell)
%  Retrieves the cell at Row/Col. Fails cleanly if out of bounds.
get_cell(Board, Row, Col, Cell) :-
    board_size(Board, Size),
    Row >= 0, Row < Size,
    Col >= 0, Col < Size,
    nth0(Row, Board, RowList),
    nth0(Col, RowList, Cell).

%% set_cell(+Board, +Row, +Col, +Value, -NewBoard)
%  Returns a new board with cell Row/Col replaced by Value.
%  Uses nth0/4 (the "rest" variant) to non-destructively replace.
set_cell(Board, Row, Col, Value, NewBoard) :-
    nth0(Row, Board, OldRow, RestRows),
    nth0(Col, OldRow, _, RestCols),
    nth0(Col, NewRow, Value, RestCols),
    nth0(Row, NewBoard, NewRow, RestRows).

%% empty_cell(+Cell)
%  True when Cell is the free-cell marker.
empty_cell('.').

%% all_cells(+Board, -Cells)
%  Cells is a list of all Row/Col positions on the board.
all_cells(Board, Cells) :-
    board_size(Board, Size),
    Max is Size - 1,
    findall(R/C, (between(0, Max, R), between(0, Max, C)), Cells).

%% display_board(+Board)
%  Pretty-prints the board with 0-based column headers and row labels.
%
%  Example (3×3):
%       0  1  2
%     +------
%  0 |  .  x  .
%  1 |  .  .  .
%  2 |  .  .  o
display_board(Board) :-
    board_size(Board, Size),
    Max is Size - 1,
    % Column header
    write('      '),
    print_col_header(0, Max),
    nl,
    % Divider
    write('    +'),
    print_divider(Size),
    nl,
    % Rows
    print_rows(Board, 0).

print_col_header(I, Max) :-
    ( I > Max
    -> true
    ;  format(' ~w ', [I]),
       Next is I + 1,
       print_col_header(Next, Max)
    ).

print_divider(0) :- !.
print_divider(N) :-
    write('---'),
    N1 is N - 1,
    print_divider(N1).

print_rows([], _).
print_rows([Row|Rest], I) :-
    format(' ~w  | ', [I]),
    print_row(Row),
    nl,
    Next is I + 1,
    print_rows(Rest, Next).

print_row([]).
print_row([Cell|Rest]) :-
    format(' ~w ', [Cell]),
    print_row(Rest).
