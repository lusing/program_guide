:- encoding(utf8).
% 22_max_principle.pl —— 第 22 章：极值原理与谱规则（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) 极值原理的推理规则版（书定理 2.1 的证明骨架做规则）；
%   (2) 五点矩阵谱知识；
%   (3) 存在唯一性（定理 2.2）的论证链。

% ---------- (1) 极值原理骨架 ----------
% 若 Δ_h u ≥ 0 且内点取严格最大值 M，则四邻点也须 = M（系数非负凸组合）
propagate_max(M, Neighbors) :-
    length(Neighbors, 4),   % 四邻全部 = M
    maplist(=(M), Neighbors).

% 传播到边界 ⟹ M ≤ 边界最大值，矛盾
contradiction_if(strict_interior_max, boundary_smaller).

% ---------- (2) 谱知识 ----------
five_point_eig(I, J, N, E) :- E is 4 - 2 * cos(I * pi / N) - 2 * cos(J * pi / N).
jacobi_radius(N, R) :- R is cos(pi / N).
min_eig(N, E) :- E is 8 * sin(pi / (2 * N)) ^ 2.   % I=J=1（坑账：小写 i/j 是原子）
hermitian(five_point_matrix).
diagonally_dominant(five_point_matrix, weak).      % 行和 = 0（弱占优）
irreducible(five_point_matrix).                     % 连通网格 ⟹ 严格占优结论可用

% ---------- (3) 存在唯一性论证链 ----------
% 齐次问题（零边界）⟹ 极值原理 ⟹ max ≤ 0 且 min ≥ 0 ⟹ u ≡ 0 ⟹ 唯一
homogeneous_zero(f, boundary_zero).
uniqueness_via(max_principle).
uniqueness_via(min_principle).

% ---------- main ----------
main :-
    format("==== 22 max principle~n"),

    propagate_max(1.0, [1.0, 1.0, 1.0, 1.0]),
    contradiction_if(strict_interior_max, boundary_smaller),
    format("max principle skeleton: strict interior max forces all neighbors = M;~n"),
    format("  propagation reaches boundary -> contradiction -> max on boundary~n"),

    five_point_eig(1, 1, 20, E11), E11 > 0,
    min_eig(20, E0), abs(E11 - E0) < 1e-12,
    jacobi_radius(20, R), R < 1,
    hermitian(five_point_matrix),
    diagonally_dominant(five_point_matrix, weak),
    irreducible(five_point_matrix),
    format("spectrum: min eig = 8 sin^2(pi/2N) = ~w > 0; Jacobi radius ~w < 1~n", [E0, R]),
    format("hermitian + weakly dominant + irreducible -> nonsingular (unique solution)~n"),

    homogeneous_zero(f, boundary_zero),
    uniqueness_via(max_principle),
    uniqueness_via(min_principle),
    format("uniqueness: homogeneous problem has only zero solution by both principles~n"),

    format("END ====~n").
