:- encoding(utf8).
% 第 11 章 传递模型：坍缩函数的递归计算
%
% 外延良基图（ext 谓词）→ 传递集合编码（嵌套项表示）。
% π(x) = π"ext(x)：良基递归的直接 Prolog 化。

% ---------- 一、图：ext(X, Zs)（X 的成员表 Zs） ----------

% 例：von Neumann 链 0∈1∈2∈3
ext_vn(0, []).
ext_vn(1, [0]).
ext_vn(2, [0, 1]).
ext_vn(3, [0, 1, 2]).

% ---------- 二、坍缩：π(x) = {π(z) : z ∈ ext(x)} ----------

% 集合编码：s(List)（List 是成员的坍缩列表）
collapse_vn(X, s(ZsC)) :-
    ext_vn(X, Zs),
    maplist(collapse_vn, Zs, ZsC).

% ---------- 三、外延性检查（同名坍缩 ⟹ 同点） ----------

same_collapse(X, Y) :-
    collapse_vn(X, C), collapse_vn(Y, C).

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 11 传递模型：Mostowski 坍缩~n"),
    forall((member(X, [0, 1, 2, 3]), collapse_vn(X, C)),
           format("  π(~w) = ~w~n", [X, C])),
    format("  ——链 0∈1∈2∈3 坍缩成 von Neumann 数。~n"),
    (   same_collapse(2, 3) ->
        format("  2 与 3 同坍缩（错误！外延破坏）~n")
    ;   format("  π 单射：2 与 3 坍缩不同 ✓（外延性）~n") ),
    (   same_collapse(1, 1) ->
        format("  自身坍缩稳定 ✓~n")
    ;   true ),
    format("  反射原理（定理 29）的官方机器化：Isabelle Reflection.thy。~n"),
    format("END ====~n").
