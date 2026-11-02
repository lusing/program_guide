:- encoding(utf8).
% 21_multivariate_normal.pl —— 第 21 章：多元正态的有理数代数账（SWI-Prolog）
%
% ① 二元协方差矩阵：det = s1^2 s2^2 (1-rho^2)，Schur 补 = 条件方差，回归系数 = rho s2/s1
% ② 3 维 Sigma=[[4,2,1],[2,3,1/2],[1,1/2,2]]：给定 X3 后 (X1,X2) 的条件协方差（Schur 补）
% ③ 条件方差不超过无条件方差；回归系数 B C^-1
% ④ 符号翻转反例的有限版：X∈{-1,0,1}，Y=S*X，Cov=0 但 P(0,0)≠P(X=0)P(Y=0)

:- use_module(library(lists)).

% ① 取 s1=2, s2=3, rho=1/2：Sigma=[[4,3],[3,9]]
check_bivariate :-
    S1 is 2, S2 is 3, Rho is 1 rdiv 2,
    C12 is Rho * S1 * S2,
    Det is S1 * S1 * S2 * S2 - C12 * C12,
    Det =:= S1 * S1 * S2 * S2 * (1 - Rho * Rho), Det =:= 27,
    Schur is S2 * S2 - C12 * C12 / (S1 * S1),
    Schur =:= S2 * S2 * (1 - Rho * Rho), Schur =:= 27 rdiv 4,
    Beta is C12 / (S1 * S1),
    Beta =:= Rho * S2 / S1, Beta =:= 3 rdiv 4,
    % 全方差：beta^2 s1^2 + 条件方差 = s2^2
    Beta * Beta * S1 * S1 + Schur =:= S2 * S2,
    format("bivariate det, Schur complement, regression slope: OK~n").

% ② 3 维 Schur 补
sigma(1, 1, 4).         sigma(1, 2, 2).         sigma(1, 3, 1).
sigma(2, 1, 2).         sigma(2, 2, 3).         sigma(2, 3, 1 rdiv 2).
sigma(3, 1, 1).         sigma(3, 2, 1 rdiv 2).  sigma(3, 3, 2).

schur(I, J, V) :-
    sigma(I, J, Aij), sigma(I, 3, Bi), sigma(J, 3, Bj), sigma(3, 3, C),
    V is Aij - Bi * Bj / C.

check_schur :-
    schur(1, 1, V11), schur(1, 2, V12), schur(2, 2, V22),
    V11 =:= 7 rdiv 2, V12 =:= 7 rdiv 4, V22 =:= 23 rdiv 8,
    % 条件方差 ≤ 无条件方差
    sigma(1, 1, A11), sigma(2, 2, A22),
    V11 =< A11, V22 =< A22,
    % 回归系数 B/C = (1/2, 1/4)
    sigma(1, 3, B1), sigma(2, 3, B2), sigma(3, 3, C),
    K1 is B1 / C, K2 is B2 / C,
    K1 =:= 1 rdiv 2, K2 =:= 1 rdiv 4,
    format("3-d Schur complement [[7/2,7/4],[7/4,23/8]]: OK~n").

% ④ 符号翻转：X 在 {-1,0,1} 等概率，S 在 {-1,1} 等概率独立，Y = S*X
check_sign_flip :-
    findall(X-Y-P, ( member(X, [-1, 0, 1]), member(S, [-1, 1]),
                     Y is S * X, P is 1 rdiv 6 ), Tab),
    aggregate_all(sum(V), (member(X-Y-P, Tab), V is X * Y * P), EXY),
    EXY =:= 0,                                            % Cov = 0（E X = E Y = 0）
    aggregate_all(sum(P), member(0-0-P, Tab), P00),
    aggregate_all(sum(P), member(0-_-P, Tab), PX0),
    aggregate_all(sum(P), member(_-0-P, Tab), PY0),
    P00 =:= 1 rdiv 3, PX0 * PY0 =:= 1 rdiv 9, P00 =\= PX0 * PY0,   % 不独立
    aggregate_all(sum(V), (member(X-Y-P, Tab), V is X*X*Y*Y*P), E22),
    E22 =:= 2 rdiv 3,                                     % E[X²Y²] = E[X⁴] = 2/3 ≠ 4/9
    E22 =\= (2 rdiv 3) * (2 rdiv 3),
    format("sign-flip: uncorrelated but dependent: OK~n").

main :-
    format("==== 21 multivariate_normal~n"),
    check_bivariate,
    check_schur,
    check_sign_flip,
    format("END ====~n"), !.

:- initialization(main).
