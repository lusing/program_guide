- encoding(utf8).
% Chapter 14 sequences: Prolog channel.
% 1/11 is under 1/10, 20^2 escapes 100, alternating distance is 1/11.
% Run: swipl -q -f 14_sequences.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

main :-
    format("==== 14 sequences ====~n", []),
    verify((H is 1 rdiv 11, E is 1 rdiv 10, H < E)),
    format("1/11 < 1/10; N = 11 works for epsilon = 1/10~n", []),

    verify((Sq is 20 * 20, Sq > 100)),
    format("20^2 escapes the bound 100~n", []),

    verify((D is abs(1 + ((-1) rdiv 11) - 1), T is 1 rdiv 11, D =:= T)),
    format("alternating distance to 1 equals 1/11~n", []),

    verify((C is abs(1 - 1), C =:= 0)),
    format("constant sequence stays at distance 0~n", []),

    verify((Left is 1 + (1 rdiv 2), Right is -1 + ((-1) rdiv 3), Gap is abs(Left - Right), Gap > 2)),
    format("consecutive terms of the two-endpoint sequence stay more than 2 apart~n", []),

    format("END ====~n", []).
