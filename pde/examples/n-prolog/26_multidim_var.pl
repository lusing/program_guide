:- encoding(utf8).
% 26_multidim_var.pl —— 第 26 章：变分形式规则（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) Ritz/Galerkin 等价规则（D 对称正定 ⟺ 两原理等价）；
%   (2) 非齐次边界提升规则；
%   (3) 间断系数界面条件规则。

% ---------- (1) 等价性 ----------
symmetric(bilinear_D).
positive_semi_definite(X) :- symmetric(X).
equiv(ritz, galerkin) :- positive_semi_definite(_).
% 力学对应：Ritz = 最小势能原理，Galerkin = 虚功原理
mechanics(ritz, minimum_potential_energy).
mechanics(galerkin, virtual_work).

% ---------- (2) 提升 ----------
% 非齐次边界 u|∂ = g：取 u0 延拓 g，u = u0 + w（w 零边界）
% 方程变为 -Δw = f + Δu0
lift(boundary_g, source_f, w_equation(f_plus_delta_u0)).

% ---------- (3) 间断系数界面条件 ----------
% k1 u1 = k2 u2（通量连续）与 u1 = u2（温度连续）在界面 Γ
interface_condition(flux_continuity, k1 * du1dn = k2 * du2dn).
interface_condition(value_continuity, u1 = u2).
% 变分形式自动包含这两个条件（弱解的定义吸收界面跳变）

% ---------- main ----------
main :-
    format("==== 26 multidim var~n"),

    symmetric(bilinear_D), positive_semi_definite(bilinear_D),
    equiv(ritz, galerkin),
    mechanics(ritz, minimum_potential_energy),
    mechanics(galerkin, virtual_work),
    format("symmetric positive D: Ritz (min potential energy) == Galerkin (virtual work)~n"),

    lift(boundary_g, source_f, w_equation(f_plus_delta_u0)),
    format("lifting: u = u0 + w, w solves -lap w = f + lap u0~n"),

    interface_condition(flux_continuity, _),
    interface_condition(value_continuity, _),
    format("interface (discontinuous k): flux continuity + value continuity,~n"),
    format("  both absorbed automatically by the weak formulation~n"),

    format("END ====~n").


