:- encoding(utf8).
% 第 04 章 实数：Baire 空间的树表示（Jech (4.10)-(4.15)）
%
% 树 T ⊆ Seq（有限序列集）对初始段封闭；
% [T] = 穿过 T 的无穷路径全体（闭集）；
% 导树 T'（分叉节点）剥掉"单干道"。
% 本文件实现：树的封闭性检查、[T] 的路径搜索、导树算子。

% ---------- 一、表示：序列为列表，树为谓词 ----------

% 初始段关系：subseq(S, T) 当 S 是 T 的初始段
subseq([], _).
subseq([X|Xs], [X|Ys]) :- subseq(Xs, Ys).

% 树 = 对初始段封闭的序列集（用 in_tree/1 的封闭性规则刻画）
% 具体树用事实给出 + tree_closed 规则检查

% ---------- 二、全树与有限树 ----------

% 全树：所有序列都在（用通配事实模拟）
in_full_tree(_).

% 有限树：长度 ≤ 2 的序列
in_bounded_tree(S) :- length(S, N), N =< 2.

% 字母表与有限序列（防无界枚举）
seq_elem(0).
seq_elem(1).
finite_seq(N, S) :- between(0, N, N2), length(S, N2), maplist(seq_elem, S).

% 树的封闭性验证：长度 ≤ 4 的 0/1 序列里，T 成员的初始段都在 T
tree_closed(full) :-
    forall((between(0, 4, N), finite_seq(N, S), in_full_tree(S)),
           forall(subseq(P, S), in_full_tree(P))).
tree_closed(bounded) :-
    forall((between(0, 4, N), finite_seq(N, S), in_bounded_tree(S)),
           forall(subseq(P, S), in_bounded_tree(P))).

% ---------- 三、[T]：无穷路径（深度 k 的前缀全在 T） ----------

% path_in(T, Depth)：存在长度 Depth 的序列，其全部初始段在 T
path_prefix_ok(T, S) :- forall(subseq(P, S), in_tree(T, P)).

in_tree(full, S) :- in_full_tree(S).
in_tree(bounded, S) :- in_bounded_tree(S).

% 注意：finite_seq(N,S) 生成"长度 ≤ N"；路径搜索要"恰 Depth 长"：
exact_seq(N, S) :- length(S, N), maplist(seq_elem, S).

has_path(T, Depth) :-
    between(0, 6, Depth),
    findall(S, (exact_seq(Depth, S), path_prefix_ok(T, S)), Ss),
    Ss \= [].

% ---------- 四、导树 T'（Jech (4.13)）----------
% t ∈ T' ⟺ T 中有不相容的两条延伸

incompatible(S, T) :- \+ subseq(S, T), \+ subseq(T, S).

in_der_tree(T, S) :-
    between(0, 4, N1), exact_seq(N1, E1), in_tree(T, E1),
    between(0, 4, N2), exact_seq(N2, E2), in_tree(T, E2),
    subseq(S, E1), subseq(S, E2),
    E1 \= E2, incompatible(E1, E2).

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 04 实数：树表示与 Cantor-Bendixson~n"),
    (   tree_closed(full) -> format("  全树封闭 ✓~n") ; format("  全树封闭 FAIL~n") ),
    (   tree_closed(bounded) -> format("  有限树（长≤2）封闭 ✓~n") ; format("  有限树封闭 FAIL~n") ),
    format("路径搜索：~n"),
    (   has_path(full, 5) -> format("  全树有任意深路径：[T] = 整个 Baire 空间 ✓~n")
    ;   format("  全树无路径（错误！）~n") ),
    (   has_path(bounded, 3) -> format("  有限树有深度 3 路径（错误！）~n")
    ;   format("  有限树无深度 3 路径：[T] = ∅ ✓（有极大节点）~n") ),
    format("导树（分叉节点）：~n"),
    (   in_der_tree(full, []) -> format("  全树根节点已分叉（0/1 两枝）✓~n")
    ;   format("  （错误）~n") ),
    format("要点：闭集 ↔ 无极大节点的树；CB 导树迭代剥掉孤立点。~n"),
    format("END ====~n").
