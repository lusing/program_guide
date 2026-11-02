:- encoding(utf8).
% 08_random_variables.pl —— 第 08 章：随机变量与 CDF（Prolog 穷举）
%
% ① 三硬币 8 路径枚举 → pmf 表（1/8,3/8,3/8,1/8）与矩账；
% ② 两骰 36 有序对 → 三角形 pmf 与均值 7、方差 35/6；
% ③ n=4 伯努利过程：16 位串全枚举 → 二项 pmf 与 CDF
%    阶梯（P(X ≤ 2) = 11/16）。

bits(0, []).
bits(N, [B|Bs]) :- N > 0, N1 is N - 1, between(0, 1, B), bits(N1, Bs).

bit_count(Bs, K) :- include(=(1), Bs, Ones), length(Ones, K).

count_occ(_, [], 0).
count_occ(X, [Y|Ys], N) :- count_occ(X, Ys, N0),
                           (X == Y -> N is N0 + 1 ; N = N0).

% ① 三硬币：8 路径按正面数折层 = pmf 表
check_three_coin :-
    findall(K, (bits(3, Bs), bit_count(Bs, K)), Ks),
    length(Ks, 8),
    count_occ(0, Ks, 1), count_occ(1, Ks, 3),
    count_occ(2, Ks, 3), count_occ(3, Ks, 1),
    % 矩账：E[X] = 12/8 = 3/2、E[X2] = 24/8 = 3、Var = 3 - 9/4 = 3/4
    S1 is 0*1 + 1*3 + 2*3 + 3*1, S2 is 0*1 + 1*3 + 4*3 + 9*1,
    E1 is S1 rdiv 8, E2 is S2 rdiv 8,
    E1 =:= 3 rdiv 2, E2 =:= 3,
    Var is E2 - E1 * E1, Var =:= 3 rdiv 4,
    format("three-coin pmf [1,3,3,1]/8, E[X]=3/2, E[X2]=3, Var=3/4: OK~n").

% ② 两骰和：36 格 → 三角形、均值、方差
check_two_dice :-
    findall(R, (between(1, 6, A), between(1, 6, B), R is A + B), Rs),
    length(Rs, 36),
    forall(between(2, 12, R),
           (count_occ(R, Rs, N), N =:= 6 - abs(R - 7))),
    sum_list(Rs, S), S =:= 36 * 7,                  % 均值 7 的分子账
    dev_sum(Rs, D), D =:= 210,                      % Σ(r-7)² = 210
    Var is 210 rdiv 36, Var =:= 35 rdiv 6,
    format("two-dice triangle pmf, mean 7, Var 35/6: OK~n").

dev_sum([], 0).
dev_sum([R|Rs], S) :- dev_sum(Rs, S0),
                      D is (R - 7) * (R - 7), S is S0 + D.

% ③ n=4 伯努利过程：16 位串 → 二项 pmf 与 CDF
check_binom4 :-
    findall(K, (bits(4, Bs), bit_count(Bs, K)), Ks),
    length(Ks, 16),
    count_occ(0, Ks, 1), count_occ(1, Ks, 4),
    count_occ(2, Ks, 6), count_occ(3, Ks, 4), count_occ(4, Ks, 1),
    exclude(<(2), Ks, Le2), length(Le2, 11),        % 保留 X≤2：1+4+6 = 11
    P is 11 rdiv 16, P =:= 11 / 16,
    format("binomial(4): pmf [1,4,6,4,1]/16, CDF F(2)=11/16: OK~n").

main :-
    format("==== 08 random_variables~n", []),
    check_three_coin,
    check_two_dice,
    check_binom4,
    format("END ====~n"), !.

:- initialization(main).
