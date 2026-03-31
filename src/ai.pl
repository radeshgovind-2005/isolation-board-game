% ============================================================
%  ai.pl  —  Minimax and Alpha-Beta search for ISOLA
%  ISOLA — Inteligência Artificial, ISEL 2025/2026
%
%  Convention:
%    Player 1 ('x') is the MAX player — wants a HIGH score.
%    Player 2 ('o') is the MIN player — wants a LOW score.
%    The evaluation function always returns a value from
%    Player 1's perspective (positive = good for Player 1).
%
%    Terminal values:
%      +1000  Player 2 has no moves  → Player 1 wins
%      -1000  Player 1 has no moves  → Player 2 wins
%
%  The search treats each full turn (move pawn + remove cell)
%  as a single ply.  Branching factor ≈ 8 moves × N² removes.
%
%  best_move/7   — entry point (uses alpha-beta)
%  alphabeta/10  — depth-limited alpha-beta pruning
%  minimax/6     — pure minimax (for small boards / testing)
%  evaluate/4    — mobility + centrality heuristic
% ============================================================

:- use_module(library(lists)).
:- ensure_loaded('rules.pl').    % also loads board.pl

% ============================================================
%  ENTRY POINT
% ============================================================

%% best_move(+Board, +Player, +P1Pos, +P2Pos, +Depth,
%%           -MovePos, -RemPos)
%  Runs alpha-beta and returns the best (MovePos, RemPos) pair.
%  If all moves lead to defeat, returns the first legal move
%  rather than failing (we must play something).
best_move(Board, Player, P1Pos, P2Pos, Depth, MovePos, RemPos) :-
    alphabeta(Board, Player, P1Pos, P2Pos, Depth,
              -10000, 10000, _Val, BM, BR),
    ( BM = none
    ->  any_legal_move(Board, Player, P1Pos, P2Pos, MovePos, RemPos)
    ;   MovePos = BM, RemPos = BR
    ).

%% any_legal_move(+Board, +Player, +P1Pos, +P2Pos, -MovePos, -RemPos)
%  Fallback: picks the very first legal move (used when all moves
%  are losing; the AI still has to move).
any_legal_move(Board, Player, P1Pos, P2Pos, TR/TC, RR/RC) :-
    player_pos(Player, P1Pos, P2Pos, CR/CC),
    valid_move(Board, CR, CC, TR, TC),
    apply_move(Board, CR, CC, TR, TC, Bm),
    move_positions(Player, P1Pos, P2Pos, TR/TC, NP1R/NP1C, NP2R/NP2C),
    valid_removes(Bm, NP1R, NP1C, NP2R, NP2C, [RR/RC|_]),
    !.

% ============================================================
%  ALPHA-BETA SEARCH
% ============================================================

%% alphabeta(+Board, +Player, +P1Pos, +P2Pos, +Depth,
%%           +Alpha, +Beta, -Value, -BestMovePos, -BestRemPos)
%
%  Base case 1 — depth exhausted: return static evaluation.
alphabeta(Board, _Player, P1Pos, P2Pos, 0, _A, _B, Value, none, none) :-
    !,
    evaluate(Board, P1Pos, P2Pos, Value).

%  Base case 2 — current player has no legal moves: terminal loss.
alphabeta(Board, Player, P1Pos, P2Pos, _D, _A, _B, Value, none, none) :-
    player_pos(Player, P1Pos, P2Pos, CR/CC),
    \+ valid_move(Board, CR, CC, _, _),
    !,
    terminal_value(Player, Value).

%  Recursive case — generate and search all (move, remove) pairs.
alphabeta(Board, Player, P1Pos, P2Pos, Depth, Alpha, Beta, Value, BM, BR) :-
    all_move_pairs(Board, Player, P1Pos, P2Pos, Pairs),
    order_pairs(Pairs, Board, Player, P1Pos, P2Pos, Ordered),
    NextDepth is Depth - 1,
    Other is 3 - Player,
    ( Player =:= 1
    ->  ab_max(Ordered, Board, Other, P1Pos, P2Pos, Player, NextDepth,
               Alpha, Beta, -10000, none, none, Value, BM, BR)
    ;   ab_min(Ordered, Board, Other, P1Pos, P2Pos, Player, NextDepth,
               Alpha, Beta, 10000, none, none, Value, BM, BR)
    ).

%% terminal_value(+Player, -Value)
%  If Player has no moves, that player loses.
terminal_value(1, -1000).   % Player 1 stuck → Player 2 wins
terminal_value(2,  1000).   % Player 2 stuck → Player 1 wins

