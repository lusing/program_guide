:- encoding(utf8).
% 第 44 章 Prolog：无穷可分的精确判决（rdiv 全程）。
% ① 卷积引擎 + 整因子侧封闭：Bernoulli^2 = Bin(2)、Bernoulli^3 = Bin(3)、
%    NB(1,p)*NB(1,p) = NB(2,p)（k = 0..5 逐点）；
% ② Bernoulli(p) 不可 2-分：三点方程的消元矛盾（q1^2 = 0 强制 q1 = 0）；
% ③ 均匀三点 {0,1,2} 不可 2-分：平方判据 4/9 != 1/9（无理数的平方消不去）。
% 结论：可分比直觉窄——Bernoulli 只能沿因子的卷积展开，均匀完全不可切。
:- initialization(main).

% C(N,K)（乘法递推，整数精确）
comb(N, 0, 1) :- !.
comb(N, K, 0) :- K > N, !.
comb(N, K, C) :- K1 is K - 1, N1 is N - 1,
                 comb(N1, K1, C1), C is C1 * N // K.

% 卷积的一个表项：C[K] = sum_{i=0..K} A[i]*B[K-i]（rdiv 精确）
conv_entry(A, B, K, C) :-
    findall(T,
        (   between(0, K, I),
            nth0(I, A, AI), J is K - I,
            nth0(J, B, BI),
            T is AI * BI ),
        Ts),
    sum_list(Ts, C).

% 两个 pmf 的前 Len 项卷积表
conv_pmf(A, B, Len, Cs) :-
    findall(C,
        ( between(0, Len, K), conv_entry(A, B, K, C) ),
        Cs).

% 二项 pmf 前 N 项（N = 支撑上界）
bin_pmf(N, P, L) :-
    findall(V,
        (   between(0, N, K), comb(N, K, C),
            V is (C rdiv 1) * P ** K * (1 - P) ** (N - K) ),
        L).

% 负二项 NB(r,p) 前 Len 项（整数 r）
nb_pmf(R, P, Len, L) :-
    findall(V,
        (   between(0, Len, K), KK is K + R - 1, comb(KK, K, C),
            V is (C rdiv 1) * P ** R * (1 - P) ** K ),
        L).

% Bernoulli(p) 的 2-根不存在：q1^2 = 0 唯一非负解 q1 = 0，
% 代回 2q0q1 = 0 与 P(X=1) = P > 0 矛盾
bern_no_root(P) :-
    P > 0,
    Q1 is 0, Q0 is 1 - Q1,
    2 * Q0 * Q1 =:= 0,
    0 =\= P.

% 均匀三点 {0,1,2} 的 2-根不存在：q2 = 0（由 q2^2 = P(X=2) = 0）后
% q0^2 = q1^2 = 1/3 与 2q0q1 = 1/3 平方相矛盾
uni_no_root :-
    L is 4 * (1 rdiv 3) * (1 rdiv 3),
    R is (1 rdiv 3) ^ 2,
    L =:= 4 rdiv 9,
    R =:= 1 rdiv 9,
    L =\= R.

main :-
    format("==== 44 infinitely_divisible~n"),
    % ---------- ① 整因子侧的卷积封闭 ----------
    format("① 卷积引擎（rdiv 精确）：~n"),
    Ber = [1 rdiv 2, 1 rdiv 2],
    conv_pmf(Ber, Ber, 2, Cs2),
    bin_pmf(2, 1 rdiv 2, B2),
    format("   Bernoulli^2 = ~w~n", [Cs2]),
    format("   Bin(2,1/2)  = ~w~n", [B2]),
    Cs2 = B2,                              % 逐项合一即判决
    conv_pmf(Cs2, Ber, 3, Cs3),
    bin_pmf(3, 1 rdiv 2, B3),
    format("   Bernoulli^3 = Bin(3,1/2)：~w~n", [Cs3]),
    Cs3 = B3,
    P = 1 rdiv 3,
    nb_pmf(1, P, 5, NB1),
    nb_pmf(2, P, 5, NB2),
    conv_pmf(NB1, NB1, 5, NB12),
    format("   NB(1,1/3)*NB(1,1/3) 的 k=0..4 项：~w~n", [NB12]),
    format("   NB(2,1/3)           的 k=0..4 项：~w~n", [NB2]),
    NB12 = NB2,
    % ---------- ② Bernoulli 不可 2-分 ----------
    format("② Bernoulli(1/2) 的 2-根判决：q1^2=0 => q1=0 => 2q0q1=0 != 1/2~n"),
    bern_no_root(1 rdiv 2),
    format("   无解——两点原子挡住切分（Bin 族只在因子处可分）~n"),
    % ---------- ③ 均匀三点不可 2-分 ----------
    format("③ 均匀三点的 2-根判决：~n"),
    uni_no_root,
    format("   (2q0q1)^2 = 4/9 != 1/9 = (1/3)^2——连无理解都不存在~n"),
    format("END ====~n").
