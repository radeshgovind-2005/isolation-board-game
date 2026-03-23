% Create a square board of Size x Size filled with '.'
initial_board(Size, Board) :-
    length(Board, Size),
    maplist(create_row(Size), Board).

create_row(Size, Row) :-
    length(Row, Size),
    maplist(=('.'), Row).

% Display the board with coordinates (0, 1, 2...) [cite: 39-46, 50-58]
display_board(Board) :-
    length(Board, Size),
    write('   '), % Offset for row numbers
    draw_header(0, Size), nl,
    draw_rows(Board, 0).

draw_header(Size, Size) :- !.
draw_header(I, Size) :-
    write(I), write(' '),
    Next is I + 1,
    draw_header(Next, Size).

draw_rows([], _).
draw_rows([Row|Rest], I) :-
    write(I), write('  '), % Print row index
    draw_line(Row),
    nl,
    Next is I + 1,
    draw_rows(Rest, Next).

draw_line([]).
draw_line([Cell|Rest]) :-
    write(Cell), write(' '),
    draw_line(Rest).

% Helper to update a cell (Row/Col) [cite: 48, 49]
update_board(Board, Row/Col, Value, NewBoard) :-
    nth0(Row, Board, OldRow, RestRows),
    nth0(Col, OldRow, _, RestCells),
    nth0(Col, NewRow, Value, RestCells),
    nth0(Row, NewBoard, NewRow, RestRows).