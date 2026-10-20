:- encoding(utf8).
% 54_universal_limits.pl —— 第 54 章：普遍极限（Prolog 通道）
%
% ① 无穷小条件的有限判决（给定阵列的 max P 显式核算）；
% ② 二项→Poisson 的精确分数对拍（pmf 权重比的逐项账）；
% ③ 退化 vs 非退化的特征函数判据（有限支撑 φ 值枚举）。

pow(_, 0, 1) :- !.
pow(B, N, P) :- N > 0, N1 is N - 1, pow(B, N1, Q), P is B * Q.

fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, G), F is N * G.

binom(_, 0, 1) :- !.
binom(N, K, 0) :- K > N, !.
% 乘积公式（O(k)——朴素 Pascal 递归在 n=1000 处 Θ(C(n,k)) 爆炸）
binom(N, K, R) :- K > 0, K =< N,
    Km is min(K, N - K), bp(N, Km, 0, 1, R).
bp(_, K, I, Acc, Acc) :- I >= K, !.
bp(N, K, I, Acc, R) :-
    I2 is I + 1,
    Acc2 is Acc * (N - I) / I2,
    bp(N, K, I2, Acc2, R).

% ① 无穷小判决：p_{n,k} = 1/n（k=1..n）⟹ max P{|X|>ε} = 1/n → 0
%    对照：p_{n,1} = 1/2 固定 ⟹ max = 1/2 ↛ 0
check_infinitesimal :-
    N = 100,
    MaxTiny is 1 / N,                      % 均匀小阵列的 max
    MaxOut is max(1/2, 1 / N),             % 带离群首项的 max
    MaxTiny < 0.05,                        % 无穷小 ✓
    MaxOut > 0.4,                          % 破坏 ✓
    format("infinitesimal: uniform 1/n array max = ~w -> 0; with outlier = ~w: OK~n",
           [MaxTiny, MaxOut]).

% ② 二项→Poisson 的权重比：C(n,k)·k!/n^k = prod_{j<k}(1−j/n) → 1
%    （λ^k 两端相消后的核心逼近——54.4 例 54.E 的代数心脏）
weight_ratio(N, K, R) :-
    binom(N, K, C), fact(K, F),
    R is C * F / (N ** K).

check_binom_poisson :-
    weight_ratio(100, 2, R2),
    weight_ratio(100, 5, R5),
    weight_ratio(1000, 5, R5b),
    abs(R2 - 1) < 0.05,                    % (1-1/100) ≈ 0.99
    abs(R5 - 1) < 0.12,                    % ∏(1-j/100) ≈ 0.90
    abs(R5b - 1) < 0.02,                   % n=1000 更近
    R5b > R5,                              % 单调改善
    format("Bin->Poisson weights: ratio(100,2)=~w ratio(100,5)=~w ratio(1000,5)=~w: OK~n",
           [R2, R5, R5b]).

% ③ 退化判据的 φ 值枚举：分布 X ∈ {0, 1}（P=p）：
%    φ(t) = 1−p+p·cos t（实部）。退化（p=0 或 1）⟹ |φ| ≡ 1；
%    非退化 ⟹ 存在 t 使 |φ| < 1（δ 的指纹）
phi_two_point(P, T, V) :- V is 1 - P + P * cos(T).

check_degeneracy :-
    % 退化 δ₀（p=0）：φ ≡ 1
    forall(between(1, 6, K), (T is K * 0.5, phi_two_point(0, T, V), abs(V - 1) < 1e-12)),
    % 非退化 p=1/2：t=π/2 处 φ = 1/2 < 1（非退化的指纹）
    phi_two_point(1/2, pi/2, V),
    abs(V - 1/2) < 1e-12,
    V < 1,
    format("degeneracy fingerprint: delta has |phi|=1 everywhere; p=1/2 has phi(pi/2)=1/2: OK~n").

main :-
    format("==== 54 universal_limits~n", []),
    check_infinitesimal,
    check_binom_poisson,
    check_degeneracy,
    format("END ====~n"), !.

:- initialization(main).
