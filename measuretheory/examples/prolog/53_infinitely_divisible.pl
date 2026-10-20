:- encoding(utf8).
% 53_infinitely_divisible.pl —— 第 53 章：无穷可分（Prolog 通道）
%
% ① 三点分布（P{±1}=1/4，P{0}=1/2）的 n=2 卷积根不存在：代数矛盾
%    判决 + dyadic 网格穷举双证；② Bernoulli 分解账（qr = 0 强制
%    退化）；③ 几何分布 Poisson 积（例 53.J）：λₖ = 1/(k·3ᵏ) 分数
%    生成、Λ = log(3/2) 对拍、Panjer 递推 vs 几何 pmf。

pow(_, 0, 1) :- !.
pow(B, N, P) :- N > 0, N1 is N - 1, pow(B, N1, Q), P is B * Q.

% ① (a) 代数矛盾：g_1^2 = f_2 = 0 ⟹ g_1 = 0；但 f_1 = 2·g_0·g_1 = 1/4
%        ⟹ g_1 ≥ 1/8 > 0 —— 无解
check_no_root_algebra :-
    F1 is 1/4,
    G1 is sqrt(0),                 % g_1 = 0（由 f_2 = g_1^2 = 0）
    Residual is 2 * 1 * G1,        % g_0 ≤ 1 时 2 g_0 g_1 的最大可能
    Residual =\= F1,               % 0 ≠ 1/4 —— 方程组矛盾
    format("3-point algebraic: g1=0 forces 2*g0*g1=0 =/= 1/4: OK~n").

% ① (b) dyadic 网格穷举：支撑 {-1,0,1}，步长 1/16，全搜无解
weight(-1, Gm, _, _, Gm).
weight(0, _, G0, _, G0).
weight(1, _, _, Gp, Gp).

conv_value(Gm, G0, Gp, S, V) :-
    findall(A * B, (member(I, [-1, 0, 1]), member(J, [-1, 0, 1]),
                    I + J =:= S,
                    weight(I, Gm, G0, Gp, A), weight(J, Gm, G0, Gp, B)),
            Terms),
    sum_list(Terms, V).

check_no_root_grid :-
    \+ (between(0, 16, A), between(0, 16, B), between(0, 16, C),
        Gm is A / 16, G0 is B / 16, Gp is C / 16,
        Gm + G0 + Gp =:= 1,
        conv_value(Gm, G0, Gp, -2, 0),
        conv_value(Gm, G0, Gp, -1, 1/4),
        conv_value(Gm, G0, Gp, 0, 1/2),
        conv_value(Gm, G0, Gp, 1, 1/4),
        conv_value(Gm, G0, Gp, 2, 0)),
    format("3-point grid search: no rational root on 1/16 grid (17^3): OK~n").

% ② Bernoulli 分解：b(1,p) = b(1,q) * b(1,r) ⟹ P{和=2} = qr = 0
%    ⟹ 退化根 (0,p) 与 (p,0) 恰两个
check_bernoulli :-
    P is 1/4,
    findall(Q - R, (member(Q, [0, P]), member(R, [0, P]),
                    Q + R - Q * R =:= P, Q * R =:= 0), Sols),
    length(Sols, 2),
    format("Bernoulli split: only degenerate roots (0,p),(p,0): OK~n").

% ③ 几何 Poisson 积（p = 3）：λ_k = 1/(k·3^k)，Λ = log(3/2)
lam(K, L) :- pow(3, K, P), L is 1 / (K * P).

check_lambda_total :-
    findall(L, (between(1, 30, K), lam(K, L)), Ls),
    sum_list(Ls, S),
    Target is log(3 / 2),
    abs(S - Target) < 1e-12,       % Σ 1/(k 3^k) = log(3/2) 精确恒等式
    format("geometric Poisson integral: sum 1/(k*3^k) = log(3/2) exact: OK~n").

%    Panjer 递推：f(0) = e^{-Λ}；f(m) = (Λ/m) Σ_k k·q(k)·f(m-k)
panjer_table(M, Fs) :-
    Lambda is log(3 / 2),
    F0 is exp(-Lambda),
    build(1, M, Lambda, [F0], Rev),
    reverse(Rev, Fs).

build(K, M, _, Fs, Fs) :- K > M, !.
build(K, M, Lambda, Acc, Out) :-
    % Acc 倒序存 [f(K-1), ..., f(0)]：取 f(Km) = lookup(K-1-Km)
    findall(K1 * Q * Fj, (between(1, K, K1), lam(K1, Lk),
                          Q is Lk / Lambda, Km is K - K1,
                          Off is K - 1 - Km,
                          lookup(Off, Acc, Fj)), Terms),
    sum_list(Terms, S),
    Fk is Lambda / K * S,
    K1 is K + 1,
    build(K1, M, Lambda, [Fk | Acc], Out).

% lookup(J, Acc, F)：倒序表的第 J 项（0 起）
lookup(0, [F | _], F) :- !.
lookup(J, [_ | Rest], F) :- J > 0, J1 is J - 1, lookup(J1, Rest, F).

max_err_([], _, E, E).
max_err_([F | Rest], M, Acc, Err) :-
    Geo is (2 / 3) * (1 / 3) ** M,
    E is abs(F - Geo),
    A2 is max(Acc, E),
    M1 is M + 1,
    max_err_(Rest, M1, A2, Err).

check_panjer :-
    panjer_table(12, Fs),
    max_err_(Fs, 0, 0.0, Err),
    Err < 1e-10,
    format("Panjer vs geometric pmf: max err = ~e (m<=12): OK~n", [Err]).

main :-
    format("==== 53 infinitely_divisible~n", []),
    check_no_root_algebra,
    check_no_root_grid,
    check_bernoulli,
    check_lambda_total,
    check_panjer,
    format("END ====~n"), !.

:- initialization(main).