% ============================================================
%  MAX NODE LOOP
%  ab_max(+Pairs, +Board, +Other, +P1Pos, +P2Pos, +CurPlayer,
%         +Depth, +Alpha, +Beta,
%         +BestVal, +BestM, +BestR, -Val, -BM, -BR)
% ============================================================

%  No more pairs: return accumulated best.
ab_max([], _, _, _, _, _, _, _, _, BV, BM, BR, BV, BM, BR).

ab_max([move(MPos, RPos)|Rest], Board, Other, P1Pos, P2Pos, CurPlayer, Depth,
       Alpha, Beta, BestVal, BestM, BestR, Val, BM, BR) :-
    apply_pair(Board, CurPlayer, P1Pos, P2Pos, MPos, RPos,
               NewBoard, NewP1, NewP2),
    alphabeta(NewBoard, Other, NewP1, NewP2, Depth, Alpha, Beta,
              ChildVal, _, _),
    % Update best: prefer strictly better, or first if none set yet.
    % Note: the OR condition must be in its own parentheses, otherwise
    % Prolog's operator precedence parses it as a bare disjunction.
    ( ( BestM = none ; ChildVal > BestVal )
    ->  NewBest = ChildVal, NewBM = MPos, NewBR = RPos
    ;   NewBest = BestVal, NewBM = BestM, NewBR = BestR
    ),
    NewAlpha is max(Alpha, NewBest),
    ( NewAlpha >= Beta
    ->  Val = NewBest, BM = NewBM, BR = NewBR          % beta cut-off
    ;   ab_max(Rest, Board, Other, P1Pos, P2Pos, CurPlayer, Depth,
               NewAlpha, Beta, NewBest, NewBM, NewBR, Val, BM, BR)
    ).

% ============================================================
%  MIN NODE LOOP
% ============================================================

ab_min([], _, _, _, _, _, _, _, _, BV, BM, BR, BV, BM, BR).

ab_min([move(MPos, RPos)|Rest], Board, Other, P1Pos, P2Pos, CurPlayer, Depth,
       Alpha, Beta, BestVal, BestM, BestR, Val, BM, BR) :-
    apply_pair(Board, CurPlayer, P1Pos, P2Pos, MPos, RPos,
               NewBoard, NewP1, NewP2),
    alphabeta(NewBoard, Other, NewP1, NewP2, Depth, Alpha, Beta,
              ChildVal, _, _),
    ( ( BestM = none ; ChildVal < BestVal )
    ->  NewBest = ChildVal, NewBM = MPos, NewBR = RPos
    ;   NewBest = BestVal, NewBM = BestM, NewBR = BestR
    ),
    NewBeta is min(Beta, NewBest),
    ( Alpha >= NewBeta
    ->  Val = NewBest, BM = NewBM, BR = NewBR          % alpha cut-off
    ;   ab_min(Rest, Board, Other, P1Pos, P2Pos, CurPlayer, Depth,
               Alpha, NewBeta, NewBest, NewBM, NewBR, Val, BM, BR)
    ).

% ============================================================
%  PURE MINIMAX (for small boards or educational comparison)
% ============================================================

%% minimax(+Board, +Player, +P1Pos, +P2Pos, +Depth, -Value)
minimax(Board, _Player, P1Pos, P2Pos, 0, Value) :-
    !,
    evaluate(Board, P1Pos, P2Pos, Value).

minimax(Board, Player, P1Pos, P2Pos, _D, Value) :-
    player_pos(Player, P1Pos, P2Pos, CR/CC),
    \+ valid_move(Board, CR, CC, _, _),
    !,
    terminal_value(Player, Value).

minimax(Board, Player, P1Pos, P2Pos, Depth, Value) :-
    all_move_pairs(Board, Player, P1Pos, P2Pos, Pairs),
    NextD is Depth - 1,
    Other is 3 - Player,
    maplist(minimax_child(Board, Player, Other, P1Pos, P2Pos, NextD),
            Pairs, ChildValues),
    ( Player =:= 1
    ->  max_list(ChildValues, Value)
    ;   min_list(ChildValues, Value)
    ).

minimax_child(Board, CurPlayer, Other, P1Pos, P2Pos, Depth,
              move(MPos, RPos), ChildVal) :-
    apply_pair(Board, CurPlayer, P1Pos, P2Pos, MPos, RPos,
               NewBoard, NewP1, NewP2),
    minimax(NewBoard, Other, NewP1, NewP2, Depth, ChildVal).

% ============================================================
%  MOVE GENERATION
% ============================================================

