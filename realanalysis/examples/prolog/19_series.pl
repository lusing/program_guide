- encoding(utf8).
% Chapter 19 series: Prolog channel.
% 1 + 1/2 + 1/4 = 7/4 = (1 - 1/8)/(1/2).
% (2/3)/(1 - 2/3) = 2.
% The harmonic head is larger than 2; replacing 1/3 by 1/4 gives 2.
% The constant term 1 is not below 1/2.
% Run: swipl -q -f 19_series.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

main :-
    format("==== 19 series ====~n", []),
    verify((Partial is rdiv(1, 1) + rdiv(1, 2) + rdiv(1, 4),
            Closed is rdiv(rdiv(1, 1) - rdiv(1, 8), rdiv(1, 2)),
            Partial =:= rdiv(7, 4), Closed =:= Partial)),
    format("1 + 1/2 + 1/4 equals 7/4, and so does the closed form~n", []),

    verify((Rect is rdiv(rdiv(2, 3), rdiv(1, 1) - rdiv(2, 3)), Rect =:= 2)),
    format("(2/3) / (1 - 2/3) equals 2~n", []),

    verify((Group is rdiv(1, 1) + rdiv(1, 2) + rdiv(1, 4) + rdiv(1, 4),
            Harm is rdiv(1, 1) + rdiv(1, 2) + rdiv(1, 3) + rdiv(1, 4),
            Group =:= 2, Harm > Group)),
    format("replacing 1/3 by 1/4 gives 2; the harmonic head is larger~n", []),

    verify((One is rdiv(1, 1), Half is rdiv(1, 2), abs(One) > Half)),
    format("the constant term 1 is not below 1/2~n", []),

    format("END ====~n", []).
