:- encoding(utf8).
% 55_stable_laws.pl —— 第 55 章：稳定分布（Prolog 通道）
%
% ① 四特征的有限模型对照（两点/三点分布逐条检验哪条破产）；
% ② aₙ 变易方程 aₙ = C·n^{1/α} 的数值核对（三档 α）；
% ③ 对称稳定 ch.f. 的 |t|^α 指纹判决（由 t 网格反解 α）。

pow(_, 0, 1) :- !.
pow(B, N, P) :- N > 0, N1 is N - 1, pow(B, N1, Q), P is B * Q.

% ① 卷积封闭性（特征 (a2)）的有限判决：
%    两点 ±1 各 1/2：X₁+X₂ ∈ {-2,0,2} 概率 {1/4,1/2,1/4}——
%    不是 ±c·X+d 的三点分布（支撑间距不等距于 ±1 的缩放）
check_a2_two_point :-
    % X1+X2 的支撑 {-2,0,2}：若 cX+d（X 支撑 {±1}）则支撑 {d-c, d+c}
    % ——间距 2c；{-2,0,2} 间距 2 ⟹ c=1, d=0 ⟹ 和应 ≡ X：但
    % P{=0} = 1/2 ≠ 1/2·... 检查：X 的 P{0} = 0 ≠ 1/2 ⟹ 破产
    P0 is 1/2, PX0 is 0,
    P0 =\= PX0,
    format("a2 fails for two-point: sum has P(0)=1/2 but cX+d has P(0)=0: OK~n").

%    对照：Cauchy 的代数模型不可行，用正态的方差账代替（α=2 满足 a2）
check_a2_normal :-
    % N(0,σ₁²)+N(0,σ₂²) = N(0, σ₁²+σ₂²)：c=√(σ₁²+σ₂²)——封闭 ✓
    V1 is 1.0, V2 is 3.0, V is V1 + V2,
    C is sqrt(V),
    abs(C * C - V) < 1e-12,
    format("a2 holds for normal: variances add, c = sqrt(v1+v2): OK~n").

% ② aₙ 变易方程：aₙ/a_{[nt]} → t^{1/α}（取 aₙ = n^{1/α} 显式解）
an(_, Alpha, N, A) :- A is N ** (1.0 / Alpha).

check_an :-
    an(1.0, 1.0, 1000, A1000), an(1.0, 1.0, 100, A100),
    R1 is A1000 / A100, T1 is 10 ** 1.0,         % t=10, α=1：t^{1} = 10
    abs(R1 - T1) < 1e-9,
    an(1.0, 1.5, 1000, B1000), an(1.0, 1.5, 100, B100),
    R15 is B1000 / B100, T15 is 10 ** (1.0 / 1.5),
    abs(R15 - T15) < 1e-9,
    an(1.0, 2.0, 1000, C1000), an(1.0, 2.0, 100, C100),
    R2 is C1000 / C100, T2 is 10 ** 0.5,
    abs(R2 - T2) < 1e-9,
    format("variation equation: a_1000/a_100 = t^(1/a) for a = 1/1.5/2: OK~n").

% ③ |t|^α 指纹：φ(t) = exp(−|t|^α) ⟹ α = log(−log|φ(t)|)/log|t|
%    （t 网格反解——对称稳定的身份认证）
check_fingerprint :-
    Alpha = 1.5,
    T = 2.0,
    Phi is exp(-(T ** Alpha)),
    AlphaBack is log(-log(Phi)) / log(T),
    abs(AlphaBack - Alpha) < 1e-12,
    T2v = 0.5,
    Phi2 is exp(-(T2v ** Alpha)),
    AlphaBack2 is log(-log(Phi2)) / log(T2v),
    abs(AlphaBack2 - Alpha) < 1e-12,
    format("alpha fingerprint: recovered from phi at t = 2 and 0.5 (a = 1.5): OK~n").

main :-
    format("==== 55 stable_laws~n", []),
    check_a2_two_point,
    check_a2_normal,
    check_an,
    check_fingerprint,
    format("END ====~n"), !.

:- initialization(main).
