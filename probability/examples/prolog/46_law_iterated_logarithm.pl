:- encoding(utf8).
% 第 46 章 Prolog：重对数律可代数化部分的精确账（rdiv 全程）。
% ① 分级二项尾：P(S_{2^j} >= t) 的精确分数（comb 递推 + rdiv）；
% ② 指数压倒多项式的整数证书：2^n >= n^3 / n^5 的最小 n 搜索；
% ③ 分级求和的收敛账：Σ_j 1/j^2 的部分和（上界翼 (j·log2)^(-K) 的原型）；
% ④ 双侧翻倍：分级点尾概率 ×2（上界翼 (6.3.18) 的精确面）。
:- initialization(main).

comb(_N, 0, 1) :- !.
comb(N, K, 0) :- K > N, !.
comb(N, K, C) :- K1 is K - 1, N1 is N - 1,
                 comb(N1, K1, C1), C is C1 * N // K.

% P(S_n >= t) 的分子：S = 2B - n，故 B >= (n+t)/2；求 Σ C(n,i)
tail_num(N, T, S) :-
    Idx is (N + T + 1) // 2,
    Idx =< N,
    findall(C, (between(Idx, N, I), comb(N, I, C)), Cs),
    sum_list(Cs, S).

% 证书搜索：最小的 N 使 2^N >= N^k 且 2^(N-1) < (N-1)^k（从 N-1 起以后恒成立）
first_n(K, N) :-
    between(2, 200, N),
    2 ^ N >= N ^ K,
    N1 is N - 1,
    2 ^ N1 < N1 ^ K, !.

% Σ_{j=1}^{m} 1/j^2 的精确部分和
sum_inv_sq(M, S) :-
    findall(Q, (between(1, M, J), Q is 1 rdiv (J * J)), Qs),
    sum_list(Qs, S).

main :-
    format("==== 46 lil~n"),
    % ---------- ① 分级二项尾 ----------
    format("① 分级二项尾 P(S_{{2^j}} >= t) 的精确分数：~n"),
    member(j(4, 8), [j(4, 8)]),
    tail_num(16, 8, S16), P16 is S16 rdiv 65536,
    format("   n=16, t=8 ：~w/65536 = ~w~n", [S16, P16]),
    tail_num(16, 10, S1610), P1610 is S1610 rdiv 65536,
    P1610 =:= 697 rdiv 65536,
    format("   n=16, t=10：~w/65536（S>=10 ⟺ Bin>=13，与 Lean 件同一账）~n", [S1610]),
    tail_num(32, 18, S32), P32 is S32 rdiv 4294967296,
    format("   n=32, t=18：~w/2^32 = ~w（约 ~4f）~n", [S32, P32, P32]),
    P1610 < P16,
    format("   阈值上移，尾骤降——分级点的方差控制~n"),
    % ---------- ② 整数证书 ----------
    format("② 指数压倒多项式（2^n >= n^k 的最小 n）：~n"),
    first_n(3, N3), first_n(5, N5),
    format("   k=3：n = ~w（Lean 已证对一切 n >= 10 成立）~n", [N3]),
    format("   k=5：n = ~w~n", [N5]),
    N3 =:= 10, N5 > N3,
    % ---------- ③ 分级求和收敛账 ----------
    format("③ 分级求和 Σ 1/j^2 的部分和（上界翼原型）：~n"),
    sum_inv_sq(10, S10), sum_inv_sq(100, S100), sum_inv_sq(1000, S1000),
    format("   m=10：~w ≈ ~4f~n", [S10, S10]),
    format("   m=100：~4f，m=1000：~4f（单调有界 -> 收敛）~n", [S100, S1000]),
    S1000 > S100, S100 > S10, S1000 < 2,
    % ---------- ④ 双侧翻倍 ----------
    format("④ 双侧账：2·P(S_16 >= 10) = ~w（(6.3.18) 的精确面）~n",
           [2 * P1610]),
    format("END ====~n").
