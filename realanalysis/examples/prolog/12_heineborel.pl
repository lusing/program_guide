:- encoding(utf8).
% Chapter 12 Heine-Borel: Prolog channel.
% A point common to the nested intervals, a bisection short enough,
% a bounded sample inside a cell, and 1/n approaching 0.
% Run: swipl -q -f 12_heineborel.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

in_nested(X, N) :-
    Right is 1 + 1 / (N + 1),
    0 =< X, X =< Right.

in_cell(X) :-
    -3 =< X, X =< 3.

main :-
    format("==== 12 heine borel ====~n", []),
    verify(forall(between(0, 19, N), (in_nested(0, N), in_nested(1, N)))),
    format("0 and 1 lie in every [0, 1+1/(n+1)]~n", []),

    verify((Len is 4 / 64, Len < 0.1)),
    format("after 6 bisections, length 4/64 < 1/10~n", []),

    verify((findall(X, (member(K, [-3, -1, 0, 2, 3]), X is K), Sample),
            maplist(in_cell, Sample),
            \+ in_cell(4))),
    format("bounded sample sits in [-3,3]; 4 does not~n", []),

    verify((Twentieth is 1 / 20, 0 < Twentieth, Twentieth < 1, Twentieth < 0.1)),
    format("1/20 stays in (0,1] and is < 1/10~n", []),

    format("END ====~n", []).
