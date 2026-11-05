- encoding(utf8).
% Chapter 15 subsequences: Prolog channel.
% Sum, scale, product, reciprocal, and the even/odd index split.
% Run: swipl -q -f 15_subsequences.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

main :-
    format("==== 15 subsequences ====~n", []),
    verify((Sum is (1 rdiv 11 + 1) - 1, Sum =:= 1 rdiv 11)),
    format("adding 1 moves the term by exactly 1/11 from the limit 1~n", []),

    verify((Sc is abs(3 * (1 rdiv 11)), Bd is 3 rdiv 10, Sc < Bd)),
    format("three times 1/11 stays under 3/10~n", []),

    verify((P is (1 + 1 rdiv 10) * (2 + 1 rdiv 10), G is abs(P - 2), Half is 1 rdiv 2, G < Half)),
    format("product at n=10 is within 1/2 of 2~n", []),

    verify((Inv is 1 rdiv (1 + 1 rdiv 10), Dinv is abs(Inv - 1), Target is 1 rdiv 11, Dinv =:= Target)),
    format("reciprocal of 1+1/10 is 10/11, distance 1/11~n", []),

    verify((2 < 4, 4 < 6)),
    format("even indices 2, 4, 6 keep increasing~n", []),

    format("END ====~n", []).
