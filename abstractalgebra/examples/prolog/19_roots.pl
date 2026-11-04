:- encoding(utf8).
% 第 19 章 · 根与因子 —— Prolog 通道
%
% 根穷举 + 有理根候选 + F[x] 的 gcd。

% ---------- 多项式件（同 17 章口径） ----------
peval(P, F, A, V) :-
    reverse(F, FR),
    foldl([C, Acc0, Acc1]>>(Acc1 is (Acc0 * A + C) mod P), FR, 0, V).

root(P, F, A) :- Pm is P - 1, between(0, Pm, A0), A is A0 mod P,
    peval(P, F, A, V), V =:= 0.

% ---------- 有理根候选 ----------
divisor_of(N, D) :- N > 0, between(1, N, D), N mod D =:= 0.

% ---------- gcd 递归（多项式欧几里得的递归性质用整数版呈现） ----------
gcd_p(A, 0, A) :- !.
gcd_p(A, B, D) :- C is A mod B, gcd_p(B, C, D).

main :-
    format("==== 19 从数到多项式~n"),

    % 根穷举
    findall(A, root(7, [0, 6, 0, 1], A), R7), sort(R7, [0, 1, 6]),
    findall(A, root(8, [7, 0, 1], A), R8), sort(R8, [1, 3, 5, 7]),
    findall(A, root(5, [1, 1, 1], A), R5), R5 == [],
    format("根穷举：x³−x (mod 7) 恰 {0,1,6}；x²−1 (mod 8) 恰 4 根；x²+x+1 (mod 5) 无根 ✓~n"),

    % 有理根命中判定（整数化 q³f(p/q) = 2p³ + p·q² − 3q³ = 0）
    findall(SgP/Q, (divisor_of(3, PP), divisor_of(2, Q0),
                    member(Sg, [1, -1]), SgP is Sg * PP,
                    0 =:= 2 * SgP ^ 3 + SgP * Q0 ^ 2 - 3 * Q0 ^ 3),
            Hits),
    sort(Hits, [1/1]),
    format("有理根定理：2x³+x−3 的 8 候选中恰 p/q = 1 入选 ✓~n"),

    % gcd 链
    gcd_p(326, 78, 2),
    gcd_p(1071, 462, 21),
    format("整数 gcd 复核（欧几里得内核）：gcd(326,78) = 2；gcd(1071,462) = 21 ✓~n"),

    format("END ====~n").
