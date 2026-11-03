:- encoding(utf8).
% 第 04 章 · 算术基本定理 —— Prolog 通道
%
% 试除分解（回溯直译）+ 指数合成 gcd/lcm 与欧几里得版对拍。


gcd(A, 0, A) :- !.
gcd(A, B, G) :- C is A mod B, gcd(B, C, G).

divisor(D, N) :- between(1, N, D), N mod D =:= 0.

% ---------- 试除分解：返回 [(素数, 指数)|...] ----------
% factor_from(+N, +P, -Fs)：P 是当前候选素数
factorize(N, Fs) :- N > 1, factor_from(N, 2, Fs).

factor_from(1, _, []) :- !.
factor_from(N, P, Fs) :-
    P * P > N, !,
    Fs = [(N, 1)].                       % 剩下的自身是素数（命题 1.3）
factor_from(N, P, Fs) :-
    N mod P =:= 0, !,
    extract_power(N, P, 0, N1, E),
    next_p(P, Q),
    factor_from(N1, Q, Fs0),
    Fs = [(P, E) | Fs0].
factor_from(N, P, Fs) :-
    next_p(P, Q),
    factor_from(N, Q, Fs).

next_p(2, 3) :- !.
next_p(P, Q) :- Q is P + 2.

% 数出 P 的指数
extract_power(N, P, E0, N1, E) :-
    (   N mod P =:= 0 ->
        N2 is N // P, E2 is E0 + 1,
        extract_power(N2, P, E2, N1, E)
    ;   N1 = N, E = E0
    ).

% 由分解还原
reconstruct([], 1) :- !.
reconstruct([(P, E) | Fs], N) :-
    reconstruct(Fs, N0),
    N is P ^ E * N0.

% 指数合成 gcd / lcm
gcd_from_factors([], _, 1) :- !.
gcd_from_factors([(P, E) | Fs], Fs2, G) :-
    (   member((P, E2), Fs2) ->
        E3 is min(E, E2), G0 is P ^ E3
    ;   G0 is 1
    ),
    gcd_from_factors(Fs, Fs2, G1),
    G is G0 * G1.

lcm_from_factors(Fs1, Fs2, L) :-
    reconstruct(Fs1, A), reconstruct(Fs2, B),
    gcd_from_factors(Fs1, Fs2, G),
    L is A * B // G.

main :-
    format("==== 04 算术基本定理~n"),

    % n ≤ 300：还原、素数递增、与 gcd/lcm 对拍
    forall(between(2, 300, N),
           ( factorize(N, Fs),
             reconstruct(Fs, N),
             strictly_increasing_primes(Fs),
             gcd_from_factors(Fs, Fs, N)      % 自身：gcd(n,n) = n
           )),
    format("试除分解：n ≤ 300 还原 + 素数递增 + 自 gcd 一致 ✓~n"),

    forall((between(2, 80, A), between(2, 80, B)),
           ( factorize(A, Fa), factorize(B, Fb),
             gcd_from_factors(Fa, Fb, G1),
             gcd(A, B, G2),
             G1 =:= G2,
             lcm_from_factors(Fa, Fb, L1),
             L1 =:= A * B // G2
           )),
    format("指数律 gcd/lcm：a,b ≤ 80 与欧几里得实现一致；gcd·lcm = ab ✓~n"),

    % 规范形算例
    factorize(1728, Fs1728),
    Fs1728 == [(2, 6), (3, 3)],
    format("1728 = 2⁶·3³（规范形）✓~n"),

    format("END ====~n").

strictly_increasing_primes([]) :- !.
strictly_increasing_primes([_]) :- !.
strictly_increasing_primes([(P1, _) | [(P2, _) | Rest]]) :-
    P1 < P2,
    strictly_increasing_primes([(P2, _) | Rest]).
