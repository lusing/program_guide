:- encoding(utf8).
% 11_boundary.pl —— 第 11 章：边界条件计数与数值边界规则（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) 边界条件计数：标量 a>0 ⟹ 左 1 右 0；方程组按 A 的正/负特征值
%       个数分别给右/左边界；
%   (2) 数值边界方法知识表：外推 (5.20) 反例、(5.21) 也不行、
%       迎风 (5.22) 可行、特征插值 (5.28) 可行且低一阶不影响整体。

% ---------- (1) 计数规则 ----------
scalar_bc_count(A, left, N)  :- ( A > 0 -> N = 1 ; N = 0 ).
scalar_bc_count(A, right, N) :- ( A > 0 -> N = 0 ; N = 1 ).

% 方程组：x=0 处条件数 = 负特征值个数；x=1 处 = 正特征值个数
system_bc_count(Eigs, left, N)  :- count_neg(Eigs, 0, N).
system_bc_count(Eigs, right, N) :- count_pos(Eigs, 0, N).
count_neg([], N, N).
count_neg([E|Es], Acc, N) :- ( E < 0 -> A2 is Acc + 1 ; A2 is Acc ), count_neg(Es, A2, N).
count_pos([], N, N).
count_pos([E|Es], Acc, N) :- ( E > 0 -> A2 is Acc + 1 ; A2 is Acc ), count_pos(Es, A2, N).

% ---------- (2) 数值边界方法表 ----------
bc_method(extrap_linear,   'u_J = 2u_{J-1} - u_{J-2}',  fails).
bc_method(extrap_second,   '(5.21) second extrapolation', fails).
bc_method(upwind_bc,       'u_J^{n+1} = u_J - lam(u_J - u_{J-1})', works).
bc_method(char_interp,     'characteristic interpolation (5.28)', works).
bc_method(fv_trapezoid,    'finite-volume + trapezoid', works).

% 边界精度可比内点低一阶（定理事实）
boundary_order_allowance(inner, 2, 1).

% ---------- main ----------
main :-
    format("==== 11 boundary~n"),

    % (1) 计数
    scalar_bc_count(1.0, left, 1), scalar_bc_count(1.0, right, 0),
    scalar_bc_count(-2.0, left, 0), scalar_bc_count(-2.0, right, 1),
    format("scalar a>0: left=1 right=0; a<0: left=0 right=1~n"),
    system_bc_count([-1.0, 2.0, -3.0], left, 2),
    system_bc_count([-1.0, 2.0, -3.0], right, 1),
    format("system eigs [-1,2,-3]: left=2 (negative count), right=1 (positive count)~n"),
    system_bc_count([-1.0, 1.0], left, 1),
    system_bc_count([-1.0, 1.0], right, 1),
    format("system eigs [-1,1]: one condition on each side~n"),

    % (2) 方法表
    bc_method(extrap_linear, _, fails),
    bc_method(upwind_bc, _, works),
    bc_method(char_interp, _, works),
    boundary_order_allowance(inner, 2, 1),
    format("numerical BC verdicts: extrap fails, upwind/char-interp work;~n"),
    format("boundary may be one order lower than interior without harm~n"),

    format("END ====~n").
