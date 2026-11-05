- encoding(utf8).
% Chapter 20 review: Prolog channel.
% 6 is past 5. |3+(-1)| does not exceed 3+1.
% Two halves add back to 1. 1/(1-1/2) = 2.
% Run: swipl -q -f 20_summary.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

main :-
    format("==== 20 review ====~n", []),
    verify((Six is 6, Five is 5, Six > Five)),
    format("6 is past 5~n", []),

    verify((Gap is abs(3 + -1), Room is abs(3) + abs(-1), Gap =< Room)),
    format("|3 + (-1)| does not exceed |3| + |-1|~n", []),

    verify((Half is rdiv(1, 2), Whole is Half + Half, Whole =:= 1)),
    format("two halves add back to 1~n", []),

    verify((Sum is rdiv(1, rdiv(1, 1) - rdiv(1, 2)), Sum =:= 2)),
    format("1 / (1 - 1/2) equals 2~n", []),

    format("END ====~n", []).
