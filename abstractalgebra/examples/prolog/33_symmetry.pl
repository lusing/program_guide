:- encoding(utf8).
% 第 33 章 · 装饰的对称 —— Prolog 通道
%
% 仿射等距 iso(Sx, Sy, N)（z ↦ (Sx·x + N/2, Sy·y)）的整数编码 +
% 带群关系 + 窗口计数 + 晶体学限制（2×2 整矩阵阶枚举）。

% ---------- 复合与逆（全整数：N 以半单位计） ----------
% comp((sx1,sy1,n1),(sx2,sy2,n2)) = (sx1·sx2, sy1·sy2, sx1·n2 + n1)
comp_(iso(A1,B1,C1), iso(A2,B2,C2), iso(A,B,C)) :-
    A is A1 * A2,
    B is B1 * B2,
    C is A1 * C2 + C1.

inv_(iso(A, B, C), iso(A, B, Ci)) :- Ci is -C.   % 线性部分自逆

% 五个基本等距
id_iso(iso(1,1,0)).
t_iso(iso(1,1,2)).        % t：x ↦ x + 1
tinv_iso(iso(1,1,-2)).
rho_iso(iso(1,-1,1)).     % ρ：x ↦ x + 1/2, y ↦ −y
rh_iso(iso(-1,-1,0)).     % R：半翻转
al_iso(iso(1,-1,0)).      % α：x-轴反射
be_iso(iso(-1,1,0)).      % β：y-轴反射

% ---------- 带群窗口（|N| ≤ 6 即 |平移| ≤ 3） ----------
frieze_window(Gens, S) :-
    maplist([G, Gi]>>inv_(G, Gi), Gens, Ginvs),
    append(Gens, Ginvs, Gf),
    id_iso(Id),
    grow([Id], Gf, S0),
    sort(S0, S).

grow(S0, Gf, S) :-
    findall(P, (member(A, S0), member(G, Gf), comp_(A, G, P),
                P = iso(_, _, N), abs(N) =< 6), New),
    append(S0, New, C), sort(C, S1),
    (S1 == S0 -> S = S1 ; grow(S1, Gf, S)).

% ---------- 2×2 整矩阵阶（晶体学限制） ----------
mat_mul([A,B,C,D], [E,F,G,H], [X,Y,Z,W]) :-
    X is A*E + B*G, Y is A*F + B*H,
    Z is C*E + D*G, W is C*F + D*H.

mat_order(M, Ord) :-
    M = [1,0,0,1], !, Ord = 1.
mat_order(M, Ord) :-
    mat_mul(M, M, X0), mat_order_(M, X0, 2, Ord).

mat_order_(_, X, K, K) :- X = [1,0,0,1], !.
mat_order_(M, X, K0, Ord) :-
    K0 < 12,
    K1 is K0 + 1,
    mat_mul(M, X, X1),
    mat_order_(M, X1, K1, Ord).

% ---------- 主流程 ----------
main :-
    format("==== 33 装饰的对称~n"),

    % 关系式（定理 6.42 的基础代数，整数精确）
    t_iso(T), rho_iso(Rho), rh_iso(R), al_iso(Al), be_iso(Be),
    tinv_iso(Tinv), id_iso(Id),
    comp_(Rho, Rho, T),                       % ρ² = t
    comp_(R, R, Id), comp_(Al, Al, Id), comp_(Be, Be, Id),
    comp_(Be, Al, R),                         % βα = R
    comp_(Al, T, TA), comp_(T, Al, TA),       % αt = tα
    comp_(Be, T, BT), comp_(Tinv, Be, BT),    % βt = t⁻¹β
    comp_(R, T, RT), comp_(Tinv, R, RT),      % Rt = t⁻¹R
    format("关系式：ρ²=t、R²=α²=β²=1、βα=R、αt=tα、βt=t⁻¹β、Rt=t⁻¹R（整数精确）✓~n"),

    % 带群窗口计数
    frieze_window([T], F1),        length(F1, 7),
    frieze_window([T, R], F2),     length(F2, 14),
    frieze_window([T, Al], F4),    length(F4, 14),
    frieze_window([T, R, Al], F7), length(F7, 28),
    format("带群窗口：F₁=7、F₂=14、F₄=14、F₇=28（对 ⟨t⟩ 指数 1/2/2/4）✓~n"),

    % 点群（推论 6.49）：F₇ 的点群 = V₄，封闭/自逆/交换
    findall([Sx,Sy], (member(iso(Sx,Sy,_), F7)), Lins0),
    sort(Lins0, Lins),
    Lins = [[-1,-1],[-1,1],[1,-1],[1,1]],
    forall((member(L1, Lins), member(L2, Lins)),
           (sgn_mul(L1, L2, L3), member(L3, Lins))),
    forall(member(L, Lins), sgn_mul(L, L, [1,1])),
    format("点群：F₇ 的点群 = V₄ = {(1,1),(1,−1),(−1,1),(−1,−1)}，封闭自逆交换 ✓~n"),

    % F₅ = ⟨ρ⟩ ≅ ℤ：ρ² = t
    comp_(Rho, Rho, T),
    format("F₅ = ⟨ρ⟩：ρ² = t ⟹ ⟨t⟩ ≤ ⟨ρ⟩，无限循环 ≅ ℤ ✓~n"),

    % 晶体学限制：{−1,0,1} 矩阵可逆者的阶 ⊆ {1,2,3,4,6}
    findall(K, (between(-1, 1, A), between(-1, 1, B),
                between(-1, 1, C), between(-1, 1, D),
                A*D - B*C =\= 0,
                mat_order([A,B,C,D], K)), Ks0),
    sort(Ks0, [1,2,3,4,6]),
    format("晶体学限制：可逆 {−1,0,1} 矩阵的阶恰 {1,2,3,4,6}（无 5、无 7+）✓~n"),

    % 迹核对：阶 3 矩阵 [0,−1,1,−1] 迹 −1；阶 6 矩阵 [0,−1,1,1] 迹 1
    M3 = [0,-1,1,-1], M3 = [A3,_,_,D3],
    mat_order(M3, 3), Tr3 is A3 + D3, Tr3 =:= -1,
    M6 = [0,-1,1,1], M6 = [A6,_,_,D6],
    mat_order(M6, 6), Tr6 is A6 + D6, Tr6 =:= 1,
    format("迹：120° 旋转迹 −1 = 2cos(2π/3)、60° 迹 1 = 2cos(2π/6) ✓~n"),

    format("END ====~n").

sgn_mul([A1,B1], [A2,B2], [A,B]) :- A is A1 * A2, B is B1 * B2.
