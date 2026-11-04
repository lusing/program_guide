:- encoding(utf8).
% Chapter 00 intro: Prolog channel.
% Exact rational arithmetic (rdiv) vs binary floats, finite evidence
% for the irrationality of sqrt(2), and a computable Archimedean property.
% Run: swipl -q -f 00_intro.pl -g main -t halt

% verify(+Goal): succeed silently, report and fail otherwise.
verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

verify_not(G) :-
    (   call(G)
    ->  format("FAILED (expected failure): ~w~n", [G]),
        fail
    ;   true
    ).

% No pair (M,N) with 1 =< N =< 5000 satisfies M^2 = 2 N^2.
pyth_solution(N, M) :-
    between(1, 5000, N),
    M0 is round(sqrt(2) * N),
    Lo is M0 - 1,
    Hi is M0 + 1,
    between(Lo, Hi, M),
    M > 0,
    M * M =:= 2 * N * N.

% Archimedean witness: floor(x) + 1 strictly exceeds x.
archimedean(X, N) :-
    F is floor(X),
    N is F + 1,
    N > X.

main :-
    format("==== 00 intro ====~n", []),

    % 1. Floats are not mathematical reals.
    S is 0.1 + 0.2,
    verify(S =\= 0.3),
    Eps is epsilon,
    format("float 0.1+0.2 = ~w, machine epsilon = ~w~n", [S, Eps]),

    % 2. Rational arithmetic is exact: 1/3 + 1/3 + 1/3 = 1.
    Third is 1 rdiv 3,
    R3 is Third + Third + Third,
    verify(R3 =:= 1),
    format("rational: 1 rdiv 3 summed three times = ~w~n", [R3]),

    % 3. Finite integer scan consistent with sqrt(2) irrationality.
    verify_not(pyth_solution(_, _)),
    format("integer scan up to 5000: no M^2 = 2 N^2~n", []),

    % A high-precision rational approximation is still not sqrt(2).
    Approx is 665857 rdiv 470832,
    verify(Approx * Approx =\= 2),
    Diff is Approx * Approx - 2,
    format("665857/470832 squared minus 2 = ~w~n", [Diff]),

    % 4. Archimedean property on sample inputs.
    verify(archimedean(1000000, _)),
    verify(archimedean(-3.7, Nneg)),
    archimedean(1000000, Nbig),
    format("archimedean(10^6) = ~w, archimedean(-3.7) = ~w~n",
           [Nbig, Nneg]),

    format("END ====~n", []).
