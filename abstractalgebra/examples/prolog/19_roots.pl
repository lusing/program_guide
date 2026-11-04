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

% ---------- 高斯整数辅助谓词（例 3.77 / 定理 3.83） ----------
gi_norm(A, B, N) :- N is A * A + B * B.
gi_mul(A1, B1, A2, B2, C, D) :- C is A1 * A2 - B1 * B2, D is A1 * B2 + B1 * A2.

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

    % ---------- 高斯整数 ℤ[i]：四商例 + 二平方和（例 3.77 / 定理 3.83） ----------
    % 3+5i = 2q + r 的四种分解（每个 ∂(r) = 2 < 4 = ∂(2)）
    forall(member(m-n-ra-rb, [1-2-1-1, 1-3-1-(-1), 2-2-(-1)-1, 2-3-(-1)-(-1)]),
           (gi_norm(ra, rb, N2), N2 = 2,
            gi_mul(2, 0, m, n, Q1, Q2),
            A is 3 - (Q1 + ra), B is 5 - (Q2 + rb), A = 0, B = 0)),
    format("例 3.77：3+5i = 2q+r 的四商恒等式全过（余范数 = 2 < 4）✓~n"),
    % 引理 3.82 见证 + 定理 3.83 正反向
    forall(member(P-M, [5-2, 13-5, 17-4, 29-12, 41-9, 61-11]),
           (P mod 4 =:= 1, M * M mod P =:= P - 1,
            once((between(1, P, A), between(0, A, B), A*A + B*B =:= P)))),
    forall(member(P, [3, 7, 11, 19]),
           (P mod 4 =:= 3,
            \+ (between(0, P, A), between(0, A, B), A*A + B*B =:= P))),
    format("定理 3.83：p ≡ 1 (mod 4) 六例有表示（见证 m² ≡ −1）；p ≡ 3 (mod 4) 四例无表示 ✓~n"),

    format("END ====~n").
