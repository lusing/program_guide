:- encoding(utf8).
% Chapter 13 perfect and connected sets: Prolog channel.
% Points kept or removed in the first two Cantor stages, and a gap at 0.
% Run: swipl -q -f 13_perfect.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

in_e1(X) :-
    (   0 =< X, X =< 1/3
    ;   2/3 =< X, X =< 1
    ).

in_e2(X) :-
    (   0 =< X, X =< 1/9
    ;   2/9 =< X, X =< 3/9
    ;   6/9 =< X, X =< 7/9
    ;   8/9 =< X, X =< 1
    ).

in_gap(X) :-
    (   -3 =< X, X < 0
    ;   0 < X, X =< 3
    ).

main :-
    format("==== 13 perfect ====~n", []),
    verify((in_e1(0), in_e1(1/4), in_e1(1), \+ in_e1(1/2))),
    format("0, 1/4, 1 stay in E1; 1/2 is removed~n", []),

    verify((in_e2(1/4), \+ in_e2(1/2))),
    format("1/4 still in E2; 1/2 is not~n", []),

    verify((Half is 1/2, Ninth is 1/9, Ninth < Half, Pieces is 2*2, Pieces =:= 4)),
    format("E2 has 4 pieces of length 1/9, shorter than 1/2~n", []),

    verify((in_gap(-1), in_gap(1), \+ in_gap(0))),
    format("-1 and 1 are in the gapped union; 0 is not~n", []),

    format("END ====~n", []).
