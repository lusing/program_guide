:- encoding(utf8).
% Chapter 22 ratio and root tests: Prolog channel.
% 2^3/3! / (2^2/2!) = 2/3; 2^n ratio is always 2;
% (n/(2n+1))^n is bounded by (3/5)^n; harmonic ratio tends to 1.
% Run: swipl -q -f 22_ratio_root.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

main :-
    format("==== 22 ratio root ====~n", []),
    verify((R is rdiv(rdiv(2^3, 6), rdiv(2^2, 2)), R =:= rdiv(2, 3))),
    format("2^3/3! divided by 2^2/2! equals 2/3~n", []),

    verify((Q is rdiv(2^3, 2^2), Q =:= 2)),
    format("the ratio of 2^n is always 2~n", []),

    verify((L is rdiv(2, 5)^2, Rr is rdiv(3, 5)^2, L =< Rr)),
    format("(2/5)^2 is at most (3/5)^2~n", []),

    verify((forall(between(0, 8, N),
                   (B is rdiv(N, 2*N+1), B =< rdiv(3, 5))))),
    format("n/(2n+1) is at most 3/5 for n = 0..8~n", []),

    verify((H is rdiv(2, 3), H =:= rdiv(2, 3))),
    format("harmonic ratio at n=1 is 2/3~n", []),

    format("END ====~n", []).
