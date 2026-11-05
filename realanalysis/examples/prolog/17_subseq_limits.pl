- encoding(utf8).
% Chapter 17 subsequential limits: Prolog channel.
% Squares pass 10, -5*n drops below -10, (-1)^n stays at plus or minus 1,
% and the even spike terms 4, 8, 12 climb.
% Run: swipl -q -f 17_subseq_limits.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

main :-
    format("==== 17 limsup ====~n", []),
    verify((Sq is 4 * 4, Sq > 10)),
    format("4^2 is already past 10~n", []),

    verify((Neg is -5 * 4, Bound is -10, Neg < Bound)),
    format("-5*4 is below -10~n", []),

    verify((Even is (-1) * (-1), Odd is (-1) * (-1) * (-1),
            Even =:= 1, Odd =:= -1, abs(Even) < 10)),
    format("(-1)^n stays at 1 or -1, so it is not past 10~n", []),

    verify((S1 is ((-1) + 1) * 1, S2 is (1 + 1) * 2,
            S4 is (1 + 1) * 4, S6 is (1 + 1) * 6,
            S1 =:= 0, S2 =:= 4, S4 =:= 8, S6 =:= 12, S6 > 10)),
    format("odd terms of the spike are 0; even terms 4, 8, 12 climb past 10~n", []),

    format("END ====~n", []).
