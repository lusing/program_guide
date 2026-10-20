:- encoding(utf8).
% 48_prob_inequalities.pl —— 第 48 章：概率不等式（Prolog 通道）
%
% 精确有理数账：① Chebyshev 取等（两点 ±1）；② Markov 的严格富余；
% ③ Kolmogorov 极大不等式的两步对称游走动等（穷举 4 条路径）；
% ④ 二项均值的 Chebyshev 账（组合数精确求和）。

% 精确二项系数（整数递归；k > n 兜底为 0，否则尾项 binom(N-1, N) 失败）
binom(_, 0, 1) :- !.
binom(N, K, 0) :- K > N, !.
binom(N, K, R) :- K > 0, K =< N,
    N1 is N - 1, K1 is K - 1,
    binom(N1, K1, A), binom(N1, K, B), R is A + B.

% ① Chebyshev 取等：X = ±1 各 1/2 —— Var = 1，P(|X| >= 1) = 1 = Var/1^2
check_cheb_eq :-
    EX is (1/2) * 1 + (1/2) * (-1),
    EX2 is (1/2) * 1 + (1/2) * 1,
    Var is EX2 - EX * EX,
    P is 1,                       % 两点都满足 |X| >= 1
    Bound is Var / (1 * 1),
    P =:= Bound,
    format("Chebyshev equality: two-point +/-1 has P = Var/lambda^2 = 1: OK~n").

% ② Markov 严格富余：X in {0, 2, 4} 概率 {1/2, 1/4, 1/4}
%     EX = 3/2，P(X >= 2) = 1/2 < EX/2 = 3/4
check_markov :-
    EX is 0 * (1/2) + 2 * (1/4) + 4 * (1/4),
    P is (1/4) + (1/4),
    Bound is EX / 2,
    P < Bound,
    format("Markov strict slack: P(X>=2)=1/2 < E[X]/2=3/4: OK~n").

% ③ Kolmogorov 极大账：两步 ±1 游动，4 条路径的 max|S_k| = [2,1,1,2]
%     P(max >= 2) = 2/4 = 1/2；界 sum sigma^2 / lambda^2 = 2/4 = 1/2 —— 取等！
check_kolm_max :-
    Maxima = [2, 1, 1, 2],
    findall(M, (member(M, Maxima), M >= 2), Hit),
    length(Maxima, Tot), length(Hit, H),
    P is H / Tot,
    Bound is (1 + 1) / (2 * 2),   % 两步方差各 1，lambda = 2
    P =:= Bound,
    format("Kolmogorov max equality: 2-step walk P(max>=2)=1/2 = sum-var/4: OK~n").

% ④ 二项均值 Chebyshev：n = 4，p = 1/2，eps = 1/2
%     尾事件 |k/4 - 1/2| >= 1/2 即 k = 0 或 4：精确 P = 2/16 = 1/8
%     界 1/(4 n eps^2) = 1/4 —— 富余一倍。
check_binom_mean :-
    binom(4, 0, C0), binom(4, 4, C4),
    P is (C0 + C4) / 16,
    Bound is 1 / (4 * 4 * (1/4)),
    P < Bound,
    P =:= 1/8, Bound =:= 1/4,
    format("Binomial mean Chebyshev: exact 1/8 < bound 1/4 (n=4, eps=1/2): OK~n").

main :-
    format("==== 48 prob_inequalities~n", []),
    check_cheb_eq,
    check_markov,
    check_kolm_max,
    check_binom_mean,
    format("END ====~n"), !.

:- initialization(main).
