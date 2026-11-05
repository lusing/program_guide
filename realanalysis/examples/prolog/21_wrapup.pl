- encoding(utf8).
% Chapter 21 wrap-up: Prolog channel.
% Three thirds make 1. 6 is past 5.
% Two halves make 1. 1/(1-1/2) = 2.
% Run: swipl -q -f 21_wrapup.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

main :-
    format("==== 21 roadmap ====~n", []),
    verify((T1 is rdiv(1, 3), T2 is rdiv(1, 3), T3 is rdiv(1, 3),
            Sum3 is T1 + T2 + T3, Sum3 =:= 1)),
    format("three thirds make 1~n", []),

    verify((Six is 6, Five is 5, Six > Five)),
    format("6 is past 5~n", []),

    verify((Half is rdiv(1, 2), Whole is Half + Half, Whole =:= 1)),
    format("two halves make 1~n", []),

    verify((Geo is rdiv(1, rdiv(1, 1) - rdiv(1, 2)), Geo =:= 2)),
    format("geometric closed form is 2~n", []),

    format("END ====~n", []).
