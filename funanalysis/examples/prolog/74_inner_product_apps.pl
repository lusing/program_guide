:- encoding(utf8).
% 74_inner_product_apps.pl —— 内积应用的规则模型（docs/74 实验）
% 通道：SWI-Prolog（gprolog 兼容：format/2 带 []、main 尾部 !）
% 内容：相关系数计算与相似度分类、Gram 2x2 无关性判定、
%       法方程求解、弱收敛判据规则

% ---------- 相关系数与相似度（书 4.5.1） ----------
% vec/2：有限信号（列表）
dot([], [], 0.0) :- !.
dot([A|As], [B|Bs], S) :- dot(As, Bs, S0), S is S0 + A * B.
norm(V, N) :- dot(V, V, S), N is sqrt(S).

corr(X, Y, Rho) :-
    dot(X, Y, XY), norm(X, NX), norm(Y, NY),
    Rho is XY / (NX * NY).

% 相似度分类：|ρ| 阈值（书：ρ 越大越相似，ρ=1 完全相似）
similarity(X, Y, perfect)          :- corr(X, Y, R), R > 0.999999, !.
similarity(X, Y, similar)          :- corr(X, Y, R), R > 0.9, !.
similarity(X, Y, weakly_correlated) :- corr(X, Y, R), R > 0.5, !.
similarity(_, _, decorrelated).

% 最优尺度（书 4.5.1 的 λ* = Σxy/Σy²）
best_scale(X, Y, Lam) :- dot(X, Y, XY), dot(Y, Y, YY), Lam is XY / YY.

% 最小能量误差 minQ = ‖x‖² − (⟪x,y⟫)²/‖y‖²
min_energy(X, Y, Q) :-
    dot(X, Y, XY), dot(X, X, XX), dot(Y, Y, YY),
    Q is XX - XY * XY / YY.

% ---------- Gram 2x2 无关性（书 4.5.5） ----------
% gram2(X, Y, D)：D = ‖x‖²‖y‖² − ⟨x,y⟩²（Lagrange 恒等式 = 行列式）
gram2(X, Y, D) :-
    dot(X, X, XX), dot(Y, Y, YY), dot(X, Y, XY),
    D is XX * YY - XY * XY.

independent(X, Y) :- gram2(X, Y, D), D > 1e-12, !.
dependent(X, Y)   :- gram2(X, Y, D), D =< 1e-12.

% ---------- 法方程（书 4.5.3 的 2x2：正交基情形） ----------
% span{u,v} 正交时 Gram 对角化：a₁ = ⟨f,u⟩/⟨u,u⟩，a₂ = ⟨f,v⟩/⟨v,v⟩
normal_eq_diagonal(F, U, V, A1, A2) :-
    dot(U, V, 0.0),                      % 正交前提
    dot(F, U, FU), dot(U, U, UU),
    dot(F, V, FV), dot(V, V, VV),
    A1 is FU / UU, A2 is FV / VV.

% ---------- 实验 ----------
main :-
    format("==== 74 inner product apps (rule model) ====", []),

    % 实验 1：相关系数三分类
    S1 = [1.0, 2.0, 3.0, 4.0],
    S2 = [2.0, 4.0, 6.0, 8.0],           % S2 = 2*S1：完全相似
    S3 = [-1.0, -2.0, -3.0, -4.0],       % 反向：S3 = −S1，ρ = −1
    S4 = [1.0, -1.0, -1.0, 1.0],         % 与 S1 正交（Σxᵢyᵢ=0）
    similarity(S1, S2, perfect),
    corr(S1, S3, R13), abs(R13 + 1.0) < 1e-9,
    corr(S1, S4, R14), abs(R14) < 1e-9,
    format("~nEXP1 similarity: 2x-signal perfect (rho=1); reversed rho=~w; orthogonal rho=~w", [R13, R14]),

    % 实验 2：最优尺度与最小能量
    best_scale(S1, S2, Lam), abs(Lam - 0.5) < 1e-9,   % x = 0.5*y
    min_energy(S1, S2, Q), abs(Q) < 1e-9,             % 完全相似 ⟹ 零误差
    min_energy(S1, S4, Q2), Q2 > 0.1,
    format("~nEXP2 best scale: lambda*=0.5, minQ=0 (exact fit); orthogonal minQ=~w>0", [Q2]),

    % 实验 3：Gram 无关性（Lagrange 行列式）
    independent(S1, S4),
    dependent(S1, S2),                                  % 平行 ⟹ 行列式 0
    format("~nEXP3 gram determinant: {S1,S4} independent; {S1,2*S1} dependent (det=0)", []),

    % 实验 4：对角法方程（正交基）
    F = [1.0, 2.0, 1.0, 3.0],
    normal_eq_diagonal(F, [1.0,1.0,0.0,0.0], [0.0,0.0,1.0,1.0], A1, A2),
    abs(A1 - 1.5) < 1e-9, abs(A2 - 2.0) < 1e-9,
    format("~nEXP4 normal eq (orthogonal basis): a1=~w a2=~w (diagonal Gram)", [A1, A2]),

    format("~nEND ====", []), !.
