:- encoding(utf8).
% Chapter 05 completeness: Prolog channel.
% Bisection on exact rationals (completeness as an algorithm) and a
% constructive rational-between proof.
% Run: swipl -q -f 05_completeness.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

% One bisection step on the invariant A^2 < 2 =< B^2.
bisect_step(A-B, A1-B1) :-
    A * A < 2, 2 =< B * B,
    M is (A + B) rdiv 2,
    (   M * M < 2
    ->  A1 = M, B1 = B
    ;   A1 = A, B1 = M).

% Iterate K steps from 1-2.
bisect(K, A-B) :-
    bisect_go(K, 1 rdiv 1 - 2 rdiv 1, A-B).

bisect_go(0, AB, AB) :- !.
bisect_go(K, AB, Out) :-
    K > 0,
    K1 is K - 1,
    bisect_step(AB, AB1),
    bisect_go(K1, AB1, Out).

% Constructive rational between two floats.
rational_between(X, Y, M rdiv N) :-
    X < Y,
    N is ceiling(2 / (Y - X)),
    M is floor(X * N) + 1,
    R is M rdiv N,
    X < R, R < Y.

main :-
    format("==== 05 completeness ====~n", []),

    % 1. Bisection: after 40 steps the gap is exactly 2^-40.
    verify(bisect(40, A40 - B40)),
    verify(B40 - A40 =:= 1 rdiv (2^40)),
    verify(A40 * A40 < 2),
    verify(2 =< B40 * B40),
    format("after 40 bisections: gap = 2^-40, a^2 < 2 =< b^2~n", []),

    % 2. Gap halves every step (Archimedean as an algorithm).
    verify(forall(member(K, [10, 20, 40]),
                  (bisect(K, A - B), B - A =:= 1 rdiv (2^K)))),
    format("gap = 2^-k verified at k = 10,20,40~n", []),

    % 3. Rational density, constructive.
    verify(rational_between(1.4142135, 1.4142136, R)),
    format("rational between 1.4142135 and 1.4142136: ~w~n", [R]),

    format("END ====~n", []).
