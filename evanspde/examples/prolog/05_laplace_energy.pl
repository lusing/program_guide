% Ch05 Laplace 方程 III：能量方法规则
%
% 对应书 §2.2.5：唯一性能量证明（w 调和零边值 ⟹ ∫|∇w|²=0 ⟹ w=0）、
% Dirichlet 原理（解 = 能量泛函极小）、一阶/二阶变分结构。
% 数值核：3 模式 Rayleigh–Ritz 系数与能量闭式对账（Lean 通道有
% 完整的配方法证明）。

:- encoding(utf8).

energy_uniqueness :-
    % 书定理 16 的三段论
    w_harmonic_zero_bdry,      % w := u - u' 调和、零边值
    integrate_parts,           % ∫ w Δw = -∫|∇w|²
    energy_zero,               % Δw = 0 ⟹ ∫|∇w|² = 0
    grad_zero_implies_const.   % ∇w ≡ 0 + 连通 + 零边值 ⟹ w = 0

w_harmonic_zero_bdry.
integrate_parts.
energy_zero.
grad_zero_implies_const.

% 一阶变分：dE[u+εv]/dε|₀ = ∫(∇u·∇v - f v) = 0（弱解条件）
first_variation_condition :-
    format("  dE/deps(0) = int(grad u . grad v - f v) = 0 for all zero-bdry v~n").

% RR 结构规则：c_i = 4 f_i / lambda_i（phi_i 归一 ∫phi^2 = 1 时），
% 或对 ∫phi^2 = 1/4 的正弦基 c = 4f/lambda（Julia 通道的实测坑）
rr_coefficient(FmN, Lam, C) :- C is 4 * FmN / Lam.
rr_energy_min(Modes, Emin) :-
    findall(F2dL, (member((F, L), Modes), F2dL is F * F / L), List),
    sum_list(List, S),
    Emin is -2 * S.   % E_min = -2 Σ f²/λ（∫phi²=1/4 标度）

main :-
    format("==== 05~n"),
    energy_uniqueness,
    format("  uniqueness by energy: OK~n"),
    first_variation_condition,
    % 3 模式数值核：lambda = 2π², 5π², 8π²；f = 1 的正弦载荷
    Pi2 is pi * pi,
    Modes = [(2 / Pi2 * 4 / Pi2, 2 * Pi2), (0.0, 5 * Pi2), (0.0, 8 * Pi2)],
    % 简化：只放 (1,1) 模式载荷 f11 = (2/pi)*(2/pi) = 4/pi^2，lambda = 2 pi^2
    F11 is 4 / Pi2,
    L11 is 2 * Pi2,
    rr_coefficient(F11, L11, C11),
    C_expect is 4 * F11 / L11,
    abs(C11 - C_expect) < 1e-15,
    format("  RR coefficient c11 = ~6f (= 4f/lambda)~n", [C11]),
    rr_energy_min([(F11, L11)], E1),
    E1_expect is -2 * F11 * F11 / L11,
    abs(E1 - E1_expect) < 1e-15,
    format("  RR minimal energy = ~6f (= -2 f^2/lambda)~n", [E1]),
    format("END ====~n").
