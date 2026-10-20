:- encoding(utf8).
% 50_lln.pl —— 第 50 章：弱大数律（Prolog 通道，精确有理数账）
%
% ① Chebyshev 界 vs 二项精确尾概率（n=20，eps=1/5，全分数）；
% ② 界的 1/n 衰减：n = 10/20/40 逐级对半（精确有理恒等）；
% ③ 圣彼得堡截尾期望 = (k+1)/2 的逐点分数账；
% ④ 精确尾概率随 n 单调收缩（n=10 vs n=20，同一 eps 带）。

binom(_, 0, 1) :- !.
binom(N, K, 0) :- K > N, !.
binom(N, K, R) :- K > 0, K =< N,
    N1 is N - 1, K1 is K - 1,
    binom(N1, K1, A), binom(N1, K, B), R is A + B.

pow2(0, 1) :- !.
pow2(N, P) :- N > 0, N1 is N - 1, pow2(N1, Q), P is 2 * Q.

% |k/n - 1/2| >= 1/5 的精确尾概率（分数求和，无浮点）
tail_prob(N, PowN, S) :-
    findall(R, (between(0, N, K), abs(K / N - 1/2) >= 1/5,
                binom(N, K, C), R is C / PowN), L),
    sum_list(L, S).

% ① n = 20：界 1/(4 n eps^2) = 25/80 = 5/16，精确值在其下
check_cheb :-
    pow2(20, Pow),
    tail_prob(20, Pow, Exact),
    Bound is 1 / (4 * 20 * (1/25)),
    Bound =:= 5/16,
    Exact =< Bound,
    format("Chebyshev vs exact binomial tail (n=20): exact =< 5/16: OK~n").

% ② 1/n 衰减：界逐级对半（精确有理恒等，非浮点近似）
check_decay :-
    B10 is 1 / (4 * 10 * (1/25)),
    B20 is 1 / (4 * 20 * (1/25)),
    B40 is 1 / (4 * 40 * (1/25)),
    B10 =:= 2 * B20,
    B20 =:= 2 * B40,
    format("bound decays as 1/n: B(10)=5/8, B(20)=5/16, B(40)=5/32 exact: OK~n").

% ③ 圣彼得堡截到 2^k：E = sum_{j=0}^{k} 2^j * 2^{-(j+1)} = (k+1)/2
stpet(K, E) :-
    findall(T, (between(0, K, J), pow2(J, P), J1 is J + 1,
                pow2(J1, Q), T is P * (1 / Q)), L),
    sum_list(L, E).

check_stpet :-
    stpet(3, E3), stpet(8, E8),
    E3 =:= 2,       % (3+1)/2
    E8 =:= 9/2,     % (8+1)/2 —— 每档贡献恰 1/2
    format("St. Petersburg capped E[X;X<=2^k] = (k+1)/2 exact (k=3,8): OK~n").

% ④ 同带尾概率单调收缩：n=10 与 n=20（eps=1/5）
check_shrink :-
    pow2(10, PowA), tail_prob(10, PowA, PA),
    pow2(20, PowB), tail_prob(20, PowB, PB),
    PB < PA,
    format("exact tail shrinks: P(n=20) < P(n=10) in the eps=1/5 band: OK~n").

main :-
    format("==== 50 lln~n", []),
    check_cheb,
    check_decay,
    check_stpet,
    check_shrink,
    format("END ====~n"), !.

:- initialization(main).
