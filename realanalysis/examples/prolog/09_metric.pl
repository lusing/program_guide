:- encoding(utf8).
% Chapter 09 metric definitions: Prolog channel.
% Distance axioms, open ball, bounded interval, endpoint sequence.
% Run: swipl -q -f 09_metric.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

d(P, Q, D) :- D is abs(P - Q).

main :-
    format("==== 09 metric ====~n", []),
    Pts = [-3, -1, 0, 1, 3],
    verify((forall(member(P, Pts), (d(P, P, 0))))),
    verify((forall((member(P, Pts), member(Q, Pts)),
                   (d(P, Q, D1), d(Q, P, D2), D1 =:= D2)))),
    verify((forall((member(P, Pts), member(Q, Pts), member(R, Pts)),
                   (d(P, Q, PQ), d(P, R, PR), d(R, Q, RQ), PQ =< PR + RQ)))),
    format("distance axioms on a sample~n", []),

    verify((d(0, 2.9, Dball), Dball < 3)),
    verify((d(0, 3, 3), \+ 3 < 3)),
    format("ball(0,3) contains 2.9, excludes the endpoint 3~n", []),

    verify((forall(member(P, Pts), (d(P, 0, Dp), Dp =< 3)))),
    format("[-3,3] is bounded by 0 and M=3~n", []),

    verify((findall(X, (between(1, 20, N), X is 3 - 1/N), Seq),
            maplist([X]>>(X > -3, X < 3), Seq),
            last(Seq, Last), abs(Last - 3) < 0.1)),
    format("3-1/n in (-3,3) approaches the missing endpoint~n", []),

    format("END ====~n", []).
