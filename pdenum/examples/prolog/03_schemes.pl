:- encoding(utf8).
% 03_schemes.pl —— 第 03 章：差分格式的构造（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% 三件事：
%   (1) 差商判阶引擎：对表达式树数值测前差/后差/中心差/二阶中心差
%       逼近导数的阶（h 与 h/2 的误差比）；
%   (2) 差分格式知识表：模板、截断误差阶、相容性；
%   (3) 网格比与迎风方向规则（a>0 取左差）。

% ---------- 表达式求值内核（单变量 x） ----------
ev_at(n(C), _, C).
ev_at(x, X, X).
ev_at(add(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA + VB.
ev_at(sub(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA - VB.
ev_at(mul(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA * VB.
ev_at(div(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA / VB.
ev_at(neg(A), X, V) :- ev_at(A, X, VA), V is -VA.
ev_at(exp(A), X, V) :- ev_at(A, X, VA), V is exp(VA).
ev_at(sin(A), X, V) :- ev_at(A, X, VA), V is sin(VA).
ev_at(cos(A), X, V) :- ev_at(A, X, VA), V is cos(VA).
ev_at(pow(A, N), X, V) :- ev_at(A, X, VA), V is VA ^ N.

% ---------- (1) 差商判阶引擎 ----------
% D_h 近似 D 值在 X 的误差：E(X±H) 由 ev_at 在平移点直接求值
dq_err(forward, E, DE, X, H, Err) :-
    ev_at(E, X, FX), ev_at(E, X + H, FXP),
    ev_at(DE, X, DFX),
    Err is abs((FXP - FX) / H - DFX).
dq_err(backward, E, DE, X, H, Err) :-
    ev_at(E, X, FX), ev_at(E, X - H, FXM),
    ev_at(DE, X, DFX),
    Err is abs((FX - FXM) / H - DFX).
dq_err(central, E, DE, X, H, Err) :-
    ev_at(E, X + H, FXP), ev_at(E, X - H, FXM),
    ev_at(DE, X, DFX),
    Err is abs((FXP - FXM) / (2 * H) - DFX).
dq_err(second_central, E, D2E, X, H, Err) :-
    ev_at(E, X + H, FXP), ev_at(E, X, FX), ev_at(E, X - H, FXM),
    ev_at(D2E, X, D2FX),
    Err is abs((FXP - 2 * FX + FXM) / (H * H) - D2FX).

measured_order(Kind, E, DE, X, Order) :-
    dq_err(Kind, E, DE, X, 1.0e-2, E1),
    dq_err(Kind, E, DE, X, 5.0e-3, E2),
    Order is log(E1 / E2) / log(2.0).

% ---------- (2) 差分格式知识表 ----------
% scheme(名字, 方程, 模板描述, 对τ的精度阶, 对h的精度阶)
scheme(ftbs, advection, [n, j, j-1], 1, 1).        % 迎风：时间前差+空间后差
scheme(ftfs, advection, [n, j, j+1], 1, 1).        % 顺风（a>0 不稳定）
scheme(ftcs_advection, advection, [n, j, j-1/j+1], 1, 2).  % 时间前差空间中心
scheme(ftcs_heat, diffusion, [n, j-1/j/j+1], 1, 2).        % 显式热传导
scheme(btcs_heat, diffusion, [n+1, j-1/j/j+1], 1, 2).      % 隐式热传导

% 截断误差主项（书 (2.5)(2.6) 的结论，符号微分验证见 Julia/Python 通道）
trunc_main(ftbs, mul(n(1), mul(h, div(d2y, n(2))))).          % τ/2 u_tt − ah/2 u_xx 组合
trunc_main(ftcs_heat, sub(mul(n(1), mul(tau, div(d2t, n(2)))),
                          mul(n(1), mul(h, mul(h, div(d4x, n(12))))))).

% 相容性：截断误差阶 > 0 ⟹ 相容
consistent(S) :- scheme(S, _, _, P, Q), P > 0, Q > 0.

% ---------- (3) 网格比与迎风规则 ----------
mesh_ratio(Lam, A, Tau, H) :- Lam is A * Tau / H.
% a>0 特征向右传播（依赖左边的值）⟹ 用左差（后差）空间算子
upwind_dir(A, backward) :- A > 0, !.
upwind_dir(A, forward) :- A < 0.
% 隐式格式每步须解三对角方程组：追赶法（Thomas）工作量 3J-3 乘除
thomas_work(J, W) :- W is 3 * J - 3.

% ---------- main ----------
main :-
    format("==== 03 schemes~n"),

    % (1) 差商判阶：u = sin x, u' = cos x, u'' = -sin x
    U = sin(x), DU = cos(x), D2U = neg(sin(x)),
    measured_order(forward, U, DU, 1.0, O1),
    measured_order(backward, U, DU, 1.0, O2),
    measured_order(central, U, DU, 1.0, O3),
    measured_order(second_central, U, D2U, 1.0, O4),
    R1 is round(O1 * 1000) / 1000, R2 is round(O2 * 1000) / 1000,
    R3 is round(O3 * 1000) / 1000, R4 is round(O4 * 1000) / 1000,
    format("diff orders: fwd ~w bwd ~w ctr ~w 2nd ~w~n", [R1, R2, R3, R4]),
    abs(O1 - 1) < 0.1, abs(O2 - 1) < 0.1,
    abs(O3 - 2) < 0.1, abs(O4 - 2) < 0.1,

    % (2) 知识表查询：全部相容
    forall(scheme(S, _, _, _, _), consistent(S)),
    scheme(ftcs_heat, diffusion, _, 1, 2),
    format("knowledge base: all 5 schemes consistent; ftcs_heat order (1,2)~n"),

    % (3) 迎风方向与网格比
    upwind_dir(1.0, backward), upwind_dir(-2.0, forward),
    mesh_ratio(L, 1.0, 0.008, 0.01), abs(L - 0.8) < 1.0e-12,
    thomas_work(100, W), W =:= 297,
    format("upwind: a>0 backward diff, a<0 forward; lambda = a*tau/h; Thomas work 3J-3~n"),

    format("END ====~n").
