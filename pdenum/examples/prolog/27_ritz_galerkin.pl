:- encoding(utf8).
% 27_ritz_galerkin.pl —— 第 27 章：Ritz/Galerkin/权余量规则引擎（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) Ritz 系数方程：Σ c_j D(φ_j, φ_i) = F(φ_i)；
%   (2) Galerkin 同一方程（对称正定时）；
%   (3) 权余量家族：配点法/子域法/最小二乘/矩法/Galerkin 的权函数表。

% ---------- (1) Ritz 系数方程 ----------
% J(v) = 1/2 D(v,v) - F(v)；v = Σ c_j φ_j；dJ/dc_i = 0 ⟹
% Σ_j c_j D(φ_j, φ_i) = F(φ_i)
ritz_equation(_, _, _) :-
    format("sum_j c_j D(phi_j, phi_i) = F(phi_i)  for all i~n").

% ---------- (2) Galerkin ----------
% 残差 R = Lu - f 正交于全部基函数：∫R·φ_i = 0 ⟹ 同一方程
galerkin_equation(A, B) :-
    ritz_equation(A, B, B),
    format("identical system when D symmetric positive~n").

% ---------- (3) 权余量家族 ----------
% 加权余量法 ∫R·w_i = 0 的权选择：
weight(collocation, delta_at_points).      % 配点法：w_i = δ(x - x_i)
weight(subdomain, characteristic).         % 子域法：w_i = χ_i（分块特征函数）
weight(least_squares, dR_dc_i).            % 最小二乘：w_i = ∂R/∂c_i
weight(moment, x_pow_i).                   % 矩法：w_i = x^i
weight(galerkin, phi_i).                   % Galerkin：w_i = 基函数本身

% 收敛性直觉：权与试探函数同族（Galerkin）时矩阵对称
galerkin_symmetric(yes).

% ---------- main ----------
main :-
    format("==== 27 ritz galerkin~n"),

    ritz_equation(_, _, _),
    galerkin_equation(_, _),

    weight(collocation, delta_at_points),
    weight(galerkin, phi_i),
    weight(moment, x_pow_i),
    forall(member(M, [collocation, subdomain, least_squares, moment, galerkin]),
           weight(M, _)),
    format("weighted residual family: collocation/subdomain/LS/moment/Galerkin~n"),
    format("  all reduce to sum_j c_j A_ij = b_i with different weights~n"),

    galerkin_symmetric(yes),
    format("Galerkin (w = trial family): symmetric matrix, best in energy norm~n"),

    format("END ====~n").
