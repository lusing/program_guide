- encoding(utf8).
% Chapter 16 Cauchy and monotone sequences: Prolog channel.
% Tail gap, spans of {1,2,3} and [-3,3], a decreasing reciprocal,
% and 1-1/(n+1) climbing toward 1.
% Run: swipl -q -f 16_cauchy.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

main :-
    format("==== 16 cauchy ====~n", []),
    verify((Gap is abs(1 rdiv 11 - 1 rdiv 12), Tenth is 1 rdiv 10, Gap < Tenth)),
    format("terms 11 and 12 of 1/n are less than 1/10 apart~n", []),

    verify((Span is abs(3 - 1), Span =:= 2)),
    format("the farthest points of {1,2,3} are 2 apart~n", []),

    verify((Ends is abs(3 - (-3)), Ends =:= 6)),
    format("the ends of [-3,3] are 6 apart~n", []),

    verify((Trunc is abs(141 rdiv 100 - 1414 rdiv 1000), Hundredth is 1 rdiv 100, Trunc < Hundredth)),
    format("two truncations of sqrt(2) differ by less than 1/100~n", []),

    verify((Small is 1 rdiv 12, Large is 1 rdiv 11, Small < Large)),
    format("1/n decreases: 1/12 is smaller than 1/11~n", []),

    verify((Left is 1 - 1 rdiv 11, Right is 1 - 1 rdiv 12, Left < Right,
             Short is abs(Left - 1), Short =:= 1 rdiv 11)),
    format("1-1/11 is below 1-1/12, and it is 1/11 short of 1~n", []),

    format("END ====~n", []).
