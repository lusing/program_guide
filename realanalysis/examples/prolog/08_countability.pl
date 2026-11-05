:- encoding(utf8).
% Chapter 08 countability: Prolog channel.
% Zigzag enumeration of integers, diagonal escape, reduced rationals.
% Run: swipl -q -f 08_countability.pl -g main -t halt

verify(G) :-
    (   call(G)
    ->  true
    ;   format("FAILED: ~w~n", [G]),
        fail
    ).

zig(N, Z) :-
    (   0 =:= N mod 2
    ->  Z is N // 2
    ;   Z is -((N + 1) // 2)
    ).

unzig(Z, N) :-
    (   Z >= 0
    ->  N is 2 * Z
    ;   N is -2 * Z - 1
    ).

diagonal([], []).
diagonal(Rows, [D|Ds]) :-
    nth0(0, Rows, Row0),
    nth0(0, Row0, Bit),
    (Bit =:= 0 -> D = 1 ; D = 0),
    maplist(tail, Rows, Tails0),
    exclude(=([ ]), Tails0, Tails),
    diagonal(Tails, Ds).
tail([_|Xs], Xs).

gcd_nat(A, B, G) :- G is gcd(A, B).

main :-
    format("==== 08 countability ====~n", []),

    verify((findall(Z, (between(0, 5, N), zig(N, Z)),
                    [0, -1, 1, -2, 2, -3]))),
    verify((forall(between(-20, 20, Z),
                   (unzig(Z, N), zig(N, Z))))),
    verify((forall(between(0, 40, N),
                   (zig(N, Z), unzig(Z, N))))),
    format("zigzag bijection on sample~n", []),

    Rows = [[0,1,0,1],[1,1,0,0],[0,0,0,1],[1,0,1,1]],
    verify((diagonal(Rows, S),
            nth0(0, S, S0), S0 =\= 0,
            nth0(1, S, S1), S1 =\= 1,
            nth0(2, S, S2), S2 =\= 0,
            nth0(3, S, S3), S3 =\= 1)),
    format("diagonal escape differs on the diagonal~n", []),

    verify((gcd_nat(2, 4, 2), gcd_nat(1, 2, 1), gcd_nat(3, 5, 1))),
    format("reduced fractions use gcd = 1~n", []),

    format("END ====~n", []).
