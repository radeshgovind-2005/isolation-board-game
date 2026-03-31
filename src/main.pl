% ============================================================
%  main.pl  —  Entry point for ISOLA
%  ISOLA — Inteligência Artificial, ISEL 2025/2026
%
%  HOW TO RUN
%  ----------
%  From the project root:
%
%    swipl src/main.pl          (interactive, starts game)
%    swipl -g play src/main.pl  (explicit entry predicate)
%
%  HOW TO RUN TESTS
%  ----------------
%    swipl -g "run_tests, halt" tests/tests.pl
%
%  FILE STRUCTURE
%  --------------
%    src/board.pl  — board representation, display
%    src/rules.pl  — move legality, apply_move, game_over
%    src/ai.pl     — minimax, alpha-beta, evaluation
%    src/game.pl   — game loop, menus, human/AI turn handlers
%    src/main.pl   — this file (entry point)
%    tests/tests.pl — PLUnit tests
% ============================================================

:- use_module(library(lists)).

% Load modules in dependency order.
% ensure_loaded/1 resolves paths relative to this file's directory,
% so 'board.pl' resolves to src/board.pl regardless of where swipl
% is invoked from.
:- ensure_loaded('board.pl').
:- ensure_loaded('rules.pl').
:- ensure_loaded('ai.pl').
:- ensure_loaded('game.pl').

%% :- initialization(play, main)
%  When this file is loaded as the top-level script (swipl main.pl),
%  automatically call play/0.
:- initialization(play, main).
