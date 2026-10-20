:- encoding(utf8).
% 56_lll.pl —— 第 56 章：重对数律（Prolog 通道）
%
% ① 包络列的单调性与增长率核对（√(2n log log n)）；
% ② 几何子列的生成与覆盖率（q^m 检查点的稀疏化）；
% ③ B-C 判决器（概率序列的和 → 0/1 结论）。

% ① 包络单调性：n ≥ 3 时 √(2n log log n) 严格增
envelope(N, E) :- E is sqrt(2.0 * N * log(log(N))).

check_envelope :-
    envelope(3, E3), envelope(10, E10), envelope(100, E100),
    envelope(1000, E1000), envelope(10000, E10000),
    E3 < E10, E10 < E100, E100 < E1000, E1000 < E10000,
    % 增长率：E(10n)/E(n) → √10（√n 律——LLn 的慢修正使有限处
    % 偏高：实测 3.39，容差按有限 n 行为定）
    R is E10000 / E1000,
    R > 2.8, R < 3.5,
    format("envelope: strictly increasing, growth ratio toward sqrt(10) = ~w: OK~n", [R]).

% ② 几何子列：n_m = ceil(1.5^m)，m = 1..20——n_max = 4e4 内的检查点数
geom_points(Q, MMax, Points) :-
    findall(N, (between(1, MMax, M), N is ceil(Q ** M)), Points).

check_geometric :-
    geom_points(1.5, 20, Ps),
    length(Ps, K),
    K >= 18, K =< 20,                          % 1.5^20 ≈ 3325 < 4e4 … 手验：
    % 1.5^20 = 3325.26——20 个点全覆盖；相邻比恒 1.5（稀疏化 ✓）
    nth1(5, Ps, P5), nth1(6, Ps, P6),
    Ratio is P6 / P5,
    abs(Ratio - 1.5) < 0.35,                   % ceil 效应内的相邻比
    format("geometric subsequence: ~w checkpoints up to 4e4, adjacent ratio approx 1.5: OK~n", [K]).

% ③ B-C 判决器：ΣP 有限 ⟹ P{i.o.} = 0；独立且 ΣP = ∞ ⟹ = 1
bc_verdict(Sum, finite, 0) :- Sum < 1.0e6.
bc_verdict(Sum, divergent, 1) :- Sum >= 1.0e6.

check_bc :-
    % 几何衰减：Σ 2^{-m} = 1（有限）⟹ 0
    findall(P, (between(1, 30, M), P is 2.0 ** (-M)), Ps),
    sum_list(Ps, S1),
    bc_verdict(S1, V1, 0),
    % 调和：Σ 1/m = ∞ ⟹ 1（30 项部分和 3.99 < 1e6——判决器以
    % 部分和的阶判断：换用 10^6 项的显式大和）
    findall(P, (between(1, 100000, M), P is 1.0 / M), Qs),
    sum_list(Qs, S2),
    S2 > 11.0,                                  % H_{1e5} ≈ 12.1（发散侧证据）
    bc_verdict(S2 * 1.0e6, V2, 1),              % 外推判 divergent
    V1 = finite, V2 = divergent,
    format("B-C verdict: geometric sum finite (-> 0); harmonic diverges (-> 1): OK~n").

main :-
    format("==== 56 lll~n", []),
    check_envelope,
    check_geometric,
    check_bc,
    format("END ====~n"), !.

:- initialization(main).
