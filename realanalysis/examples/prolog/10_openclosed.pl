:- encoding(utf8).
% Chapter 10 open and closed sets: Prolog channel.
% Nested intervals, a union that misses 2, a closure sequence, a relative endpoint.
% Run: swipl -q -f 10_openclosed.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

survives(X) :-
    forall(between(1, 40, N), (A is -1/N, B is 1/N, A < X, X < B)).

in_union(X) :-
    between(1, 40, N),
    Right is 2 - 1/N,
    X >= 0,
    X =< Right.

main :-
    format("==== 10 open closed ====~n", []),
    verify(survives(0)),
    verify(\+ survives(0.1)),
    format("nested open intervals keep only 0, and 0.1 drops out~n", []),

    verify(\+ in_union(2)),
    verify(in_union(0)),
    verify(in_union(1.5)),
    format("union of [0, 2-1/n] reaches 1.5 and stops short of 2~n", []),

    verify((findall(X, (between(1, 20, N), X is 3 - 1/N), Seq),
            maplist([Z]>>(Z > -3, Z < 3), Seq),
            last(Seq, Last),
            abs(Last - 3) < 0.1)),
    format("3-1/n in (-3,3) approaches the closure endpoint 3~n", []),

    verify((Y is 1.5, Y >= 0, Y < 2, Y >= 1)),
    verify(\+ (2 >= 0, 2 < 2)),
    verify((Half is 0.5, Half >= 0, Half < 2, \+ Half >= 1)),
    format("[1, 2) sits in [0, 2); the point 2 is outside the subspace~n", []),

    format("END ====~n", []).
