:- encoding(utf8).
% 28_fem1d.pl —— 第 28 章：有限元装配索引引擎（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) 局部-整体映射：单元 e 的两个局部基（L/R）对应全局节点；
%   (2) 单元刚度/质量闭式表；
%   (3) 装配引擎：对给定 N 输出内点行。

% ---------- (1) 局部-整体映射（0 基全局节点，同 Fortran 通道坑账） ----------
local_global(E, L, G) :- G is E - 2 + L.      % L=1 左节点，L=2 右节点
local_global_name(E, 1, left_node, G) :- G is E - 2.
local_global_name(E, 2, right_node, G) :- G is E - 1.

% ---------- (2) 单元闭式 ----------
elem_stiff(p1q1, H, [[K, Off],[Off, K]]) :- K is 1/H + H/3, Off is -1/H + H/6.
elem_mass(H, [[M, C],[C, M]]) :- M is 2*H/6, C is H/6.
elem_load(H, FL, FR, [F1, F2]) :- F1 is H/6*(2*FL + FR), F2 is H/6*(FL + 2*FR).

% ---------- (3) 装配引擎 ----------
% 内点 i（1 <= i <= N-1）的对角 = 两个相邻单元的 RR + LL
assembled_diag(H, D) :- D is 2/H + 2*H/3.
assembled_offdiag(H, O) :- O is -1/H + H/6.

% 端点（Robin 侧）对角 = 单单元 LL + alpha
assembled_robin_diag(H, Alpha, D) :- D is 1/H + H/3 + Alpha.

% ---------- main ----------
main :-
    format("==== 28 fem1d~n"),

    % (1) 映射检查
    local_global(1, 1, 0), local_global(1, 2, 1),
    local_global(5, 1, 4), local_global(5, 2, 5),
    format("local-global map: element e connects nodes (e-1, e)~n"),

    % (2) 闭式表
    elem_stiff(p1q1, 0.1, [[K, Off]|_]),
    format("element stiffness h=0.1: diag = ~w, off = ~w~n", [K, Off]),
    abs(K - 10.033333333333333) < 1e-12,
    abs(Off - (-9.983333333333333)) < 1e-12,
    elem_mass(0.1, [[M, C]|_]),
    abs(M - 0.03333333333333333) < 1e-12, abs(C - 0.016666666666666666) < 1e-12,
    format("element mass h=0.1: diag = ~w, off = ~w~n", [M, C]),

    % (3) 装配
    assembled_diag(0.05, D), abs(D - (2/0.05 + 2*0.05/3)) < 1e-12,
    assembled_offdiag(0.05, O), abs(O - (-1/0.05 + 0.05/6)) < 1e-12,
    assembled_robin_diag(0.05, 2.0, DR), abs(DR - (1/0.05 + 0.05/3 + 2.0)) < 1e-12,
    format("assembled rows: interior diag = 2/h+2h/3, off = -1/h+h/6;~n"),
    format("  Robin endpoint diag = 1/h+h/3+alpha~n"),

    format("END ====~n").
