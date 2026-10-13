:- encoding(utf8).
% 第 06 章 基数算术：König 定理的可执行对角逃逸
%
% 定理 17：κᵢ < λᵢ ⟹ Σκᵢ < Πλᵢ。证明的灵魂：任何 Zi（|Zi|≤κᵢ）
% 都盖不满积 Πλᵢ——第 i 坐标逃出 Zi 的投影。
% 有限版：给定 aᵢ < bᵢ，任何"每坐标至多 aᵢ 个候选"的覆盖
% 都漏掉一个点——对角逃逸在有限域的完整可执行版。

% ---------- 一、积空间：坐标取值域 ----------

% 三个坐标，取值域 0..b_i-1
dom1(X) :- between(0, 1, X).        % b_1 = 2
dom2(X) :- between(0, 2, X).        % b_2 = 3
dom3(X) :- between(0, 3, X).        % b_3 = 4

% aᵢ：每坐标允许的"已覆盖候选数"上限（a_1=1, a_2=2, a_3=3）
cover1(X) :- member(X, [0]).        % 第 1 坐标的"投影"只盖 1 个值
cover2(X) :- member(X, [0, 1]).     % 第 2 坐标盖 2 个值
cover3(X) :- member(X, [0, 1, 2]).  % 第 3 坐标盖 3 个值

% ---------- 二、对角逃逸：构造不在覆盖里的点 ----------

escape(X1, X2, X3) :-
    dom1(X1), dom2(X2), dom3(X3),
    \+ cover1(X1).
escape(X1, X2, X3) :-
    dom1(X1), dom2(X2), dom3(X3),
    cover1(X1), \+ cover2(X2).
escape(X1, X2, X3) :-
    dom1(X1), dom2(X2), dom3(X3),
    cover1(X1), cover2(X2), \+ cover3(X3).

% 逃逸点：逃出**第一个**没盖满的坐标
escape_point(P) :- escape(X1, X2, X3), P = (X1, X2, X3).

% ---------- 三、和与积的数值验证 ----------

sum_a(S) :- S is 1 + 2 + 3.
prod_b(P) :- P is 2 * 3 * 4.

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 06 König：可执行对角逃逸~n"),
    sum_a(S), prod_b(P),
    format("  a=[1,2,3], b=[2,3,4]：Σa=~w < Πb=~w~n", [S, P]),
    S < P,
    findall(Pt, escape_point(Pt), Es),
    length(Es, NE),
    format("  逃逸点数（离开『每坐标部分覆盖』的点）：~w~n", [NE]),
    format("  示例逃逸点：~w~n", [Es]),
    format("  结构：Πb - Πa'' 的差集里每个点都是某个 Zi 覆盖不了的。~n"),
    format("  König 的无穷版：逃逸点在任意 Zi-覆盖下存在（定理 17）。~n"),
    format("END ====~n").
