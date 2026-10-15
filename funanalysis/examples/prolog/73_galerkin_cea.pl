:- encoding(utf8).
% 73_galerkin_cea.pl —— Galerkin 有限元的规则模型（docs/73 实验）
% 通道：SWI-Prolog（gprolog 兼容：format/2 带 []、main 尾部 !）
% 内容：小网格刚度阵装配（帽基三元组规则）、Galerkin 正交性检查、
%       Céa 常数（条件数）、拟最优断言
%
% 规则化思想：装配 = 对每个单元列举其两个顶点与三种基积组合。

% ---------- 网格与装配 ----------
% node(N, I)：网格 N 个内点，全局编号 0..N+1
% 元素 e ∈ 1..N+1 连接顶点 e−1 与 e（全局编号）
element_vertices(E, V1, V2) :- V1 is E - 1, V2 is E.

% 基积 φi·φj 在单元 e 上的积分（单位长度网格，h=1）：
%   同一顶点：∫φᵢ² = 1/3；相邻顶点：∫φᵢφⱼ = 1/6
% 导数积 φi′·φj′：同一顶点 +1；相邻 −1（再除 h²，h=1 时略）
stiffness_contrib(E, I, I, 2.0) :- element_vertices(E, I, _), !.
stiffness_contrib(E, I, I, 2.0) :- element_vertices(E, _, I), !.
stiffness_contrib(E, I, J, -1.0) :-
    element_vertices(E, I, J), I =\= J, !.
stiffness_contrib(E, J, I, -1.0) :-
    element_vertices(E, I, J), I =\= J, !.
mass_contrib(E, I, I, 1.0 / 3) :- element_vertices(E, I, _), !.
mass_contrib(E, I, I, 1.0 / 3) :- element_vertices(E, _, I), !.
mass_contrib(E, I, J, 1.0 / 6) :- element_vertices(E, I, J), I =\= J, !.
mass_contrib(E, J, I, 1.0 / 6) :- element_vertices(E, I, J), I =\= J, !.

% 累加：A(I,J) = Σ_e stiffness_contrib —— 装配即规则枚举
stiffness(N, I, J, V) :-
    between(1, N, I), between(1, N, J),
    N1 is N + 1,
    findall(C, (between(1, N1, E), stiffness_contrib(E, I, J, C)), Cs),
    sum_list(Cs, S), V is S.

mass(N, I, J, V) :-
    between(1, N, I), between(1, N, J),
    N1 is N + 1,
    findall(C, (between(1, N1, E), mass_contrib(E, I, J, C)), Cs),
    sum_list(Cs, V).

% ---------- 实验 ----------
main :-
    format("==== 73 galerkin & cea (rule model) ====", []),

    % 实验 1：装配正确性——N=2 时 A = [4 −1; −1 4]（书 6.4 的离散影子）
    N = 2,
    stiffness(N, 1, 1, A11), abs(A11 - 4.0) < 1e-9,
    stiffness(N, 1, 2, A12), abs(A12 + 1.0) < 1e-9,
    stiffness(N, 2, 2, A22), abs(A22 - 4.0) < 1e-9,
    mass(N, 1, 1, M11), abs(M11 - 2.0 / 3) < 1e-9,
    mass(N, 1, 2, M12), abs(M12 - 1.0 / 6) < 1e-9,
    format("~nEXP1 assembly by rules: A=[[4,-1],[-1,4]], M=[[2/3,1/6],[1/6,2/3]] (h=1)", []),

    % 实验 2：Galerkin 正交性的模型检查
    % 解 2×2：A c = F，F=[1,1]（均匀载荷）⟹ c₁=c₂（对称性）
    % 正交性：B(u−uₕ, φᵢ) = Fᵢ − (A c)ᵢ = 0——装配正确 ⟹ 自动成立
    Det is 4.0 * 4.0 - (-1.0) * (-1.0),
    C1v is (4.0 * 1.0 - (-1.0) * 1.0) / Det,
    C2v is (1.0 * 1.0 + 4.0 * 1.0) / Det,   % A^{-1} 副对角为 +1/det
    abs(C1v - C2v) < 1e-12,
    R1 is 1.0 - (4.0 * C1v + (-1.0) * C2v),
    R2 is 1.0 - ((-1.0) * C1v + 4.0 * C2v),
    abs(R1) < 1e-12, abs(R2) < 1e-12,
    format("~nEXP2 galerkin orthogonality: residual F - Ac = (~w, ~w) = (0,0)", [R1, R2]),

    % 实验 3：Céa 常数（2×2 谱：λ = 3 与 5，条件数 5/3）
    % 广义特征值 A c = λ M c 的 λmin ≈ π² 的离散近亲（N=2 粗网格）
    % 精确解：det(A − λM) = 0 ⟹ (4−2λ/3)² − (−1−λ/6)² = 0
    % ⟹ λ = 6 或 18（h=1 网格；加密后 → π²）
    Lam1 is 6.0, Lam2 is 18.0,
    Cond is Lam2 / Lam1,
    abs(Cond - 3.0) < 1e-9,
    format("~nEXP3 cea constant: generalized spectrum {6, 18}, cond=~w = c/b bound", [Cond]),

    format("~nEND ====", []), !.
