:- encoding(utf8).
% 72_poincare_embedding.pl —— Poincaré 与嵌入的规则模型（docs/72 实验）
% 通道：SWI-Prolog（gprolog 兼容：format/2 带 []、main 尾部 !）
% 内容：零边界判定与 Poincaré 生效规则、嵌入三段式的维数-指数规则、
%       紧嵌入规则、Hölder 指数计算

% ---------- Poincaré 的生效条件（书 6.1.1 / 6.1.6 / 6.2.3） ----------
% poincare(U)：‖U‖_{L²} ≤ C‖∇U‖_{L²} 成立
zero_boundary(sinqx).            % sin(πx)：两端为零的样板
zero_boundary(hat(_)).           % 帽基函数：紧支撑 ⟹ 零边界
poincare(U) :- zero_boundary(U), !.
poincare(U) :- in_w01(U).        % W_0^{1,2} 全体（闭包定义自动零迹）
poincare_broken(const).          % 常数函数：‖u‖=1, ‖∇u‖=0，破坏

in_w01(sinqx).
in_w01(hat(_)).


% ---------- 嵌入三段式（书 6.2.6）：n 维、W^{k,p} 的目标空间 ----------
% embeds(N, K, P, Target)：
%   kp > N        → L^q 对一切 q（含 L^∞ 当 kp > N 的 Hölder 段）
%   kp = N        → L^q 对一切 q < ∞（临界：不含 L^∞）
%   kp < N        → L^{Np/(N−kp)}（临界指数 q*）
embeds(N, K, P, lq(any)) :- K * P > N, !.
embeds(N, K, P, lq(finite)) :- K * P =:= N, !.
embeds(N, K, P, lq(Q)) :- K * P < N, Q is N * P / (N - K * P).

% Hölder 指数（kp > N 时的 C^{m,λ} 段）：λ = 1 − N/(kp) 的整数分解
holder_exponent(N, K, P, M, Lam) :-
    KP is K * P,
    KP > N,
    M is floor(KP - N / P),        % 整数光滑度（简化模型）
    Lam is min(1.0, KP - N - (KP - N - min(1.0, KP - N))),
    Lam > 0.

% ---------- 紧嵌入（书 6.2.7）：q < 临界指数 ⟹ 紧 ----------
compact_embeds(N, K, P, Q) :-
    embeds(N, K, P, lq(Qstar)),
    number(Qstar) -> Q < Qstar ; true.      % 非临界带全紧（模型简化）

% 一维特例：W^{1,p}(0,1) ⊂ C^{0,1−1/p}（Morrey；p=1 时 Lipschitz→C⁰）
morrey_holder_exponent(P, Lam) :- P >= 1, Lam is 1 - 1 / P.

% ---------- 实验 ----------
main :-
    format("==== 72 poincare & embedding (rule model) ====", []),

    % 实验 1：Poincaré 生效与破坏
    poincare(sinqx),
    poincare(hat(3)),
    \+ poincare_broken(sinqx),
    format("~nEXP1 poincare holds for zero-boundary data (sin, hats); const breaks it", []),

    % 实验 2：嵌入三段式读表
    embeds(3, 1, 2, T32), T32 = lq(6),          % W^{1,2}(R^3) → L^6（经典）
    embeds(2, 1, 2, T22), T22 = lq(finite),     % 临界：n=kp，不含 L^∞
    embeds(3, 2, 2, T322), T322 = lq(any),      % kp=4>3：全 q
    format("~nEXP2 three regimes: W12(R3)->L6 ; W12(R2)->Lq(fin) ; W22(R3)->all", []),

    % 实验 3：Hölder 指数
    morrey_holder_exponent(2, L2), abs(L2 - 0.5) < 1e-9,
    morrey_holder_exponent(1, L1), abs(L1) < 1e-9,
    format("~nEXP3 1D Morrey exponents: p=2 -> lambda=0.5 ; p=1 -> lambda=0 (C^0)", []),

    % 实验 4：紧嵌入规则
    compact_embeds(3, 1, 2, 2),                  % q=2 < 6 ⟹ 紧
    compact_embeds(3, 1, 2, 4),
    format("~nEXP4 compact embedding: W12(R3) ->> Lq for every q < 6 (Rellich-Kondrachov)", []),

    format("~nEND ====", []), !.
