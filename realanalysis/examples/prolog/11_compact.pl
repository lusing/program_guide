:- encoding(utf8).
% Chapter 11 compact sets: Prolog channel.
% A finite subcover of [-3,3], and a point that escapes every finite piece of (0,1).
% Run: swipl -q -f 11_compact.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

in_subcover(X) :-
    (   -4 < X, X < 0
    ;   -1 < X, X < 3
    ;   2 < X, X < 6
    ).

escapes(N) :-
    X is 1 / (2 * N),
    Left is 1 / N,
    0 < X, X < 1,
    \+ Left < X.

in_all_open(X) :-
    forall(between(1, 40, N), (Right is 1/N, 0 < X, X < Right)).

main :-
    format("==== 11 compact ====~n", []),
    verify((findall(X, (between(-6, 6, K), X is K/2), Grid),
            maplist(in_subcover, Grid))),
    format("[-3,3] by halves sits in the three open intervals~n", []),

    verify(forall(between(1, 20, N), escapes(N))),
    format("1/(2N) is in (0,1) and left of (1/N, 1-1/N)~n", []),

    verify((findall(X, (between(0, 20, K), X is K/20), Sample),
            maplist([Z]>>(\+ in_all_open(Z)), Sample))),
    format("no sample point lies in every (0, 1/n)~n", []),

    verify(forall(between(1, 20, K),
                  (P is 1/(2*K), R is 1/K, 0 < P, P < R))),
    format("each finite intersection (0, 1/k) still holds 1/(2k)~n", []),

    format("END ====~n", []).
