- encoding(utf8).
% Chapter 18 special sequences: Prolog channel.
% 1/121 is below 1/10 and below 1/11.
% (1/2)^10 = 1/1024 is below 1/100.
% (3/2)^2 = 9/4 is above 1 + 2*(1/2).
% Run: swipl -q -f 18_special.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

main :-
    format("==== 18 squeeze ====~n", []),
    verify((Gap is rdiv(1, 121), Bound is rdiv(1, 10), Gap < Bound)),
    format("1/121 is below 1/10~n", []),

    verify((Slot is rdiv(1, 121), Harm is rdiv(1, 11),
            0 < Slot, Slot < Harm)),
    format("1/121 sits strictly between 0 and 1/11~n", []),

    verify((Half is rdiv(1, 1024), Hundredth is rdiv(1, 100),
            Half < Hundredth)),
    format("(1/2)^10 is 1/1024, below 1/100~n", []),

    verify((Left is 1 + 2 * rdiv(1, 2), Right is rdiv(9, 4), Left < Right)),
    format("(3/2)^2 is 9/4, above 1 + 2*(1/2)~n", []),

    format("END ====~n", []).
