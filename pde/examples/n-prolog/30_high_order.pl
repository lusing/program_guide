:- encoding(utf8).
% 30_high_order.pl —— 第 30 章：高次元与等参元规则（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) 一维 Lagrange/Hermite 基函数表；
%   (2) 面积坐标规则（和恒等、顶点/边中点取值）；
%   (3) 等参元映射规则（参考元 ↔ 物理元）。

% ---------- (1) 基函数表 ----------
% 二次 Lagrange（参考元 [-1,1]，节点 -1, 0, 1）：
lagrange2(node_m1, xi_times_xi_minus_1_over_2).
lagrange2(node_0,  one_minus_xi_squared).
lagrange2(node_p1, xi_times_xi_plus_1_over_2).
% Hermite（书 3.1.2）：两节点 + 两导数自由度
hermite3(h00, cubic_two_node_value_basis).
hermite3(h10, cubic_two_node_slope_basis).

% ---------- (2) 面积坐标 ----------
% L1 + L2 + L3 = 1 恒成立；顶点 i：L_i = 1；边中点 ij：L_i = L_j = 1/2
area_sum_identity(1).
area_at_vertex(i, [1, 0, 0]).
area_at_edge_mid(i_j, [1/2, 1/2, 0]).
% 二次基（6 自由度）：
% 顶点基 N_i = L_i(2L_i - 1)；边中点基 N_ij = 4 L_i L_j

% ---------- (3) 等参元 ----------
% 几何与未知量用同一组基映射：x = Σ N_i(ξ,η) x_i
isoparametric(same_basis_for_geometry_and_field).
% 曲边单元：增加中边节点可精确表示二次曲边
curved_edge(needs_midside_nodes).

% ---------- main ----------
main :-
    format("==== 30 high order~n"),

    lagrange2(node_m1, _), lagrange2(node_0, _), lagrange2(node_p1, _),
    format("1D quadratic Lagrange: 3 dofs per element (endpoints + midpoint)~n"),
    hermite3(h00, cubic_two_node_value_basis),
    hermite3(h10, cubic_two_node_slope_basis),
    format("1D Hermite cubic: value + slope dofs (C1 continuity)~n"),

    area_sum_identity(1),
    area_at_vertex(i, [1, 0, 0]),
    area_at_edge_mid(i_j, [1/2, 1/2, 0]),
    format("area coords: L1+L2+L3=1; vertex L_i=1; edge mid L_i=L_j=1/2~n"),
    format("  quadratic triangle: 6 dofs, N_i = L_i(2L_i-1), N_ij = 4 L_i L_j~n"),

    isoparametric(same_basis_for_geometry_and_field),
    curved_edge(needs_midside_nodes),
    format("isoparametric: geometry and field share the same basis;~n"),
    format("  curved boundaries need midside nodes~n"),

    format("END ====~n").
