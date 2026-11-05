:- encoding(utf8).
% 第 43 章 Prolog：Lindeberg 商与 u.a.n. 的精确判决（rdiv 全程）。
% ① 三族商：多项式（n=8 归零——民主）、几何（恒 3/4——独裁）、有界（n=5 归零）；
% ② u.a.n. 判决：两点分布下 P(|X_k| >= eps·c_n) 非 0 即 1，
%    序列 u.a.n. ⟺ 无越线者 ⟺ 商为 0；
% ③ Feller 份额与峰度亏损的精确分数。
:- initialization(main).

% over_sum(Sig2, Threshold, S)：方差 >= 阈值（判据已两边平方）的项之和
over_sum([], _, 0).
over_sum([X | Xs], T, S) :-
    (   X >= T
    ->  over_sum(Xs, T, S1), S is X + S1
    ;   over_sum(Xs, T, S)
    ).

% 两点分布 ±sigma 的 Lindeberg 商
quot(Sig2, Eps, Q) :-
    sum_list(Sig2, C2),
    T is Eps * Eps * C2,
    over_sum(Sig2, T, S),
    Q is S rdiv C2.

% u.a.n. 判决：无任何项越线（对两点分布精确等价于商 = 0）
uan(Sig2, Eps) :- quot(Sig2, Eps, 0).

% 最大方差份额（Feller 条件）
share(Sig2, S) :- max_list(Sig2, M), sum_list(Sig2, C2), S is M rdiv C2.

% 峰度亏损：kurt = 3 - 2·Σσ^4/c^4
kurt_deficit(Sig2, D) :-
    sum_list(Sig2, C2),
    maplist([X, Y] >> (Y is X * X), Sig2, Sq),
    sum_list(Sq, S4),
    D is (2 * S4) rdiv (C2 * C2).

poly(N, L) :- findall(K, between(1, N, K), L).

% 例 5.3.1 的方差序列：1, 1, 2, 4, ..., 2^(n-2)
geo(N, [1 | T]) :- N >= 1, N2 is N - 2, findall(2 ^ K, between(0, N2, K), T).

main :-
    format("==== 43 lindeberg~n"),
    % ---------- ① 三族商 ----------
    format("① Lindeberg 商（eps = 1/2，rdiv 精确）：~n"),
    poly(7, P7), quot(P7, 1 rdiv 2, Q7),
    format("   多项式 n=7 ：商 = ~w（阈值 7 恰被末项踩线）~n", [Q7]),
    Q7 =:= 1 rdiv 4,
    poly(8, P8), quot(P8, 1 rdiv 2, Q8),
    format("   多项式 n=8 ：商 = ~w（阈值 9 越过全体——民主归零证书）~n", [Q8]),
    Q8 =:= 0,
    geo(6, G6), quot(G6, 1 rdiv 2, QG6),
    format("   几何   n=6 ：商 = ~w（独裁不退位）~n", [QG6]),
    QG6 =:= 3 rdiv 4,
    geo(10, G10), quot(G10, 1 rdiv 2, QG10),
    format("   几何   n=10：商 = ~w（与 n=6 完全相同）~n", [QG10]),
    QG10 =:= 3 rdiv 4,
    quot([3, 3, 3, 3], 1 rdiv 2, QB4),
    format("   有界   n=4 ：商 = ~w（阈值 3 被踩线，全数越线）~n", [QB4]),
    QB4 =:= 1,
    quot([3, 3, 3, 3, 3], 1 rdiv 2, QB5),
    format("   有界   n=5 ：商 = ~w（注 5.3.2：有界自动满足）~n", [QB5]),
    QB5 =:= 0,
    % ---------- ② u.a.n. 判决 ----------
    format("② u.a.n. 判决（无越线者即通过）：~n"),
    uan(P8, 1 rdiv 2),
    format("   多项式 n=8 ：u.a.n. 通过（每项 P(|X_k| >= eps·c_n) = 0）~n"),
    \+ uan(G6, 1 rdiv 2),
    format("   几何   n=6 ：u.a.n. 失败（末项 P(|X| >= eps·c) = 1）~n"),
    % ---------- ③ 份额与峰度亏损 ----------
    share(P8, SP8), share(G6, SG6),
    format("③ Feller 份额：多项式 n=8 = ~w，几何 n=6 = ~w（恒 1/2）~n", [SP8, SG6]),
    SP8 =:= 2 rdiv 9,
    SG6 =:= 1 rdiv 2,
    kurt_deficit(G6, DG6), kurt_deficit(P8, DP8),
    format("   峰度亏损 2·Σσ^4/c^4：几何 n=6 = ~w（极限 2/3），多项式 n=8 = ~w~n",
           [DG6, DP8]),
    DG6 =:= 171 rdiv 256,
    DP8 =:= 17 rdiv 54,
    format("END ====~n").