%% all_move_pairs(+Board, +Player, +P1Pos, +P2Pos, -Pairs)
%  Generates ALL valid (move, remove) pairs for Player as a list
%  of move(MovePos, RemovePos) terms.
all_move_pairs(Board, Player, P1Pos, P2Pos, Pairs) :-
    player_pos(Player, P1Pos, P2Pos, CR/CC),
    findall(
        move(TR/TC, RR/RC),
        (   valid_move(Board, CR, CC, TR, TC),
            apply_move(Board, CR, CC, TR, TC, Bmoved),
            move_positions(Player, P1Pos, P2Pos, TR/TC,
                           NP1R/NP1C, NP2R/NP2C),
            valid_removes(Bmoved, NP1R, NP1C, NP2R, NP2C, Removes),
            member(RR/RC, Removes)
        ),
        Pairs
    ).

%% move_positions(+Player, +P1Pos, +P2Pos, +NewPos,
%%                -NewP1R/NewP1C, -NewP2R/NewP2C)
%  After Player moves to NewPos, gives the updated pawn coordinates.
move_positions(1, _P1Pos, P2R/P2C, TR/TC, TR/TC, P2R/P2C).
move_positions(2, P1R/P1C, _P2Pos, TR/TC, P1R/P1C, TR/TC).

%% apply_pair(+Board, +Player, +P1Pos, +P2Pos,
%%            +MovePos, +RemPos,
%%            -NewBoard, -NewP1Pos, -NewP2Pos)
%  Applies a full turn: move pawn then remove a cell.
apply_pair(Board, Player, P1Pos, P2Pos, TR/TC, RR/RC,
           NewBoard, NewP1Pos, NewP2Pos) :-
    player_pos(Player, P1Pos, P2Pos, CR/CC),
    apply_move(Board, CR, CC, TR, TC, Bmoved),
    apply_remove(Bmoved, RR, RC, NewBoard),
    move_positions(Player, P1Pos, P2Pos, TR/TC, NewP1R/NewP1C, NewP2R/NewP2C),
    NewP1Pos = NewP1R/NewP1C,
    NewP2Pos = NewP2R/NewP2C.

% ============================================================
%  MOVE ORDERING
%  Heuristic: central moves first (reduces depth of good subtrees
%  and improves alpha-beta cut-off rate).
%  Removes: prefer cells adjacent to the opponent (cuts mobility).
% ============================================================

%% order_pairs(+Pairs, +Board, +Player, +P1Pos, +P2Pos, -Ordered)
order_pairs(Pairs, Board, Player, P1Pos, P2Pos, Ordered) :-
    board_size(Board, Size),
    Center is (Size - 1) / 2.0,
    % Opponent's position: for removes, target cells near opponent.
    ( Player =:= 1
    ->  P2Pos = OppR/OppC
    ;   P1Pos = OppR/OppC
    ),
    maplist(score_pair(Center, OppR, OppC), Pairs, Keyed),
    keysort(Keyed, Sorted),      % ascending: lowest score = best
    strip_keys(Sorted, Ordered).

%  score_pair: lower numeric score = higher priority.
%  Prefers: moves toward the centre, removes close to opponent.
score_pair(Center, OppR, OppC,
           move(MR/MC, RR/RC),
           Score-move(MR/MC, RR/RC)) :-
    MDR is abs(MR - Center), MDC is abs(MC - Center),
    MoveScore is MDR + MDC,                % smaller = more central
    RDR is abs(RR - OppR), RDC is abs(RC - OppC),
    RemScore is RDR + RDC,                 % smaller = closer to opponent
    Score is MoveScore * 3 - RemScore.     % weight moves > removes

strip_keys([], []).
strip_keys([_-V | T], [V | T2]) :- strip_keys(T, T2).

% ============================================================
%  EVALUATION FUNCTION
% ============================================================

%% evaluate(+Board, +P1Pos, +P2Pos, -Value)
%  Static evaluation from Player 1's (MAX) perspective.
%
%  Value = (P1 mobility - P2 mobility) * 10
%        + (P1 centrality - P2 centrality)
%
%  Mobility: number of legal moves available.
%  Centrality: how close to the board centre (higher = better).
%  The mobility term dominates; centrality breaks ties.
evaluate(Board, P1Pos, P2Pos, Value) :-
    P1Pos = P1R/P1C, P2Pos = P2R/P2C,
    valid_moves(Board, P1R, P1C, M1), length(M1, S1),
    valid_moves(Board, P2R, P2C, M2), length(M2, S2),
    board_size(Board, Size),
    Center is (Size - 1) / 2.0,
    centrality(P1R, P1C, Center, Cent1),
    centrality(P2R, P2C, Center, Cent2),
    Value is (S1 - S2) * 10 + (Cent1 - Cent2).

centrality(R, C, Center, Score) :-
    DR is abs(R - Center),
    DC is abs(C - Center),
    % Higher value = closer to centre.  Truncate to integer.
    Score is truncate((Center - DR) + (Center - DC)).
