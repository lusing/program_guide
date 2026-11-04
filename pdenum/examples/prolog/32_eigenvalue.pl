:- encoding(utf8).
% 32_eigenvalue.pl —— 第 32 章：特征值与变分不等式规则（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) Rayleigh-Ritz：lam1_h >= lam1（从上方逼近）；
%   (2) 极小极大原理：lam_k = min_{dim S=k} max_{v in S} R(v)；
%   (3) 变分不等方程：u >= psi 约束 + 互补条件规则。

% ---------- (1) 广义特征值问题的结构 ----------
fem_eig_problem(K_c, M_c, generalized) :-
    format("K c = lam M c with K stiffness, M mass (hat basis)~n").

% ---------- (2) 极小极大 ----------
rayleigh_ritz(above) :- format("lam1_h >= lam1_exact (min over subspace >= min over whole space)~n").
minmax(lam_k, min_over_kdim_subspaces(max_rayleigh)).
% 离散谱从上方逐个逼近连续谱

% ---------- (3) 变分不等方程 ----------
% 障碍问题：求 u >= psi 使 D(u, v-u) >= F(v-u) 对一切 v >= psi
obstacle_constraint(u_ge_psi).
complementarity(free_region, minus_lap_u_eq_f).
complementarity(active_region, minus_lap_u_ge_f).
% 投影 SOR：Gauss-Seidel 更新后投影回 [psi, +inf)
projected_sor(update, max(psi_new, projected)).

% ---------- main ----------
main :-
    format("==== 32 eigenvalue~n"),

    fem_eig_problem(stiffness, mass, generalized),
    rayleigh_ritz(above),
    minmax(lam_k, min_over_kdim_subspaces(max_rayleigh)),
    format("eigen convergence: lam_j_h -> lam_j from above, O(h^2)~n"),

    obstacle_constraint(u_ge_psi),
    complementarity(free_region, minus_lap_u_eq_f),
    complementarity(active_region, minus_lap_u_ge_f),
    projected_sor(update, max(psi_new, projected)),
    format("obstacle problem: u >= psi; free region PDE holds,~n"),
    format("  active region u = psi; solved by projected SOR~n"),

    format("END ====~n").
